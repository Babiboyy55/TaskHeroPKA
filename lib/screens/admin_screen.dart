import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/firestore_service.dart';
import '../models/user_profile.dart';
import '../models/task_model.dart';
import '../theme/app_colors.dart';
import '../utils/currency_format.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

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
              Text('Admin Dashboard',
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        border: Border.all(color: theme.colorScheme.border),
        borderRadius: BorderRadius.circular(10),
      ),
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
                Row(
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
              ],
            ),
          ),
          // Earnings
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatVND(u.totalEarned),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.green600)),
              Text('tổng thu',
                  style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.mutedForeground)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (index * 40).ms);
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

            const SizedBox(height: 20),
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
              Text('+${formatVND(fee)} phí',
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.green600)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (index * 30).ms);
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
