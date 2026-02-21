import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/task_model.dart';
import '../widgets/task_card.dart';
import '../widgets/stat_card.dart';
import '../theme/app_colors.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';
import '../utils/currency_format.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int) onNavigate;
  final void Function(HeroTask) onTaskTap;

  const HomeScreen({
    super.key,
    required this.onNavigate,
    required this.onTaskTap,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  String selectedFilter = 'all';

  Future<void> _acceptTask(HeroTask task) async {
    if (task.id == null) return;
    try {
      await _firestoreService.acceptTask(task.id!);
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast(
            title: const Text('Đã nhận nhiệm vụ!'),
            description: Text('Bạn đang xử lý "${task.title}"'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast(
            title: const Text('Lỗi'),
            description: Text('Không thể nhận nhiệm vụ: $e'),
            backgroundColor: Colors.red.withValues(alpha: 0.1),
          ),
        );
      }
    }
  }

  // ... (rest of the class)

  bool get _isMobile => MediaQuery.of(context).size.width < 768;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfile?>(
      stream: _firestoreService.getUserProfileStream(),
      builder: (context, profileSnapshot) {
        final userProfile = profileSnapshot.data;
        final displayName = userProfile?.displayName.split(' ')[0] ?? 'Hero';
        
        return StreamBuilder<List<HeroTask>>(
          stream: _firestoreService.getMyAcceptedTasks(),
          builder: (context, missionsSnapshot) {
            final myMissions = missionsSnapshot.data ?? [];
            
            return StreamBuilder<List<HeroTask>>(
              stream: _firestoreService.getOpenTasks(),
              builder: (context, openTasksSnapshot) {
                final openTasks = openTasksSnapshot.data ?? [];
                
                // Filter logic
                final filteredTasks = selectedFilter == 'all' 
                    ? openTasks 
                    : openTasks.where((t) => t.category.name == selectedFilter).toList();

                return SingleChildScrollView(
                  padding: EdgeInsets.all(_isMobile ? 16 : 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(ShadTheme.of(context), displayName),
                      const SizedBox(height: 24),
                      _buildStatCards(ShadTheme.of(context), userProfile),
                      const SizedBox(height: 28),
                      // We can add an activity chart here if we have historical data
                      // For now, we'll hide it or keep it static? 
                      // Let's keep the static animation for visual flair but maybe standard data
                      _buildActivityChart(ShadTheme.of(context)).animate().fadeIn(duration: 500.ms, delay: 400.ms),
                      const SizedBox(height: 28),
                      if (myMissions.isNotEmpty) ...[
                        _buildMyMissions(ShadTheme.of(context), myMissions),
                        const SizedBox(height: 28),
                      ],
                      _buildRecentTasks(ShadTheme.of(context), openTasks, filteredTasks),
                      const SizedBox(height: 48),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(ShadThemeData theme, String name) {
    if (_isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bảng điều khiển', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: theme.colorScheme.foreground)),
          const SizedBox(height: 4),
          Text('Chào mừng trở lại, $name.', style: TextStyle(fontSize: 14, color: theme.colorScheme.mutedForeground)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ShadButton(
              leading: const Icon(LucideIcons.circlePlus, size: 16),
              child: const Text('Đăng nhiệm vụ'),
              onPressed: () => widget.onNavigate(2),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bảng điều khiển', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: theme.colorScheme.foreground)),
              const SizedBox(height: 4),
              Text('Chào mừng trở lại, $name. Đây là tổng quan của bạn.', style: TextStyle(fontSize: 14, color: theme.colorScheme.mutedForeground)),
            ],
          ),
        ),
        ShadButton(
          leading: const Icon(LucideIcons.circlePlus, size: 16),
          child: const Text('Đăng nhiệm vụ'),
          onPressed: () => widget.onNavigate(2),
        ),
      ],
    );
  }

  Widget _buildStatCards(ShadThemeData theme, UserProfile? profile) {
    final stats = [
      StatCard(icon: LucideIcons.dollarSign, title: 'Tổng thu nhập', value: formatVND(profile?.totalEarned ?? 0), subtitle: 'từ tháng trước', badge: '+0%'),
      StatCard(icon: LucideIcons.users, title: 'Nhiệm vụ đã đăng', value: '${profile?.tasksPosted ?? 0}', subtitle: 'từ tháng trước', badge: '+0%'),
      StatCard(icon: LucideIcons.circleCheck, title: 'Đã hoàn thành', value: '${profile?.tasksCompleted ?? 0}', subtitle: 'từ tháng trước', badge: '+0%'),
      StatCard(icon: LucideIcons.star, title: 'Đánh giá', value: '${profile?.rating.toStringAsFixed(1) ?? "5.0"}', subtitle: '${profile?.totalReviews ?? 0} đánh giá', badge: '+0'),
    ];
    // ... (keep layout builder)
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 600 ? 2 : 4;
        final spacing = constraints.maxWidth < 600 ? 12.0 : 16.0;
        final cardWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: stats.map((stat) {
            return SizedBox(
              width: cardWidth,
              child: stat,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildActivityChart(ShadThemeData theme) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _firestoreService.getWeeklyCompletedTasks(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        }

        final data = snapshot.data!;
        final totalTasks = data.fold<int>(0, (sum, item) => sum + (item['count'] as int));
        final weekData = data.map((e) => (e['day'] as String, e['count'] as int)).toList();
        
        // Handle case where all counts are 0
        final maxCount = weekData.map((e) => e.$2).fold(0, (a, b) => a > b ? a : b);
        final maxVal = maxCount == 0 ? 5 : maxCount; // Default scale if empty

        return Container(
          padding: EdgeInsets.all(_isMobile ? 16 : 20),
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
                  Expanded(child: Text('Hoạt động hàng tuần', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.foreground))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.orangeLight, borderRadius: BorderRadius.circular(4)),
                    child: Text('$totalTasks nhiệm vụ tuần này', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.orange600)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Nhiệm vụ hoàn thành mỗi ngày', style: TextStyle(fontSize: 13, color: theme.colorScheme.mutedForeground)),
              const SizedBox(height: 20),
              SizedBox(
                height: _isMobile ? 120 : 160,
                child: CustomPaint(
                  size: Size(double.infinity, _isMobile ? 120 : 160),
                  painter: _AreaChartPainter(
                    data: weekData.map((e) => e.$2.toDouble()).toList(),
                    maxVal: maxVal.toDouble(),
                    lineColor: AppColors.orange500,
                    fillColor: AppColors.orange500.withValues(alpha: 0.1),
                    gridColor: theme.colorScheme.border,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: weekData.map((d) => Expanded(child: Center(child: Text(d.$1, style: TextStyle(fontSize: 11, color: theme.colorScheme.mutedForeground))))).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMyMissions(ShadThemeData theme, List<HeroTask> myMissions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Nhiệm vụ đang thực hiện', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.foreground)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: AppColors.orangeLight, borderRadius: BorderRadius.circular(4)),
            child: Text('${myMissions.length}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.orange600)),
          ),
        ]),
        const SizedBox(height: 12),
        ...myMissions.map((task) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TaskCard(task: task, onTap: () => widget.onTaskTap(task)),
        )),
      ],
    );
  }

  Widget _buildRecentTasks(ShadThemeData theme, List<HeroTask> openTasks, List<HeroTask> filteredTasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Nhiệm vụ gần đây', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.foreground)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: theme.colorScheme.accent, borderRadius: BorderRadius.circular(4)),
              child: Text('${openTasks.length} đang mở', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: theme.colorScheme.foreground)),
            ),
            ...['all', 'food', 'academic', 'tech'].map((f) {
              final isActive = selectedFilter == f;
              final label = f == 'all' ? 'Tất cả' : f == 'food' ? 'Thực phẩm' : f == 'academic' ? 'Học tập' : 'Công nghệ';
              return GestureDetector(
                onTap: () => setState(() => selectedFilter = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.orange500 : Colors.transparent,
                    border: Border.all(color: isActive ? AppColors.orange500 : theme.colorScheme.border),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isActive ? Colors.white : theme.colorScheme.mutedForeground)),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 16),
        if (_isMobile) _buildMobileTaskList(theme, filteredTasks) else _buildDesktopTable(theme, filteredTasks),
      ],
    );
  }

  Widget _buildMobileTaskList(ShadThemeData theme, List<HeroTask> tasks) {
    if (tasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: theme.colorScheme.card, border: Border.all(color: theme.colorScheme.border), borderRadius: BorderRadius.circular(8)),
        child: Center(child: Text('Không có nhiệm vụ trong danh mục này', style: TextStyle(fontSize: 13, color: theme.colorScheme.mutedForeground))),
      );
    }
    return Column(
      children: tasks.map((task) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TaskCard(
          task: task,
          onTap: () => widget.onTaskTap(task),
          onAccept: task.status == TaskStatus.open ? () => _acceptTask(task) : null,
        ),
      )).toList(),
    );
  }

  Widget _buildDesktopTable(ShadThemeData theme, List<HeroTask> tasks) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: theme.colorScheme.accent, borderRadius: const BorderRadius.vertical(top: Radius.circular(8)), border: Border.all(color: theme.colorScheme.border)),
          child: Row(children: [
            Expanded(flex: 3, child: Text('Nhiệm vụ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.mutedForeground))),
            Expanded(child: Text('Danh mục', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.mutedForeground))),
            Expanded(child: Text('Thưởng', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.mutedForeground))),
            Expanded(child: Text('Trạng thái', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.mutedForeground))),
            const SizedBox(width: 80),
          ]),
        ),
        Container(
          decoration: BoxDecoration(border: Border(left: BorderSide(color: theme.colorScheme.border), right: BorderSide(color: theme.colorScheme.border), bottom: BorderSide(color: theme.colorScheme.border)), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8))),
          child: tasks.isEmpty
              ? Padding(padding: const EdgeInsets.all(32), child: Center(child: Text('Không có nhiệm vụ trong danh mục này', style: TextStyle(fontSize: 13, color: theme.colorScheme.mutedForeground))))
              : Column(children: tasks.map((task) => _tableRow(theme, task)).toList()),
        ),
      ],
    );
  }

  Widget _tableRow(ShadThemeData theme, HeroTask task) {
    return InkWell(
      onTap: () => widget.onTaskTap(task),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.colorScheme.border.withValues(alpha: 0.5)))),
        child: Row(children: [
          Expanded(flex: 3, child: Row(children: [
            ShadAvatar(task.posterAvatarUrl, size: const Size(28, 28), placeholder: Text(task.posterName.isNotEmpty ? task.posterName[0] : '?')),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(task.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: theme.colorScheme.foreground), overflow: TextOverflow.ellipsis),
              Text('${task.posterName} · ${task.timeAgo}', style: TextStyle(fontSize: 12, color: theme.colorScheme.mutedForeground)),
            ])),
          ])),
          Expanded(child: ShadBadge.secondary(child: Text(task.category.label))),
          Expanded(child: Text('\$${task.compensation.toStringAsFixed(2)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.foreground))),
          Expanded(child: _statusBadge(task.status)),
          SizedBox(width: 80, child: task.status == TaskStatus.open ? ShadButton(size: ShadButtonSize.sm, child: const Text('Nhận'), onPressed: () => _acceptTask(task)) : const SizedBox.shrink()),
        ]),
      ),
    );
  }

  Widget _statusBadge(TaskStatus status) {
    Color bg; Color fg; String label;
    switch (status) {
      case TaskStatus.open: bg = const Color(0xFFF0F9FF); fg = const Color(0xFF0284C7); label = 'Mở';
      case TaskStatus.accepted: case TaskStatus.inProgress: bg = const Color(0xFFFEF9C3); fg = const Color(0xFFA16207); label = 'Đã nhận';
      case TaskStatus.completed: bg = const Color(0xFFDCFCE7); fg = const Color(0xFF16A34A); label = 'Hoàn thành';
      case TaskStatus.cancelled: bg = const Color(0xFFFEE2E2); fg = const Color(0xFFDC2626); label = 'Đã hủy';
    }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)), child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg)));
  }
}

class _AreaChartPainter extends CustomPainter {
  final List<double> data; final double maxVal; final Color lineColor; final Color fillColor; final Color gridColor;
  _AreaChartPainter({required this.data, required this.maxVal, required this.lineColor, required this.fillColor, required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final gridPaint = Paint()..color = gridColor..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) { final y = size.height * i / 4; canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint); }
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) { final x = i * size.width / (data.length - 1); final y = size.height - (data[i] / maxVal) * size.height * 0.85; points.add(Offset(x, y)); }
    final fillPath = Path()..moveTo(0, size.height); for (final p in points) { fillPath.lineTo(p.dx, p.dy); } fillPath.lineTo(size.width, size.height); fillPath.close();
    canvas.drawPath(fillPath, Paint()..color = fillColor);
    final linePaint = Paint()..color = lineColor..strokeWidth = 2..style = PaintingStyle.stroke..strokeJoin = StrokeJoin.round;
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) { final prev = points[i - 1]; final curr = points[i]; final cpx = (prev.dx + curr.dx) / 2; linePath.cubicTo(cpx, prev.dy, cpx, curr.dy, curr.dx, curr.dy); }
    canvas.drawPath(linePath, linePaint);
    final dotPaint = Paint()..color = lineColor;
    for (final p in points) { canvas.drawCircle(p, 3, dotPaint); canvas.drawCircle(p, 1.5, Paint()..color = Colors.white); }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
