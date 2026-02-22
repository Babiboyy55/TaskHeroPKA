import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';
import '../models/task_model.dart';
import '../theme/app_colors.dart';
import '../utils/currency_format.dart';

class ProfileScreen extends StatefulWidget {
  final void Function(HeroTask)? onTaskTap;

  const ProfileScreen({super.key, this.onTaskTap});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  bool _isCreatingProfile = false;
  String? _creationError;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _createProfile() async {
    if (_authService.currentUser == null) return;
    
    setState(() {
      _isCreatingProfile = true;
      _creationError = null;
    });

    try {
      print('[Profile] Đang tạo hồ sơ cho ${_authService.currentUser?.uid}');
      await _firestoreService.createOrUpdateUserProfile(_authService.currentUser!);
      print('[Profile] Tạo hồ sơ thành công');
    } catch (e) {
      print('[Profile] Tạo hồ sơ thất bại: $e');
      if (mounted) {
        setState(() {
          _creationError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingProfile = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: StreamBuilder<UserProfile?>(
        stream: _firestoreService.getUserProfileStream(),
        builder: (context, snapshot) {
          // Hiển thị trạng thái đang tải
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tải hồ sơ...'),
                ],
              ),
            );
          }

          // Hiển thị trạng thái lỗi
          if (snapshot.hasError) {
            print('[Profile] Lỗi tải hồ sơ: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.x, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Lỗi tải hồ sơ'),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ShadButton(
                    onPressed: () {
                      setState(() {}); // Kích hoạt rebuild để thử lại
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final userProfile = snapshot.data;
          
          if (userProfile == null) {
            // Kiểm tra nếu cần tự động tạo hồ sơ (chỉ 1 lần/phiên dể tránh vòng lặp)
            if (_authService.currentUser != null && !_isCreatingProfile) {
               // Xác minh nếu chưa thử gần đây
               _isCreatingProfile = true;
               WidgetsBinding.instance.addPostFrameCallback((_) {
                 _createProfile();
               });
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Đang thiết lập hồ sơ...'),
                  const SizedBox(height: 8),
                  Text(
                    'User ID: ${_authService.currentUser?.uid.substring(0, 5) ?? "unknown"}...',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  if (_creationError != null)
                     Text('Lỗi: $_creationError', style: const TextStyle(color: Colors.red)),
                  
                  const SizedBox(height: 16),
                  ShadButton(
                    onPressed: _isCreatingProfile ? null : _createProfile,
                    child: Text(_isCreatingProfile ? 'Đang tạo...' : 'Sửa nhanh'),
                  ),
                  const SizedBox(height: 8),
                  ShadButton.outline(
                    onPressed: () => _authService.signOut(), // Thoát khẩn cấp
                    child: const Text('Đăng xuất & Thử lại'),
                  ),
                ],
              ),
            );
          }

          print('[Profile] Đã tải hồ sơ: ${userProfile.displayName}');

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tiêu đề trang
                Text(
                  'Hồ sơ',
                  style: TextStyle(
                    fontSize: isMobile ? 24 : 32,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.foreground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Quản lý tài khoản và xem thống kê của bạn.',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
                const SizedBox(height: 24),

                // Thẻ thông tin người dùng
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.card,
                    border: Border.all(color: theme.colorScheme.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hàng trên: Avatar + Thông tin + Nút đăng xuất
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 36,
                            backgroundImage: userProfile.photoURL.isNotEmpty
                                ? NetworkImage(userProfile.photoURL)
                                : null,
                            backgroundColor: AppColors.orange50,
                            child: userProfile.photoURL.isEmpty
                                ? Text(
                                    userProfile.initials,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.orange600,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),

                          // Tên + Pillar
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userProfile.displayName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.foreground,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () => _showEditPillarYearDialog(context, userProfile),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          userProfile.pillarYear,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: theme.colorScheme.mutedForeground,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        LucideIcons.pencil,
                                        size: 13,
                                        color: AppColors.orange500,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Nút đăng xuất
                          const SizedBox(width: 8),
                          ShadButton.destructive(
                            onPressed: () async {
                              await _authService.signOut();
                            },
                            size: ShadButtonSize.sm,
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.logOut, size: 14, color: Colors.white),
                                SizedBox(width: 6),
                                Text('Đăng xuất', style: TextStyle(color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Hàng dưới: Rating + Tỉ lệ hoàn thành
                      Row(
                        children: [
                          const Icon(LucideIcons.star, size: 15, color: AppColors.orange500),
                          const SizedBox(width: 4),
                          Text(
                            '${userProfile.rating.toStringAsFixed(1)} (${userProfile.totalReviews})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.foreground,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(LucideIcons.check, size: 15, color: AppColors.green500),
                          const SizedBox(width: 4),
                          Text(
                            (userProfile.tasksCompleted + userProfile.tasksPosted) > 0
                                ? '${((userProfile.tasksCompleted / (userProfile.tasksCompleted + userProfile.tasksPosted)) * 100).toInt()}% hoàn thành'
                                : '0% hoàn thành',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.foreground,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 24),

                // Lưới thống kê
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isMobile ? 2 : 4,
                  childAspectRatio: isMobile ? 1.3 : 1.5,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildStatCard(
                      theme,
                      'Tổng thu nhập',
                      formatVND(userProfile.totalEarned),
                      userProfile.totalEarned > 0 ? 'tổng thu nhập' : 'chưa có thu nhập',
                      LucideIcons.dollarSign,
                      AppColors.green500,
                      changeColor: userProfile.totalEarned > 0 ? AppColors.green600 : Colors.grey,
                    ),
                    _buildStatCard(
                      theme,
                      'Tháng này',
                      formatVND(userProfile.thisMonthEarned),
                      userProfile.thisMonthEarned > 0 ? 'tháng này' : 'chưa có thu nhập',
                      LucideIcons.trendingUp,
                      AppColors.orange500,
                      changeColor: userProfile.thisMonthEarned > 0 ? AppColors.green600 : Colors.grey,
                    ),
                    _buildStatCard(
                      theme,
                      'Nhiệm vụ đã làm',
                      '${userProfile.tasksCompleted}',
                      userProfile.tasksCompleted > 0 ? 'nhiệm vụ hoàn thành' : 'chưa có nhiệm vụ',
                      LucideIcons.check,
                      AppColors.blue500,
                      changeColor: userProfile.tasksCompleted > 0 ? AppColors.green600 : Colors.grey,
                    ),
                    _buildStatCard(
                      theme,
                      'Nhiệm vụ đã đăng',
                      '${userProfile.tasksPosted}',
                      userProfile.tasksPosted > 0 ? 'nhiệm vụ đã đăng' : 'chưa có nhiệm vụ',
                      LucideIcons.send,
                      AppColors.purple500,
                      changeColor: userProfile.tasksPosted > 0 ? AppColors.green600 : Colors.grey,
                    ),
                  ],
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                const SizedBox(height: 32),

                // Tab nhiệm vụ của tôi
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.card,
                    border: Border.all(color: theme.colorScheme.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        tabs: const [
                          Tab(text: 'Nhiệm vụ tôi đăng'),
                          Tab(text: 'Nhiệm vụ tôi nhận'),
                        ],
                      ),
                      SizedBox(
                        height: 400,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildTasksList(_firestoreService.getMyPostedTasks(), theme),
                            _buildTasksList(_firestoreService.getMyAcceptedTasks(), theme),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
              ],
            ),
          );
        },
      ),
    );
  }

  // Hộp thoại chỉnh sửa pillar và năm học
  void _showEditPillarYearDialog(BuildContext context, UserProfile userProfile) {
    String selectedPillar = userProfile.pillar;
    int selectedYear = userProfile.year;
    
    final pillars = ['ASD', 'CSD', 'DAI', 'ESD', 'EPD', 'ISTD', 'Freshmore'];
    final years = [1, 2, 3, 4, 5];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Chỉnh sửa hồ sơ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pillar', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: selectedPillar,
                isExpanded: true,
                items: pillars.map((p) => DropdownMenuItem(
                  value: p,
                  child: Text(p),
                )).toList(),
                onChanged: (value) {
                  setDialogState(() => selectedPillar = value!);
                },
              ),
              const SizedBox(height: 16),
              const Text('Năm', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButton<int>(
                value: selectedYear,
                isExpanded: true,
                items: years.map((y) => DropdownMenuItem(
                  value: y,
                  child: Text('Năm $y'),
                )).toList(),
                onChanged: (value) {
                  setDialogState(() => selectedYear = value!);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _firestoreService.updateUserProfile({
                  'pillar': selectedPillar,
                  'year': selectedYear,
                });
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange500,
                foregroundColor: Colors.white,
              ),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    ShadThemeData theme,
    String label,
    String value,
    String change,
    IconData icon,
    Color iconColor, {
    Color changeColor = AppColors.green600,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        border: Border.all(color: theme.colorScheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
              Icon(icon, size: 16, color: iconColor),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.foreground,
            ),
          ),
          Text(
            change,
            style: TextStyle(
              fontSize: 12,
              color: changeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList(Stream<List<HeroTask>> tasksStream, ShadThemeData theme) {
    return StreamBuilder<List<HeroTask>>(
      stream: tasksStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasks = snapshot.data ?? [];
        
        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.inbox,
                  size: 48,
                  color: theme.colorScheme.mutedForeground,
                ),
                const SizedBox(height: 16),
                Text(
                  'Chưa có nhiệm vụ',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.colorScheme.mutedForeground,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return GestureDetector(
              onTap: widget.onTaskTap != null ? () => widget.onTaskTap!(task) : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.background,
                  border: Border.all(color: theme.colorScheme.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      task.category.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.foreground,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            task.status.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getStatusColor(task.status),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatVND(task.compensation),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.green600,
                      ),
                    ),
                    if (widget.onTaskTap != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(LucideIcons.chevronRight,
                            size: 16, color: theme.colorScheme.mutedForeground),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.open:
        return AppColors.blue500;
      case TaskStatus.accepted:
        return AppColors.orange500;
      case TaskStatus.inProgress:
        return AppColors.purple500;
      case TaskStatus.completed:
        return AppColors.green500;
      case TaskStatus.cancelled:
        return Colors.grey;
    }
  }
}
