import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/firestore_service.dart';
import '../models/user_profile.dart';
import 'admin_user_detail_screen.dart';
import '../models/task_model.dart';
import '../theme/app_colors.dart';
import '../utils/currency_format.dart';

class AdminScreen extends StatefulWidget {
  final Function(UserProfile)? onUserSelected;
  const AdminScreen({super.key, this.onUserSelected});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _fs = FirestoreService();
  late TabController _tab;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            _buildTabBar(theme),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _buildUsersTab(theme),
                  _buildRevenueTab(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HEADER ─────────────────────────────────────────────────
  Widget _buildHeader(ShadThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.orangeGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(LucideIcons.shieldCheck,
                size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bảng Quản trị',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.foreground,
                  )),
              Text('Quản trị hệ thống TaskHero',
                  style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.mutedForeground)),
            ],
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  // ─── TAB BAR ────────────────────────────────────────────────
  Widget _buildTabBar(ShadThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.colorScheme.border)),
      ),
      child: TabBar(
        controller: _tab,
        labelColor: AppColors.orange600,
        unselectedLabelColor: theme.colorScheme.mutedForeground,
        indicatorColor: AppColors.orange500,
        indicatorWeight: 2,
        labelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(icon: Icon(LucideIcons.users, size: 16), text: 'Người dùng'),
          Tab(
              icon: Icon(LucideIcons.trendingUp, size: 16),
              text: 'Thu nhập'),
        ],
      ),
    );
  }

  // ─── TAB 1: USERS ───────────────────────────────────────────
  Widget _buildUsersTab(ShadThemeData theme) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Tìm theo tên hoặc mã ngành...',
              hintStyle:
                  TextStyle(color: theme.colorScheme.mutedForeground, fontSize: 13),
              prefixIcon: Icon(LucideIcons.search,
                  size: 16, color: theme.colorScheme.mutedForeground),
              filled: true,
              fillColor: theme.colorScheme.card,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colorScheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colorScheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.orange400),
              ),
            ),
          ),
        ),
        // User list
        Expanded(
          child: StreamBuilder<List<UserProfile>>(
            stream: _fs.getAllUsersStream(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final users = (snap.data ?? []).where((u) {
                if (_searchQuery.isEmpty) return true;
                return u.displayName.toLowerCase().contains(_searchQuery) ||
                    u.pillar.toLowerCase().contains(_searchQuery) ||
                    u.email.toLowerCase().contains(_searchQuery);
              }).toList();

              if (users.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.users,
                          size: 48,
                          color: theme.colorScheme.mutedForeground),
                      const SizedBox(height: 12),
                      Text('Không tìm thấy người dùng',
                          style: TextStyle(
                              color: theme.colorScheme.mutedForeground)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: users.length,
                itemBuilder: (context, i) =>
                    _userCard(theme, users[i], i),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _userCard(ShadThemeData theme, UserProfile u, int index) {
    return GestureDetector(
      onTap: () {
        if (widget.onUserSelected != null) {
          widget.onUserSelected!(u);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminUserDetailScreen(user: u),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.card,
          border: Border.all(color: theme.colorScheme.border),
          borderRadius: BorderRadius.circular(10),
        ),
        constraints: const BoxConstraints(minHeight: 80),
        child: Row(
          children: [
            // Avatar
            u.photoURL.isNotEmpty
                ? CircleAvatar(
                    radius: 22,
                    backgroundImage: NetworkImage(u.photoURL),
                  )
                : CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.orangeLight,
                    child: Text(u.initials,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.orange600)),
                  ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(u.displayName,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.foreground),
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (u.isAdmin)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.orangeLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('ADMIN',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.orange600)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('${u.pillar} · Năm ${u.year}',
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.mutedForeground)),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Icon(LucideIcons.star,
                            size: 11, color: AppColors.orange400),
                        const SizedBox(width: 3),
                        Text(u.rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 11)),
                        const SizedBox(width: 10),
                        Icon(LucideIcons.circleCheck,
                            size: 11, color: AppColors.green500),
                        const SizedBox(width: 3),
                        Text('${u.tasksCompleted} hoàn thành',
                            style: const TextStyle(fontSize: 11)),
                        const SizedBox(width: 10),
                        Icon(LucideIcons.clipboardList,
                            size: 11, color: theme.colorScheme.mutedForeground),
                        const SizedBox(width: 3),
                        Text('${u.tasksPosted} đăng',
                            style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Earnings
            SizedBox(
              width: 75,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(formatVND(u.totalEarned),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.green600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text('tổng thu',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 9,
                          color: theme.colorScheme.mutedForeground)),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms, delay: (index * 40).ms),
    );
  }

  // ─── TAB 2: REVENUE ─────────────────────────────────────────
  Widget _buildRevenueTab(ShadThemeData theme) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fs.getAdminStats(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final stats = snap.data ?? {};
        final totalUsers = stats['totalUsers'] ?? 0;
        final totalTasks = stats['totalTasks'] ?? 0;
        final completedTasks = stats['completedTasks'] ?? 0;
        final openTasks = stats['openTasks'] ?? 0;
        final totalVolume = (stats['totalVolume'] ?? 0.0) as double;
        final platformRevenue = (stats['platformRevenue'] ?? 0.0) as double;
        final recentCompleted =
            (stats['recentCompleted'] ?? <HeroTask>[]) as List<HeroTask>;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Stat grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              children: [
                _statCard(theme, 'Tổng người dùng',
                    '$totalUsers', LucideIcons.users, AppColors.blue500),
                _statCard(theme, 'Tổng nhiệm vụ',
                    '$totalTasks', LucideIcons.clipboardList, AppColors.purple500),
                _statCard(theme, 'Đã hoàn thành',
                    '$completedTasks', LucideIcons.circleCheck, AppColors.green500),
                _statCard(theme, 'Đang mở',
                    '$openTasks', LucideIcons.clock, AppColors.orange500),
              ],
            ),
            const SizedBox(height: 16),

            // Revenue cards
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.orange500, AppColors.orange600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(LucideIcons.trendingUp,
                        size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text('Doanh thu Platform',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                  ]),
                  const SizedBox(height: 12),
                  Text(formatVND(platformRevenue),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800)),
                  Text('Phí dịch vụ 5% trên ${formatVND(totalVolume)} tổng giao dịch',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

            const SizedBox(height: 24),
            _buildLeaderboard(theme),

            const SizedBox(height: 24),
            Text('Giao dịch gần đây',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.foreground)),
            const SizedBox(height: 10),

            if (recentCompleted.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('Chưa có giao dịch hoàn thành',
                      style: TextStyle(
                          color: theme.colorScheme.mutedForeground)),
                ),
              )
            else
              ...recentCompleted.take(20).toList().asMap().entries.map(
                    (e) => _transactionRow(theme, e.value, e.key),
                  ),
          ],
        );
      },
    );
  }

  Widget _statCard(ShadThemeData theme, String label, String value,
      IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        border: Border.all(color: theme.colorScheme.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 20, color: color),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.foreground)),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.mutedForeground)),
            ],
          )
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildLeaderboard(ShadThemeData theme) {
    return FutureBuilder<Map<String, List<UserProfile>>>(
      future: _fs.getLeaderboardData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final topEarners = snapshot.data!['topEarners'] ?? [];
        final topSpenders = snapshot.data!['topSpenders'] ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bảng xếp hạng',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.foreground)),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _leaderboardColumn(theme, '💰 Chăm chỉ', topEarners, true)),
                const SizedBox(width: 12),
                Expanded(child: _leaderboardColumn(theme, '💎 Đại gia (VIP)', topSpenders, false)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _leaderboardColumn(ShadThemeData theme, String title, List<UserProfile> users, bool isEarner) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.muted.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isEarner ? AppColors.orange600 : Colors.indigo)),
          Text(isEarner ? 'Chăm chỉ đi làm & kiếm tiền' : 'Chi tiền thuê nhiều (Khách VIP)',
              style: TextStyle(fontSize: 9, color: theme.colorScheme.mutedForeground)),
          const SizedBox(height: 10),
          if (users.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Chưa có dữ liệu', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ),
          ...users.asMap().entries.map((e) {
            final u = e.value;
            final idx = e.key + 1;
            final amount = isEarner ? u.totalEarned : u.totalSpent;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: idx == 1 ? AppColors.orange500 : (idx == 2 ? Colors.grey : (idx == 3 ? Colors.brown : Colors.transparent)),
                      shape: BoxShape.circle,
                    ),
                    child: Text(idx.toString(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: idx <= 3 ? Colors.white : Colors.grey)),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(u.displayName, 
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis),
                  ),
                  Text(formatVND(amount), 
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isEarner ? AppColors.green600 : Colors.indigo)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _transactionRow(ShadThemeData theme, HeroTask task, int index) {
    final fee = task.compensation * 0.05;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        border: Border.all(color: theme.colorScheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(task.category.emoji,
              style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.foreground),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (task.completedAt != null)
                  Text(
                    _formatDate(task.completedAt!),
                    style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.mutedForeground),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatVND(task.compensation),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              Text(task.status.label, 
                  style: TextStyle(fontSize: 10, color: _getStatusColor(task.status), fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (index * 30).ms);
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.open: return Colors.blue;
      case TaskStatus.accepted: return Colors.indigo;
      case TaskStatus.inProgress: return Colors.orange;
      case TaskStatus.completed: return Colors.green;
      case TaskStatus.cancelled: return Colors.red;
    }
  }
}
