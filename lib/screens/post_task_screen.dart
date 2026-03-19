import 'dart:async';
import 'dart:math';
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

  // ───────────────── CHẾ ĐỘ DEMO ─────────────────
  // Đặt thành false để dùng mic thật + API thật
  static const bool _demoMode = false;

  static const List<Map<String, dynamic>> _mockSamples = [
    // 1. Học thuật
    {
      'title': 'Cần người giải thích bài Giải tích chương 3',
      'description': 'Mình không hiểu phần đạo hàm hàm hợp và quy tắc dây chuyền. Cần ai ngồi chỉ bài khoảng 45 phút tại thư viện.',
      'category': 'academic',
      'urgency': 'urgent',
      'suggested_compensation': 50000,
      'estimated_minutes': 45,
      'pickup': {'building': 'Thư viện', 'level': 'Tầng 2', 'landmark': 'Phòng học nhóm'},
      'delivery': {'building': 'Thư viện', 'level': 'Tầng 2', 'landmark': 'Phòng học nhóm'},
    },
    // 2. Đồ ăn
    {
      'title': 'Mua trà sữa Gong Cha mang về ký túc xá',
      'description': 'Order 1 ly trà sữa matcha đường 50% ít đá tại Gong Cha gần cổng, mang về phòng 215 ký túc xá.',
      'category': 'food',
      'urgency': 'normal',
      'suggested_compensation': 20000,
      'estimated_minutes': 20,
      'pickup': {'building': 'Cổng trường', 'level': 'Tầng 1', 'landmark': 'Gong Cha'},
      'delivery': {'building': 'Ký túc xá', 'level': 'Tầng 2', 'landmark': 'Phòng 215'},
    },
    // 3. Công nghệ
    {
      'title': 'Cần giúp cài đặt môi trường VSCode + Flutter',
      'description': 'Máy tính mới cài Windows, chưa biết cách cài Flutter SDK và cấu hình VSCode. Cần ai ngồi hỗ trợ khoảng 1 tiếng.',
      'category': 'tech',
      'urgency': 'normal',
      'suggested_compensation': 60000,
      'estimated_minutes': 60,
      'pickup': {'building': 'PKA Block A', 'level': 'Tầng 4', 'landmark': 'Phòng máy tính'},
      'delivery': {'building': 'PKA Block A', 'level': 'Tầng 4', 'landmark': 'Phòng máy tính'},
    },
    // 4. Việc vặt
    {
      'title': 'In và đóng tập tài liệu 50 trang',
      'description': 'Cần in 50 trang tài liệu A4 (file PDF) tại tiệm in gần trường, đóng bìa, mang về phòng học.',
      'category': 'errands',
      'urgency': 'normal',
      'suggested_compensation': 25000,
      'estimated_minutes': 30,
      'pickup': {'building': 'Cổng trường', 'level': 'Tầng 1', 'landmark': 'Tiệm photocopy'},
      'delivery': {'building': 'PKA Block C', 'level': 'Tầng 1', 'landmark': 'Phòng 102'},
    },
    // 5. Chợ / Marketplace
    {
      'title': 'Bán máy tính bảng Samsung Galaxy Tab A8',
      'description': 'Cần bán gấp Samsung Galaxy Tab A8 64GB màu xám, còn bảo hành 3 tháng, kèm bao da. Giá 3.500.000đ thương lượng.',
      'category': 'marketplace',
      'urgency': 'urgent',
      'suggested_compensation': 15000,
      'estimated_minutes': 15,
      'pickup': {'building': 'PKA Block B', 'level': 'Tầng 3', 'landmark': 'Phòng 310'},
      'delivery': {'building': 'PKA Block B', 'level': 'Tầng 3', 'landmark': 'Phòng 310'},
    },
    // 6. Sự kiện / Xã hội
    {
      'title': 'Cần người chụp ảnh cho buổi thuyết trình nhóm',
      'description': 'Nhóm mình có buổi thuyết trình cuối kỳ lúc 2h chiều nay ở hội trường B. Cần 1 người chụp ảnh + quay clip ngắn làm kỷ niệm.',
      'category': 'social',
      'urgency': 'urgent',
      'suggested_compensation': 40000,
      'estimated_minutes': 60,
      'pickup': {'building': 'Hội trường B', 'level': 'Tầng 1', 'landmark': 'Cửa vào chính'},
      'delivery': {'building': 'Hội trường B', 'level': 'Tầng 1', 'landmark': 'Cửa vào chính'},
    },
  ];
  // ─────────────────────────────────────────────────

  Future<void> _startRecording() async {
    if (_demoMode) {
      // Demo: giả lập ghi âm 2 giây rồi nhảy thẳng ra kết quả AI mẫu
      setState(() {
        isRecording = true;
        recordingSeconds = 0;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => recordingSeconds++);
        if (recordingSeconds >= 2) {
          _timer?.cancel();
          _stopRecordingDemo();
        }
      });
      return;
    }

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

  // Dừng ghi âm demo — load kết quả AI mẫu trực tiếp
  void _stopRecordingDemo() {
    _timer?.cancel();
    setState(() {
      isRecording = false;
      isTranscribing = true;
    });

    // Giả lập độ trễ "đang xử lý AI"
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        isTranscribing = false;
        isProcessing = true;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() {
          final pick = _mockSamples[Random().nextInt(_mockSamples.length)];
          aiPreview = Map<String, dynamic>.from(pick);
          isProcessing = false;
          showPreview = true;
        });
      });
    });
  }


  Future<void> _stopRecording() async {
    _timer?.cancel();
    setState(() {
      isRecording = false;
      isTranscribing = true;
    });

    print('[PostTask] Dừng ghi âm...');
    final audioBytes = await _audioRecorder.stopRecording();
    print('[PostTask] Dữ liệu âm thanh nhận được: ${audioBytes?.length ?? 0} bytes');

    if (!mounted) return;

    if (audioBytes == null || audioBytes.isEmpty) {
      print('[PostTask] LỖI: Không có dữ liệu âm thanh');
      setState(() => isTranscribing = false);
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Ghi âm thất bại'),
          description: Text('Không có âm thanh. Vui lòng thử lại.'),
        ),
      );
      return;
    }

    print('[PostTask] Gửi ${audioBytes.length} bytes đến Deepgram...');
    // Gửi đến Deepgram để chuyển giọng nói thành văn bản
    final transcript = await DeepgramService.transcribe(audioBytes);
    print('[PostTask] Kết quả chuyển đổi: ${transcript ?? "null"}');

    if (!mounted) return;
    setState(() => isTranscribing = false);

    if (transcript != null && transcript.isNotEmpty) {
      print('[PostTask] Chuyển đổi thành công: $transcript');
      _descController.text = transcript;
      // Tự động gửi sang AI để định dạng
      _processWithAI(transcript);
    } else {
      print('[PostTask] LỖI: Chuyển đổi trả về null hoặc rỗng');
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Chuyển đổi thất bại'),
          description: Text('Không thể chuyển đổi âm thanh. Thử nói rõ hơn hoặc kiểm tra kết nối.'),
        ),
      );
    }
  }

  /// Trả về index mẫu phù hợp nhất dựa trên từ khóa trong [input].
  int _matchSampleIndex(String input) {
    final text = input.toLowerCase();

    // Từ khóa theo từng danh mục
    const keywords = [
      // 0 - academic
      ['học', 'bài', 'toán', 'lý', 'hóa', 'giải tích', 'môn', 'ôn', 'chỉ', 'dạy', 'giải', 'hiểu', 'giải thích'],
      // 1 - food
      ['ăn', 'mua', 'cơm', 'trà', 'sữa', 'nước', 'đồ ăn', 'food', 'mang', 'order', 'gong cha', 'bữa'],
      // 2 - tech
      ['cài', 'máy', 'code', 'lập trình', 'flutter', 'vscode', 'app', 'phần mềm', 'setup', 'fix lỗi', 'debug'],
      // 3 - errands
      ['in', 'photocopy', 'tài liệu', 'photo', 'giấy', 'giao', 'chạy', 'lấy', 'nhờ', 'việc'],
      // 4 - marketplace
      ['bán', 'mua lại', 'thanh lý', 'đồ cũ', 'giá', 'thương lượng', 'second hand'],
      // 5 - social
      ['chụp', 'quay', 'ảnh', 'video', 'sự kiện', 'thuyết trình', 'buổi', 'event'],
    ];

    int bestIdx = -1;
    int bestScore = 0;

    for (int i = 0; i < keywords.length; i++) {
      int score = keywords[i].where((kw) => text.contains(kw)).length;
      if (score > bestScore) {
        bestScore = score;
        bestIdx = i;
      }
    }

    return bestIdx >= 0 ? bestIdx : Random().nextInt(_mockSamples.length);
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

    if (_demoMode) {
      // Demo: nhận diện từ khóa → chọn mẫu phù hợp
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      final idx = _matchSampleIndex(input);
      setState(() {
        aiPreview = Map<String, dynamic>.from(_mockSamples[idx]);
        isProcessing = false;
        showPreview = true;
      });
      return;
    }

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
    // Chống nhấn đúp / gửi nhiều lần
    if (isPosting) return;
    setState(() => isPosting = true);

    try {
      // Phân tích danh mục từ kết quả AI
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

      // Phân tích mức độ khẩn cấp
      final urgencyStr = aiPreview['urgency']?.toString() ?? 'normal';
      final urgency = urgencyStr.toLowerCase() == 'urgent' 
          ? TaskUrgency.urgent 
          : TaskUrgency.normal;

      // Phân tích tiền thưởng
      final comp = aiPreview['suggested_compensation'] is num
          ? (aiPreview['suggested_compensation'] as num).toDouble()
          : double.tryParse(aiPreview['suggested_compensation']?.toString() ?? '5') ?? 5.0;

      // Phân tích thời gian ước tính
      final estMinutes = aiPreview['estimated_minutes'] is num
          ? (aiPreview['estimated_minutes'] as num).toInt()
          : int.tryParse(aiPreview['estimated_minutes']?.toString() ?? '15') ?? 15;

      // Phân tích địa điểm
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

      // Tạo đối tượng nhiệm vụ
      final task = HeroTask(
        title: aiPreview['title']?.toString() ?? 'Nhiệm vụ mới',
        description: aiPreview['description']?.toString() ?? _descController.text,
        category: category,
        compensation: comp,
        status: TaskStatus.open,
        urgency: urgency,
        estimatedMinutes: estMinutes,
        pickup: pickup,
        delivery: delivery,
        posterName: '', // Sẽ được cập nhật bởi Firestore
        posterRating: 5.0,
        posterAvatarUrl: '',
        createdAt: DateTime.now(),
      );

      // Lưu vào Firestore
      print('[PostTask] Đang tạo nhiệm vụ trên Firestore...');
      await _firestoreService.createTask(task);
      print('[PostTask] Tạo nhiệm vụ thành công!');

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
      print('[PostTask] Lỗi khi tạo nhiệm vụ: $e');
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

  Future<void> _postTaskManual() async {
    if (_descController.text.trim().isEmpty) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Thiếu thông tin'),
          description: Text('Vui lòng nhập mô tả nhiệm vụ.'),
        ),
      );
      return;
    }
    
    if (isPosting) return;
    setState(() => isPosting = true);

    try {
      final categoryStr = selectedCategory ?? 'errands';
      TaskCategory category;
      try {
        category = TaskCategory.values.firstWhere(
          (c) => c.name.toLowerCase() == categoryStr.toLowerCase() ||
                 c.label.toLowerCase() == categoryStr.toLowerCase(),
          orElse: () => TaskCategory.errands,
        );
      } catch (_) {
        category = TaskCategory.errands;
      }

      final pickup = TaskLocation(
        building: pickupBuilding ?? 'TBD',
        level: '',
        landmark: '',
      );
      
      final delivery = TaskLocation(
        building: deliveryBuilding ?? 'TBD',
        level: '',
        landmark: '',
      );

      final words = _descController.text.trim().split(' ');
      final shortTitle = words.take(6).join(' ');

      final task = HeroTask(
        title: shortTitle.length > 5 ? shortTitle : 'Nhiệm vụ mới',
        description: _descController.text,
        category: category,
        compensation: compensation,
        status: TaskStatus.open,
        urgency: TaskUrgency.normal,
        estimatedMinutes: 20,
        pickup: pickup,
        delivery: delivery,
        posterName: '',
        posterRating: 5.0,
        posterAvatarUrl: '',
        createdAt: DateTime.now(),
      );

      print('[PostTask] Đang tạo nhiệm vụ thủ công lên Firestore...');
      await _firestoreService.createTask(task);
      print('[PostTask] Tạo nhiệm vụ thành công!');

      if (!mounted) return;
      
      ShadToaster.of(context).show(
        const ShadToast(
          title: Text('Nhiệm vụ đã đăng!'),
          description: Text('Nhiệm vụ của bạn đã có trên bảng tin.'),
        ),
      );
      
      setState(() {
        isPosting = false;
        _descController.clear();
        selectedCategory = null;
        pickupBuilding = null;
        deliveryBuilding = null;
        compensation = 15000;
      });
    } catch (e) {
      print('[PostTask] Lỗi khi tạo nhiệm vụ: $e');
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
      // Phần thanh toán
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
                leading: Icon(
                  isPosting ? LucideIcons.loaderCircle : LucideIcons.check,
                  size: 16,
                ),
                child: Text(isPosting ? 'Đang đăng...' : 'Đăng nhiệm vụ'),
                onPressed: isPosting ? null : _postTaskManual,
              ),
              ShadButton.outline(
                child: const Text('Hủy'),
                onPressed: () {
                  setState(() {
                    _descController.clear();
                    selectedCategory = null;
                    pickupBuilding = null;
                    deliveryBuilding = null;
                    compensation = 15000;
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
                _previewRow(theme, LucideIcons.banknote, 'Thù lao',
                    '$compDisplay (Bạn trả $compDisplay)'),
                if (aiPreview['urgency'] != null) ...[
                  const SizedBox(height: 6),
                  _previewRow(theme, LucideIcons.zap, 'Độ khẩn cấp',
                      aiPreview['urgency'] == 'emergency' ? 'Khẩn cấp' : (aiPreview['urgency'] == 'urgent' ? 'Gấp' : 'Bình thường')),
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
