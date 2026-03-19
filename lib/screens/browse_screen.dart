import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/task_model.dart';
import '../widgets/task_card.dart';
import '../theme/app_colors.dart';
import '../services/firestore_service.dart';
import '../utils/currency_format.dart';

class BrowseScreen extends StatefulWidget {
  final void Function(HeroTask) onTaskTap;

  const BrowseScreen({super.key, required this.onTaskTap});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String? selectedCategory;
  String searchQuery = '';
  String activeTab = 'open';

  List<HeroTask> _filterTasks(List<HeroTask> tasks) {
    var filtered = tasks.toList();

    if (activeTab == 'open') {
      filtered = filtered.where((t) => t.status == TaskStatus.open).toList();
    } else if (activeTab == 'accepted') {
      filtered = filtered.where((t) => t.status == TaskStatus.accepted || t.status == TaskStatus.inProgress).toList();
    }

    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where((t) =>
              t.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
              t.description.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }
    if (selectedCategory != null) {
      filtered = filtered.where((t) => t.category.name == selectedCategory).toList();
    }
    return filtered;
  }

  bool get _isMobile => MediaQuery.of(context).size.width < 768;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return StreamBuilder<List<HeroTask>>(
      stream: _firestoreService.getAllTasks(),
      builder: (context, snapshot) {
        final allTasks = snapshot.data ?? [];
        final filteredTasks = _filterTasks(allTasks);
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return SingleChildScrollView(
          padding: EdgeInsets.all(_isMobile ? 16 : 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme),
              const SizedBox(height: 20),
              _buildFiltersBar(theme, filteredTasks.length),
              const SizedBox(height: 16),
              _buildCategoryPills(theme),
              const SizedBox(height: 20),
              _buildTabBar(theme),
              const SizedBox(height: 0),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_isMobile) 
                _buildMobileList(theme, filteredTasks) 
              else 
                _buildTable(theme, filteredTasks),
              const SizedBox(height: 48),
            ],
          ),
        );
      },
    );
  }


  Widget _buildHeader(ShadThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Duyệt nhiệm vụ',
          style: TextStyle(
            fontSize: _isMobile ? 22 : 24,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.foreground,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tìm và nhận nhiệm vụ từ cộng đồng PKA.',
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.mutedForeground,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildFiltersBar(ShadThemeData theme, int taskCount) {
    return Row(
      children: [
        Expanded(
          child: ShadInput(
            placeholder: const Text('Tìm kiếm nhiệm vụ...'),
            leading: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(LucideIcons.search, size: 16,
                  color: theme.colorScheme.mutedForeground),
            ),
            onChanged: (v) => setState(() => searchQuery = v),
          ),
        ),
        if (!_isMobile) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.orangeLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.listFilter, size: 14,
                    color: AppColors.orange600),
                const SizedBox(width: 6),
                Text(
                  '$taskCount kết quả',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.orange600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }

  Widget _buildCategoryPills(ShadThemeData theme) {
    final cats = [null, ...TaskCategory.values];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: cats.map((cat) {
          final isActive = selectedCategory == cat?.name;
          final label =
              cat == null ? 'Tất cả nhiệm vụ' : '${cat.emoji} ${cat.label}';
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => setState(() =>
                  selectedCategory = isActive ? null : cat?.name),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.orange500 : Colors.transparent,
                  border: Border.all(
                    color:
                        isActive ? AppColors.orange500 : theme.colorScheme.border,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isActive
                        ? Colors.white
                        : theme.colorScheme.mutedForeground,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }

  Widget _buildTabBar(ShadThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.colorScheme.border)),
      ),
      child: Row(
        children: [
          _tab(theme, 'open', 'Nhiệm vụ mở'),
          _tab(theme, 'accepted', 'Đã nhận'),
          _tab(theme, 'all', 'Tất cả'),
        ],
      ),
    );
  }

  Widget _tab(ShadThemeData theme, String value, String label) {
    final isActive = activeTab == value;
    return GestureDetector(
      onTap: () => setState(() => activeTab = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color:
                  isActive ? AppColors.orange500 : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive
                ? AppColors.orange600
                : theme.colorScheme.mutedForeground,
          ),
        ),
      ),
    );
  }

  // ─── MOBILE: card list ─────────────────────────────────────
  Widget _buildMobileList(ShadThemeData theme, List<HeroTask> tasks) {
    if (tasks.isEmpty) return _emptyState(theme);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: tasks.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TaskCard(
              task: entry.value,
              onTap: () => widget.onTaskTap(entry.value),
              onAccept: entry.value.status == TaskStatus.open
                  ? () => _accept(entry.value)
                  : null,
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms, delay: (entry.key * 50).ms)
              .slideX(
                  begin: -0.03,
                  end: 0,
                  duration: 300.ms,
                  delay: (entry.key * 50).ms);
        }).toList(),
      ),
    );
  }

  // ─── DESKTOP: table ────────────────────────────────────────
  Widget _buildTable(ShadThemeData theme, List<HeroTask> tasks) {

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.border),
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.accent,
            ),
            child: Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text('Nhiệm vụ',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.mutedForeground))),
                Expanded(
                    child: Text('Danh mục',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.mutedForeground))),
                Expanded(
                    child: Text('Thưởng',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.mutedForeground))),
                Expanded(
                    child: Text('Thời gian',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.mutedForeground))),
                Expanded(
                    child: Text('Trạng thái',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.mutedForeground))),
                const SizedBox(width: 80),
              ],
            ),
          ),
          // Rows
          if (tasks.isEmpty)
            _emptyState(theme)
          else
            ...tasks.asMap().entries.map((entry) => _row(theme, entry.value)
                .animate()
                .fadeIn(
                    duration: 300.ms, delay: (entry.key * 50).ms)
                .slideX(
                    begin: -0.02,
                    end: 0,
                    duration: 300.ms,
                    delay: (entry.key * 50).ms)),
          // Footer
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(color: theme.colorScheme.border)),
            ),
            child: Row(
              children: [
                Text(
                  '${tasks.length} nhiệm vụ',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(ShadThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(LucideIcons.searchX,
              size: 40, color: theme.colorScheme.mutedForeground),
          const SizedBox(height: 12),
          Text(
            'Không có nhiệm vụ phù hợp với bộ lọc',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.foreground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Thử điều chỉnh tìm kiếm hoặc danh mục',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(ShadThemeData theme, HeroTask task) {
    return InkWell(
      onTap: () => widget.onTaskTap(task),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
                color: theme.colorScheme.border.withValues(alpha: 0.5)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  ShadAvatar(
                    task.posterAvatarUrl,
                    size: const Size(28, 28),
                    placeholder: Text(task.posterName.isNotEmpty ? task.posterName[0] : '?'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.foreground,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          task.posterName,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Text(
                task.category.label,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
            ),
            Expanded(
              child: Text(
                formatVND(task.compensation),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.orange600,
                ),
              ),
            ),
            Expanded(
              child: Text(
                '${task.estimatedMinutes} phút',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
            ),
            Expanded(child: _statusBadge(task.status)),
            SizedBox(
              width: 80,
              child: task.status == TaskStatus.open
                  ? ShadButton(
                      size: ShadButtonSize.sm,
                      child: const Text('Nhận'),
                      onPressed: () => _accept(task),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _accept(HeroTask task) async {
    if (task.id == null) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Lỗi'),
          description: Text('Lỗi: Thiếu ID nhiệm vụ'),
        ),
      );
      return;
    }

    try {
      await _firestoreService.acceptTask(task.id!);
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast(
          title: const Text('Đã nhận nhiệm vụ!'),
          description: Text('Bạn đang xử lý "${task.title}"'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('Lỗi'),
          description: Text('Không thể nhận nhiệm vụ: $e'),
        ),
      );
    }
  }

  Widget _statusBadge(TaskStatus status) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case TaskStatus.open:
        bg = AppColors.orangeLight;
        fg = AppColors.orange600;
        label = 'Mở';
      case TaskStatus.accepted:
      case TaskStatus.inProgress:
        bg = const Color(0xFFFEF9C3);
        fg = const Color(0xFFA16207);
        label = 'Đã nhận';
      case TaskStatus.completed:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF16A34A);
        label = 'Hoàn thành';
      case TaskStatus.cancelled:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        label = 'Đã hủy';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w500, color: fg)),
    );
  }
}
