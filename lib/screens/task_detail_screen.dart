import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';
import '../theme/app_colors.dart';
import '../services/firestore_service.dart';
import '../utils/currency_format.dart';

class TaskDetailScreen extends StatefulWidget {
  final HeroTask task;
  final VoidCallback onBack;

  const TaskDetailScreen({
    super.key,
    required this.task,
    required this.onBack,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isAccepting = false;

  bool get _isMobile => MediaQuery.of(context).size.width < 768;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final taskId = widget.task.id;

    // If no task ID, fall back to static data (shouldn't happen with real tasks)
    if (taskId == null) {
      return _buildContent(theme, widget.task);
    }

    // Live-updating stream from Firestore
    return StreamBuilder<HeroTask?>(
      stream: _firestoreService.getTaskStream(taskId),
      initialData: widget.task,
      builder: (context, snapshot) {
        final task = snapshot.data ?? widget.task;
        return _buildContent(theme, task);
      },
    );
  }

  Widget _buildContent(ShadThemeData theme, HeroTask task) {
    final isAccepted = task.status == TaskStatus.accepted || task.status == TaskStatus.inProgress;
    final isCompleted = task.status == TaskStatus.completed;
    final isCancelled = task.status == TaskStatus.cancelled;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isPoster = task.posterId != null && task.posterId == currentUid;
    final isHero = task.heroId != null && task.heroId == currentUid;
    final isOpenAndPoster = isPoster && task.status == TaskStatus.open;
    final showAccept = task.status == TaskStatus.open && !isPoster;
    // Poster confirmation = task is completed (poster released payment)
    final posterConfirmed = isCompleted;
    // Show payment to POSTER when hero has delivered but poster hasn't paid yet
    final showPaymentForPoster = isPoster && task.delivered && !isCompleted;

    return SingleChildScrollView(
      padding: EdgeInsets.all(_isMobile ? 16 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          GestureDetector(
            onTap: widget.onBack,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.arrowLeft,
                    size: 16, color: AppColors.orange500),
                const SizedBox(width: 6),
                Text('Quay lại',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.orange600)),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 20),
          _buildHeader(theme, task)
              .animate()
              .fadeIn(duration: 400.ms, delay: 50.ms),
          const SizedBox(height: 20),
          if (isAccepted || isCompleted) ...[
            _buildProgressTracker(theme, task, isHero: isHero, isCompleted: isCompleted, posterConfirmed: posterConfirmed, isPoster: isPoster)
                .animate()
                .fadeIn(duration: 400.ms, delay: 150.ms)
                .slideY(
                    begin: 0.05,
                    end: 0,
                    duration: 400.ms,
                    delay: 150.ms),
            const SizedBox(height: 20),
          ],
          if (_isMobile) ...[
            _buildDetails(theme, task)
                .animate()
                .fadeIn(duration: 400.ms, delay: 200.ms),
            const SizedBox(height: 16),
            _buildLocationCards(theme, task)
                .animate()
                .fadeIn(duration: 400.ms, delay: 250.ms),
            const SizedBox(height: 16),
            _buildPaymentBreakdown(theme, task)
                .animate()
                .fadeIn(duration: 400.ms, delay: 300.ms),
            const SizedBox(height: 16),
            _buildPosterInfo(theme, task)
                .animate()
                .fadeIn(duration: 400.ms, delay: 350.ms),
            if (showAccept) ...[
              const SizedBox(height: 16),
              _buildAcceptSection(theme, task)
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 400.ms),
            ],
            if (isOpenAndPoster) ...[
              const SizedBox(height: 16),
              _buildCancelSection(theme, task)
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 400.ms),
            ],
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildDetails(theme, task)
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 200.ms),
                      const SizedBox(height: 16),
                      _buildLocationCards(theme, task)
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 250.ms),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildPaymentBreakdown(theme, task)
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 300.ms),
                      const SizedBox(height: 16),
                      _buildPosterInfo(theme, task)
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 350.ms),
                      if (showAccept) ...[
                        const SizedBox(height: 16),
                        _buildAcceptSection(theme, task)
                            .animate()
                            .fadeIn(
                                duration: 400.ms, delay: 400.ms),
                      ],
                      if (isOpenAndPoster) ...[
                        const SizedBox(height: 16),
                        _buildCancelSection(theme, task)
                            .animate()
                            .fadeIn(
                                duration: 400.ms, delay: 400.ms),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          if (showPaymentForPoster) ...[
            const SizedBox(height: 20),
            _buildGooglePaySection(theme, task)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.05, end: 0, duration: 400.ms),
          ],
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildHeader(ShadThemeData theme, HeroTask task) {
    if (_isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.foreground),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                formatVND(task.compensation),
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.orange600),
              ),
              const SizedBox(width: 8),
              Text(
                  'Hero nhận ${formatVND(task.heroEarnings)}',
                  style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.mutedForeground)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _buildStatusPills(theme, task),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.foreground),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _buildStatusPills(theme, task),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatVND(task.compensation),
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.orange600),
            ),
            Text(
                'Hero nhận ${formatVND(task.heroEarnings)}',
                style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.mutedForeground)),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildStatusPills(ShadThemeData theme, HeroTask task) {
    return [
      _pill(task.category.label, AppColors.orangeLight,
          AppColors.orange600),
      if (task.urgency == TaskUrgency.urgent)
        _pill('KHẨN CẤP', const Color(0xFFFEE2E2),
            const Color(0xFFDC2626)),
      if (task.status == TaskStatus.accepted)
        _pill('Đã nhận', const Color(0xFFDCFCE7),
            const Color(0xFF16A34A)),
      if (task.status == TaskStatus.inProgress)
        _pill('Đang thực hiện', const Color(0xFFF3E8FF),
            const Color(0xFF7C3AED)),
      if (task.status == TaskStatus.completed)
        _pill('Hoàn thành', const Color(0xFFDCFCE7),
            const Color(0xFF16A34A)),
      if (task.status == TaskStatus.cancelled)
        _pill('Đã hủy', const Color(0xFFFEE2E2),
            const Color(0xFFDC2626)),
      if (task.status == TaskStatus.open)
        _pill('Mở', AppColors.orangeLight, AppColors.orange600),
    ];
  }

  Widget _pill(String label, Color bg, Color fg) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: fg)),
    );
  }

  Widget _buildProgressTracker(ShadThemeData theme, HeroTask task, {required bool isHero, required bool isCompleted, required bool posterConfirmed, required bool isPoster}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        border: Border.all(color: theme.colorScheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Tiến độ nhiệm vụ',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.foreground)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.orangeLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                    posterConfirmed
                        ? '4/4'
                        : task.delivered
                            ? '3/4'
                            : task.pickedUp
                                ? '2/4'
                                : '1/4',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.orange600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _step(theme, 'Đã nhận nhiệm vụ',
              'Bạn đã nhận nhiệm vụ này', true, null),
          _step(theme, 'Đã lấy hàng', task.pickup.full, task.pickedUp,
              isHero && !task.pickedUp && !isCompleted
                  ? () async {
                      if (task.id != null) {
                        await _firestoreService.updateTaskProgress(task.id!, {
                          'pickedUp': true,
                          'status': TaskStatus.inProgress.name,
                        });
                      }
                    }
                  : null,
              actionLabel: 'Đánh dấu đã lấy'),
          _step(
              theme,
              'Đã giao',
              task.delivery.full,
              task.delivered,
              isHero && task.pickedUp && !task.delivered && !isCompleted
                  ? () async {
                      if (task.id != null) {
                        await _firestoreService.updateTaskProgress(task.id!, {
                          'delivered': true,
                        });
                      }
                      if (mounted) {
                        ShadToaster.of(context).show(
                          const ShadToast(
                            title: Text('Đã đánh dấu giao hàng'),
                            description: Text('Chờ người đăng xác nhận và thanh toán.'),
                          ),
                        );
                      }
                    }
                  : null,
              actionLabel: 'Đánh dấu đã giao'),
          _step(
              theme,
              'Người đăng đã xác nhận',
              posterConfirmed
                  ? 'Đã thanh toán!'
                  : 'Chờ xác nhận',
              posterConfirmed,
              null,
              isLast: true),
          if (posterConfirmed) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.partyPopper,
                      size: 16, color: Color(0xFF16A34A)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isHero
                          ? 'Hoàn thành! Bạn kiếm được \$${task.heroEarnings.toStringAsFixed(2)}'
                          : 'Hoàn thành! Đã thanh toán \$${task.compensation.toStringAsFixed(2)}.',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF16A34A)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Hero sees "waiting for poster" message after delivering but before completion
          if (task.delivered && !posterConfirmed && isHero) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.orange400.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.clock,
                      size: 16, color: AppColors.orange500),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Chờ ${task.posterName} xác nhận giao hàng và thanh toán...',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.orange600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _step(ShadThemeData theme, String label, String subtitle,
      bool done, VoidCallback? action,
      {String actionLabel = '', bool isLast = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(
                done
                    ? LucideIcons.circleCheck
                    : LucideIcons.circle,
                size: 18,
                color: done
                    ? AppColors.orange500
                    : theme.colorScheme.mutedForeground,
              ),
              if (!isLast)
                Container(
                  width: 1,
                  height: 24,
                  color: done
                      ? AppColors.orange500
                          .withValues(alpha: 0.3)
                      : theme.colorScheme.border,
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        done ? FontWeight.w600 : FontWeight.w400,
                    color: done
                        ? theme.colorScheme.foreground
                        : theme.colorScheme.mutedForeground,
                  ),
                ),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color:
                            theme.colorScheme.mutedForeground)),
                if (action != null) ...[
                  const SizedBox(height: 6),
                  ShadButton(
                    size: ShadButtonSize.sm,
                    child: Text(actionLabel),
                    onPressed: action,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(ShadThemeData theme, HeroTask task) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          const SizedBox(height: 12),
          Text(task.description,
              style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.mutedForeground)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _detailChip(
                  theme, LucideIcons.clock, '${task.estimatedMinutes}min'),
              _detailChip(
                  theme, LucideIcons.mapPin, task.delivery.building),
              _detailChip(
                  theme, LucideIcons.tag, task.category.label),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailChip(
      ShadThemeData theme, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.orange500),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.mutedForeground)),
      ],
    );
  }

  Widget _buildLocationCards(ShadThemeData theme, HeroTask task) {
    if (_isMobile) {
      return Column(
        children: [
          _locationCard(
              theme, 'Lấy hàng', LucideIcons.mapPin, task.pickup),
          const SizedBox(height: 8),
          _locationCard(theme, 'Giao hàng',
              LucideIcons.navigation, task.delivery),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
            child: _locationCard(
                theme, 'Lấy hàng', LucideIcons.mapPin, task.pickup)),
        const SizedBox(width: 12),
        Expanded(
            child: _locationCard(theme, 'Giao hàng',
                LucideIcons.navigation, task.delivery)),
      ],
    );
  }

  Widget _locationCard(ShadThemeData theme, String label,
      IconData icon, TaskLocation loc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        border: Border.all(color: theme.colorScheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.orange500),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.mutedForeground)),
            ],
          ),
          const SizedBox(height: 8),
          Text(loc.building,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.foreground)),
          Text(loc.level,
              style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.mutedForeground)),
          if (loc.landmark.isNotEmpty)
            Text(loc.landmark,
                style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.mutedForeground)),
        ],
      ),
    );
  }

  Widget _buildPaymentBreakdown(
      ShadThemeData theme, HeroTask task) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        border: Border.all(color: theme.colorScheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thanh toán',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.foreground)),
          const SizedBox(height: 12),
          _payRow(theme, 'Tiền thưởng', formatVND(task.compensation)),
          const SizedBox(height: 6),
          _payRow(theme, 'Phí dịch vụ (5%)',
              '-${formatVND(task.platformFee)}',
              muted: true),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: theme.colorScheme.border),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Hero nhận',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.orange600)),
              Text(
                  formatVND(task.heroEarnings),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.orange600)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.orangeLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.creditCard,
                    size: 14, color: AppColors.orange500),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Chuyển khoản / Ví điện tử',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.foreground)),
                ),
                Icon(LucideIcons.circleCheck,
                    size: 14,
                    color: const Color(0xFF16A34A)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _payRow(ShadThemeData theme, String label, String value,
      {bool muted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: muted
                    ? theme.colorScheme.mutedForeground
                    : theme.colorScheme.foreground)),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                color: muted
                    ? theme.colorScheme.mutedForeground
                    : theme.colorScheme.foreground)),
      ],
    );
  }

  Widget _buildPosterInfo(ShadThemeData theme, HeroTask task) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        border: Border.all(color: theme.colorScheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Người đăng',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.foreground)),
          const SizedBox(height: 12),
          Row(
            children: [
              ShadAvatar(
                task.posterAvatarUrl,
                size: const Size(40, 40),
                placeholder: Text(task.posterName.isNotEmpty ? task.posterName[0] : '?'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.posterName,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.foreground)),
                    Row(
                      children: [
                        const Icon(LucideIcons.star,
                            size: 12, color: Colors.amber),
                        const SizedBox(width: 3),
                        Text('${task.posterRating} đánh giá',
                            style: TextStyle(
                                fontSize: 12,
                                color: theme
                                    .colorScheme.mutedForeground)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ShadButton.outline(
                  size: ShadButtonSize.sm,
                  leading: const Icon(
                      LucideIcons.messageCircle,
                      size: 14),
                  child: const Text('Trò chuyện'),
                  onPressed: () {
                    ShadToaster.of(context).show(
                      const ShadToast(
                        title: Text('Trò chuyện'),
                        description: Text(
                            'Tin nhắn sắp ra mắt!'),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ShadButton.outline(
                  size: ShadButtonSize.sm,
                  leading:
                      const Icon(LucideIcons.phone, size: 14),
                  child: const Text('Gọi'),
                  onPressed: () {
                    ShadToaster.of(context).show(
                      const ShadToast(
                        title: Text('Gọi'),
                        description: Text(
                            'Cuộc gọi sắp ra mắt!'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptSection(
      ShadThemeData theme, HeroTask task) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        border: Border.all(
            color: AppColors.orange400.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sẵn sàng giúp đỡ?',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.foreground)),
          const SizedBox(height: 4),
          Text(
              'Kiếm \$${task.heroEarnings.toStringAsFixed(2)} cho nhiệm vụ này.',
              style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.mutedForeground)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ShadButton(
              size: ShadButtonSize.lg,
              leading: _isAccepting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(LucideIcons.zap, size: 16),
              child: Text(_isAccepting ? 'Đang nhận...' : 'Nhận nhiệm vụ'),
              onPressed: _isAccepting ? null : () async {
                if (task.id == null) return;
                setState(() => _isAccepting = true);
                try {
                  await _firestoreService.acceptTask(task.id!);
                  if (mounted) {
                    ShadToaster.of(context).show(
                      ShadToast(
                        title: const Text('Đã nhận nhiệm vụ!'),
                        description: Text(
                            'Đi đến ${task.pickup.full} để lấy hàng'),
                      ),
                    );
                    // Go back since the task state changed
                    widget.onBack();
                  }
                } catch (e) {
                  if (mounted) {
                    ShadToaster.of(context).show(
                      ShadToast.destructive(
                        title: const Text('Không thể nhận nhiệm vụ'),
                        description: Text(e.toString()),
                      ),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isAccepting = false);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelSection(ShadThemeData theme, HeroTask task) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        border: Border.all(color: const Color(0xFFFECACA)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nhiệm vụ của bạn',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.foreground)),
          const SizedBox(height: 4),
          Text(
              'Nhiệm vụ này đang chờ Hero nhận.',
              style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.mutedForeground)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ShadButton.destructive(
              size: ShadButtonSize.lg,
              leading: const Icon(LucideIcons.x, size: 16, color: Colors.white),
              child: const Text('Hủy nhiệm vụ', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                if (task.id == null) return;
                try {
                  await _firestoreService.cancelTask(task.id!);
                  if (mounted) {
                    ShadToaster.of(context).show(
                      const ShadToast(
                        title: Text('Đã hủy nhiệm vụ'),
                        description: Text('Nhiệm vụ của bạn đã bị xóa.'),
                      ),
                    );
                    widget.onBack();
                  }
                } catch (e) {
                  if (mounted) {
                    ShadToaster.of(context).show(
                      ShadToast.destructive(
                        title: const Text('Lỗi'),
                        description: Text(e.toString()),
                      ),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGooglePaySection(
      ShadThemeData theme, HeroTask task) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        border: Border.all(color: theme.colorScheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.creditCard,
                  size: 18, color: AppColors.orange500),
              const SizedBox(width: 8),
              Text('Google Pay',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.foreground)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Connected',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF16A34A))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.orangeLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Payment Amount',
                        style: TextStyle(
                            fontSize: 13,
                            color: theme
                                .colorScheme.mutedForeground)),
                    Text(
                        '\$${task.compensation.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.orange600)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Paying to',
                        style: TextStyle(
                            fontSize: 13,
                            color: theme
                                .colorScheme.mutedForeground)),
                    Text('TaskHero Escrow',
                        style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.foreground)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Payment Method',
                        style: TextStyle(
                            fontSize: 13,
                            color: theme
                                .colorScheme.mutedForeground)),
                    Text('Visa ****6411',
                        style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.foreground)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () async {
                try {
                  // Simulate payment processing
                  ShadToaster.of(context).show(
                    const ShadToast(
                      title: Text('Processing Payment...'),
                      description: Text('Contacting payment gateway'),
                    ),
                  );
                  
                  await Future.delayed(const Duration(seconds: 2));
                  
                  // Complete the task in Firestore (releases escrow)
                  if (task.id != null) {
                    await _firestoreService.completeTask(task.id!);
                  }
                  
                  if (context.mounted) {
                    ShadToaster.of(context).show(
                      const ShadToast(
                        title: Text('Payment Processed!'),
                        description: Text('Funds released to Hero. Task Completed!'),
                      ),
                    );
                    
                    // Wait a bit and go back
                    Future.delayed(const Duration(seconds: 2), widget.onBack);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ShadToaster.of(context).show(
                      ShadToast(
                        title: const Text('Payment Failed'),
                        description: Text(e.toString()),
                        backgroundColor: Colors.red.withValues(alpha: 0.1),
                      ),
                    );
                  }
                }
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.orangeGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.creditCard,
                        size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Release Payment via Google Pay',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Confirm delivery and release payment to the Hero.',
              style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.mutedForeground),
            ),
          ),
        ],
      ),
    );
  }
}
