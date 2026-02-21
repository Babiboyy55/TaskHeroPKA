import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../services/firestore_service.dart';
import '../models/task_model.dart';
import '../theme/app_colors.dart';
import '../utils/currency_format.dart';

class PostTaskScreen extends StatefulWidget {
  const PostTaskScreen({super.key});

  @override
  State<PostTaskScreen> createState() => _PostTaskScreenState();
}

class _PostTaskScreenState extends State<PostTaskScreen> {
  bool isVoiceMode = true;
  bool isRecording = false;
  bool isTranscribing = false;
  bool isProcessing = false;
  bool isPosting = false;
  bool showPreview = false;
  String? aiError;
  int recordingSeconds = 0;
  Timer? _timer;

  final _descController = TextEditingController();
  final _audioRecorder = WebAudioRecorder();

  String? selectedCategory;
  String? pickupBuilding;
  String? deliveryBuilding;
  double compensation = 15000;

  Map<String, dynamic> aiPreview = {};

  final categories = {
    'food': 'Đồ ăn & Vật phẩm',
    'academic': 'Hỗ trợ học tập',
    'errands': 'Việc vặt trong khuôn viên',
    'tech': 'Công nghệ & Chế tạo',
    'social': 'Sự kiện & Giao lưu',
    'marketplace': 'Chợ',
  };

  final buildings = [
    'PKA Block A', 'PKA Block B', 'PKA Block C',
    'Ký túc xá', 'Thư viện', 'Căng tin',
  ];

  bool get _isMobile => MediaQuery.of(context).size.width < 768;

  Future<void> _startRecording() async {
    final ok = await _audioRecorder.startRecording();
    if (!ok) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Micro bị chặn'),
          description: Text('Cho phép truy cập micro trong trình duyệt và thử lại.'),
        ),
      );
      return;
    }
    setState(() {
      isRecording = true;
      recordingSeconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => recordingSeconds++);
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    setState(() {
      isRecording = false;
      isTranscribing = true;
    });

    print('[PostTask] Stopping recording...');
    final audioBytes = await _audioRecorder.stopRecording();
    print('[PostTask] Audio bytes received: ${audioBytes?.length ?? 0}');

    if (!mounted) return;

    if (audioBytes == null || audioBytes.isEmpty) {
      print('[PostTask] ERROR: No audio data captured');
      setState(() => isTranscribing = false);
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Ghi âm thất bại'),
          description: Text('Không có âm thanh. Vui lòng thử lại.'),
        ),
      );
      return;
    }

    print('[PostTask] Sending ${audioBytes.length} bytes to Deepgram...');
    // Send to Deepgram for transcription
    final transcript = await DeepgramService.transcribe(audioBytes);
    print('[PostTask] Transcript result: ${transcript ?? "null"}');

    if (!mounted) return;
    setState(() => isTranscribing = false);

    if (transcript != null && transcript.isNotEmpty) {
      print('[PostTask] Transcription successful: $transcript');
      _descController.text = transcript;
      // Auto-send to OpenAI for AI formatting
      _processWithAI(transcript);
    } else {
      print('[PostTask] ERROR: Transcription returned null or empty');
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Chuyển đổi thất bại'),
          description: Text('Không thể chuyển đổi âm thanh. Thử nói rõ hơn hoặc kiểm tra kết nối.'),
        ),
      );
    }
  }

  Future<void> _processWithAI(String input) async {
    if (input.trim().isEmpty) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Thiếu thông tin'),
          description: Text('Vui lòng mô tả những gì bạn cần giúp.'),
        ),
      );
      return;
    }

    setState(() {
      isProcessing = true;
      aiError = null;
    });

    final result = await AIService.formatTask(input);

    if (!mounted) return;

    if (result != null) {
      setState(() {
        aiPreview = result;
        isProcessing = false;
        showPreview = true;
      });
    } else {
      setState(() {
        isProcessing = false;
        aiError = 'Không thể kết nối OpenAI. Kiểm tra API key hoặc mạng.';
      });
    }
  }

  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _postTask() async {
    // Guard against double-tap / multiple submissions
    if (isPosting) return;
    setState(() => isPosting = true);

    try {
      // Parse category from AI preview
      final categoryStr = aiPreview['category']?.toString() ?? 'errands';
      TaskCategory category;
      try {
        category = TaskCategory.values.firstWhere(
          (c) => c.label.toLowerCase() == categoryStr.toLowerCase() ||
                 c.name.toLowerCase() == categoryStr.toLowerCase(),
          orElse: () => TaskCategory.errands,
        );
      } catch (_) {
        category = TaskCategory.errands;
      }

      // Parse urgency
      final urgencyStr = aiPreview['urgency']?.toString() ?? 'normal';
      final urgency = urgencyStr.toLowerCase() == 'urgent' 
          ? TaskUrgency.urgent 
          : TaskUrgency.normal;

      // Parse compensation
      final comp = aiPreview['suggested_compensation'] is num
          ? (aiPreview['suggested_compensation'] as num).toDouble()
          : double.tryParse(aiPreview['suggested_compensation']?.toString() ?? '5') ?? 5.0;

      // Parse estimated minutes
      final estMinutes = aiPreview['estimated_minutes'] is num
          ? (aiPreview['estimated_minutes'] as num).toInt()
          : int.tryParse(aiPreview['estimated_minutes']?.toString() ?? '15') ?? 15;

      // Parse locations
      final pickupData = aiPreview['pickup'];
      final deliveryData = aiPreview['delivery'];
      
      final pickup = TaskLocation(
        building: pickupData?['building']?.toString() ?? 'TBD',
        level: pickupData?['level']?.toString() ?? '',
        landmark: pickupData?['landmark']?.toString() ?? '',
      );
      
      final delivery = TaskLocation(
        building: deliveryData?['building']?.toString() ?? 'TBD',
        level: deliveryData?['level']?.toString() ?? '',
        landmark: deliveryData?['landmark']?.toString() ?? '',
      );

      // Create the task object
      final task = HeroTask(
        title: aiPreview['title']?.toString() ?? 'New Task',
        description: aiPreview['description']?.toString() ?? _descController.text,
        category: category,
        compensation: comp,
        status: TaskStatus.open,
        urgency: urgency,
        estimatedMinutes: estMinutes,
        pickup: pickup,
        delivery: delivery,
        posterName: '', // Will be set by Firestore service
        posterRating: 5.0,
        posterAvatarUrl: '',
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      print('[PostTask] Creating task in Firestore...');
      await _firestoreService.createTask(task);
      print('[PostTask] Task created successfully!');

      if (!mounted) return;
      
      ShadToaster.of(context).show(
        const ShadToast(
          title: Text('Nhiệm vụ đã đăng!'),
          description: Text('Nhiệm vụ của bạn đã sẵn sàng. Các Heroes sẽ được thông báo.'),
        ),
      );
      
      setState(() {
        showPreview = false;
        isRecording = false;
        isProcessing = false;
        isPosting = false;
        recordingSeconds = 0;
        aiPreview = {};
        aiError = null;
        _descController.clear();
      });
    } catch (e) {
      print('[PostTask] Error creating task: $e');
      if (!mounted) return;
      setState(() => isPosting = false);
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('Không thể đăng nhiệm vụ'),
          description: Text('Lỗi: $e'),
        ),
      );
    }
  }

  String _locationString(dynamic loc) {
    if (loc is String) return loc;
    if (loc is Map) {
      final parts = <String>[
        if (loc['building'] != null) loc['building'].toString(),
        if (loc['level'] != null) loc['level'].toString(),
        if (loc['landmark'] != null && loc['landmark'].toString().isNotEmpty)
          loc['landmark'].toString(),
      ];
      return parts.join(', ');
    }
    return 'Chưa xác định';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _descController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(_isMobile ? 16 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const SizedBox(height: 8),
          _buildIntegrationChips(theme),
          const SizedBox(height: 24),
          _buildModeToggle(theme),
          const SizedBox(height: 24),
          if (isVoiceMode)
            _buildVoiceSection(theme)
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.03, end: 0, duration: 300.ms),
          if (!isVoiceMode)
            _buildManualForm(theme)
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.03, end: 0, duration: 300.ms),
          if (aiError != null) ...[
            const SizedBox(height: 16),
            _buildError(theme),
          ],
          if (showPreview) ...[
            const SizedBox(height: 24),
            _buildAIPreview(theme)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.05, end: 0, duration: 400.ms),
          ],
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildHeader(ShadThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Đăng nhiệm vụ',
          style: TextStyle(
            fontSize: _isMobile ? 22 : 24,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.foreground,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Mô tả những gì bạn cần — AI sẽ định dạng giúp bạn.',
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.mutedForeground,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildIntegrationChips(ShadThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _integrationChip('AI Định dạng', const Color(0xFF16A34A)),
          const SizedBox(width: 8),
          _integrationChip('Ghi âm giọng nói', const Color(0xFF16A34A)),
          const SizedBox(width: 8),
          _integrationChip('Firebase', const Color(0xFF16A34A)),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }

  Widget _integrationChip(String label, Color dotColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.orangeLight,
        border: Border.all(color: AppColors.orangeMid),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.orange600)),
        ],
      ),
    );
  }

  Widget _buildModeToggle(ShadThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.colorScheme.border)),
      ),
      child: Row(
        children: [
          _modeTab(theme, true, LucideIcons.mic, 'Giọng nói (Nhanh nhất)'),
          _modeTab(theme, false, LucideIcons.penLine, 'Thủ công'),
        ],
      ),
    );
  }

  Widget _modeTab(
      ShadThemeData theme, bool isVoice, IconData icon, String label) {
    final active = isVoiceMode == isVoice;
    return GestureDetector(
      onTap: () => setState(() => isVoiceMode = isVoice),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? AppColors.orange500 : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 14,
                color: active
                    ? AppColors.orange600
                    : theme.colorScheme.mutedForeground),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active
                    ? AppColors.orange600
                    : theme.colorScheme.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceSection(ShadThemeData theme) {
    // Transcribing state — sending audio to Deepgram
    if (isTranscribing) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: theme.colorScheme.card,
          border: Border.all(color: theme.colorScheme.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFF6366F1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.audioLines,
                  size: 28, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Chuyển đổi giọng nói của bạn...',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.foreground,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: const Color(0xFFE0E7FF),
                color: const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Đang xử lý giọng nói của bạn...',
              style: TextStyle(
                  fontSize: 13, color: theme.colorScheme.mutedForeground),
            ),
          ],
        ),
      );
    }

    // Processing state — formatting with OpenAI
    if (isProcessing) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: theme.colorScheme.card,
          border: Border.all(color: theme.colorScheme.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.orangeGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.sparkles,
                  size: 28, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'AI đang định dạng nhiệm vụ...',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.foreground,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: AppColors.orangeLight,
                color: AppColors.orange500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Đang phân tích mô tả, đề xuất thù lao...',
              style: TextStyle(
                  fontSize: 13, color: theme.colorScheme.mutedForeground),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(_isMobile ? 20 : 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        border: Border.all(color: theme.colorScheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          if (!isRecording) ...[
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.orangeLight,
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.mic,
                  size: 32, color: AppColors.orange500),
            ),
            const SizedBox(height: 16),
            Text(
              'Mô tả nhiệm vụ của bạn',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.foreground,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Nhấn Ghi âm và nói, hoặc gõ yêu cầu bên dưới.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: theme.colorScheme.mutedForeground),
            ),
          ] else ...[
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFEE2E2),
              ),
              child: const Icon(LucideIcons.mic,
                  size: 32, color: Color(0xFFDC2626)),
            ),
            const SizedBox(height: 12),
            Text(
              'Đang ghi... ${recordingSeconds.toString().padLeft(2, '0')}s',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFDC2626)),
            ),
          ],
          const SizedBox(height: 20),
          ShadInput(
            controller: _descController,
            placeholder: const Text(
              'VD: Mua 1 phần cơm sườn từ căng tin mang lên phòng 302...',
            ),
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              if (!isRecording)
                ShadButton.outline(
                  leading: const Icon(LucideIcons.mic, size: 16),
                  child: const Text('Ghi âm'),
                  onPressed: _startRecording,
                ),
              if (isRecording)
                ShadButton.destructive(
                  leading: const Icon(LucideIcons.square, size: 14),
                  child: const Text('Dừng'),
                  onPressed: _stopRecording,
                ),
              ShadButton(
                leading: const Icon(LucideIcons.sparkles, size: 16),
                child: const Text('Định dạng với AI'),
                onPressed: () => _processWithAI(_descController.text),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.orangeLight,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.orangeMid),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.lightbulb,
                    size: 14, color: AppColors.orange600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mẹo: Nói những gì bạn cần, nơi lấy và nơi giao để có kết quả AI tốt nhất.',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.orange600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualForm(ShadThemeData theme) {
    return Container(
      padding: EdgeInsets.all(_isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        border: Border.all(color: theme.colorScheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chi tiết nhiệm vụ',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.foreground)),
          const SizedBox(height: 4),
          Text('Điền chi tiết thủ công.',
              style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.mutedForeground)),
          const SizedBox(height: 16),
          Text('Mô tả',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.foreground)),
          const SizedBox(height: 6),
          ShadInput(
            controller: _descController,
            placeholder: const Text('Bạn cần giúp gì?'),
            minLines: 3,
            maxLines: 5,
          ),
          const SizedBox(height: 16),
          Text('Danh mục',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.foreground)),
          const SizedBox(height: 6),
          ShadSelect<String>(
            placeholder: const Text('Chọn danh mục'),
            options: categories.entries
                .map((e) =>
                    ShadOption(value: e.key, child: Text(e.value)))
                .toList(),
            selectedOptionBuilder: (context, value) =>
                Text(categories[value] ?? value),
            onChanged: (v) => setState(() => selectedCategory = v),
          ),
          const SizedBox(height: 16),
          if (_isMobile) ...[
            _buildLocationSelect(theme, 'Điểm lấy'),
            const SizedBox(height: 12),
            _buildLocationSelect(theme, 'Điểm giao'),
          ] else
            Row(
              children: [
                Expanded(child: _buildLocationSelect(theme, 'Điểm lấy')),
                const SizedBox(width: 12),
                Expanded(child: _buildLocationSelect(theme, 'Điểm giao')),
              ],
            ),
          const SizedBox(height: 20),
          // Payment section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.orangeLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Thanh toán',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.foreground)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Giá của bạn:',
                        style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.foreground)),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: ShadInput(
                        placeholder: const Text('15.000'),
                        leading: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Text('₫')),
                        onChanged: (v) {
                          final parsed = double.tryParse(v.replaceAll('.', ''));
                          if (parsed != null) {
                            setState(() => compensation = parsed);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Phí dịch vụ (5%):',
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.mutedForeground)),
                    Text('-${formatVND(compensation * 0.05)}',
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.mutedForeground)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Người nhận được:',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.orange600)),
                    Text(
                        formatVND(compensation * 0.95),
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.orange600)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ShadButton(
                leading: const Icon(LucideIcons.sparkles, size: 16),
                child: const Text('AI Định dạng & Đăng'),
                onPressed: () {
                  // Enrich text input with manual form values so OpenAI has full context
                  String enrichedInput = _descController.text;
                  if (selectedCategory != null) {
                    final catLabel = categories[selectedCategory] ?? selectedCategory;
                    enrichedInput += '\nCategory: $catLabel';
                  }
                  if (pickupBuilding != null) {
                    enrichedInput += '\nPickup: $pickupBuilding';
                  }
                  if (deliveryBuilding != null) {
                    enrichedInput += '\nDelivery: $deliveryBuilding';
                  }
                  if (compensation != 5.00) {
                    enrichedInput += '\nNgân sách: ${formatVND(compensation)}';
                  }
                  _processWithAI(enrichedInput);
                },
              ),
              ShadButton.outline(
                child: const Text('Hủy'),
                onPressed: () {
                  setState(() {
                    _descController.clear();
                    selectedCategory = null;
                    pickupBuilding = null;
                    deliveryBuilding = null;
                    compensation = 5.00;
                    aiError = null;
                    showPreview = false;
                    aiPreview = {};
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSelect(ShadThemeData theme, String label) {
    final isPickup = label == 'Điểm lấy';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.foreground)),
        const SizedBox(height: 6),
        ShadSelect<String>(
          placeholder: const Text('Chọn tòa nhà'),
          options: buildings
              .map((b) => ShadOption(value: b, child: Text(b)))
              .toList(),
          selectedOptionBuilder: (context, value) => Text(value),
          onChanged: (v) {
            setState(() {
              if (isPickup) {
                pickupBuilding = v;
              } else {
                deliveryBuilding = v;
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildError(ShadThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.circleAlert,
              size: 16, color: Color(0xFFDC2626)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              aiError!,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFFDC2626)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIPreview(ShadThemeData theme) {
    final title = aiPreview['title']?.toString() ?? 'Nhiệm vụ chưa đặt tên';
    final description = aiPreview['description']?.toString() ?? '';
    final category = aiPreview['category']?.toString() ?? 'Chung';
    final pickup = _locationString(aiPreview['pickup']);
    final delivery = _locationString(aiPreview['delivery']);
    final estMinutes = aiPreview['estimated_minutes']?.toString() ?? '?';
    final comp = (aiPreview['suggested_compensation'] is num)
        ? (aiPreview['suggested_compensation'] as num).toStringAsFixed(0)
        : aiPreview['suggested_compensation']?.toString() ?? '15000';
    final compNum = double.tryParse(comp) ?? 15000.0;
    final heroGets = formatVND(compNum * 0.95);
    final compDisplay = formatVND(compNum);

    return Container(
      padding: EdgeInsets.all(_isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        border: Border.all(color: AppColors.orange400.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: AppColors.orangeGradient,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(LucideIcons.sparkles,
                    size: 14, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text('Xem trước nhiệm vụ AI',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.foreground)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Kiểm tra lại trước khi đăng.',
              style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.mutedForeground)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.foreground)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.orangeLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(category,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.orange600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(description,
              style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.mutedForeground)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.accent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                _previewRow(theme, LucideIcons.mapPin, 'Lấy tại', pickup),
                const SizedBox(height: 6),
                _previewRow(theme, LucideIcons.navigation, 'Giao đến', delivery),
                const SizedBox(height: 6),
                _previewRow(theme, LucideIcons.clock, 'Thời gian', '$estMinutes phút'),
                const SizedBox(height: 6),
                _previewRow(theme, LucideIcons.dollarSign, 'Thù lao',
                    '$compDisplay (Nhận được $heroGets)'),
                if (aiPreview['urgency'] != null) ...[
                  const SizedBox(height: 6),
                  _previewRow(theme, LucideIcons.zap, 'Urgency',
                      aiPreview['urgency'].toString()),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ShadButton.outline(
                leading: const Icon(LucideIcons.pencil, size: 14),
                child: const Text('Chỉnh sửa'),
                onPressed: () =>
                    setState(() => showPreview = false),
              ),
              ShadButton.outline(
                child: const Text('Hủy'),
                onPressed: () => setState(() {
                  showPreview = false;
                  aiPreview = {};
                }),
              ),
              ShadButton(
                leading: Icon(
                  isPosting ? LucideIcons.loaderCircle : LucideIcons.check,
                  size: 16,
                ),
                child: Text(isPosting ? 'Đang đăng...' : 'Đăng nhiệm vụ'),
                onPressed: isPosting ? null : _postTask,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _previewRow(
      ShadThemeData theme, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.mutedForeground),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text('$label:',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.mutedForeground)),
        ),
        Flexible(
            child: Text(value,
                style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.foreground))),
      ],
    );
  }
}
