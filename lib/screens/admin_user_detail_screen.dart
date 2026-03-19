import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../models/task_model.dart';
import '../theme/app_colors.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final UserProfile user;
  final VoidCallback? onBack;

  const AdminUserDetailScreen({super.key, required this.user, this.onBack});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  final FirestoreService _fs = FirestoreService();
  late TextEditingController _ratingController;
  late TextEditingController _notesController;
  late bool _isAdminValue;
  late bool _isBlockedValue;
  late bool _isVerifiedValue;
  bool _isLoading = false;
  List<HeroTask> _taskHistory = [];
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _ratingController = TextEditingController(text: widget.user.rating.toString());
    _notesController = TextEditingController(text: widget.user.adminNotes);
    _isAdminValue = widget.user.isAdmin;
    _isBlockedValue = widget.user.isBlocked;
    _isVerifiedValue = widget.user.isVerified;
    _loadTaskHistory();
  }

  Future<void> _loadTaskHistory() async {
    final history = await _fs.getUserTaskHistory(widget.user.uid);
    if (mounted) {
      setState(() {
        _taskHistory = history;
        _loadingHistory = false;
      });
    }
  }

  @override
  void dispose() {
    _ratingController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final newRating = double.tryParse(_ratingController.text) ?? widget.user.rating;
    
    setState(() => _isLoading = true);
    try {
      await _fs.adminUpdateUser(widget.user.uid, {
        'rating': newRating,
        'isAdmin': _isAdminValue,
        'isBlocked': _isBlockedValue,
        'isVerified': _isVerifiedValue,
        'adminNotes': _notesController.text,
      });
      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast(
            title: Text('Thành công'),
            description: Text('Thông tin người dùng đã được cập nhật.'),
          ),
        );
        if (widget.onBack != null) {
        widget.onBack!();
      } else {
        Navigator.pop(context);
      }
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ShadTheme.of(context).colorScheme.card,
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa người dùng "${widget.user.displayName}"? Hành động này không thể hoàn tác.'),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ShadButton.destructive(
            onPressed: () async {
              Navigator.pop(context); // Đóng xác nhận
              await _handleDelete();
            },
            child: const Text('Xác nhận xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete() async {
    setState(() => _isLoading = true);
    try {
      await _fs.adminDeleteUser(widget.user.uid);
      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast(
            title: Text('Đã xóa'),
            description: Text('Người dùng đã bị xóa khỏi hệ thống.'),
          ),
        );
        if (widget.onBack != null) {
          widget.onBack!();
        } else {
          Navigator.pop(context);
        }
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final u = widget.user;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: theme.colorScheme.foreground),
          onPressed: widget.onBack ?? () => Navigator.pop(context),
        ),
        title: Text('Chi tiết người dùng', style: theme.textTheme.h4),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header Info
            Center(
              child: Column(
                children: [
                  u.photoURL.isNotEmpty
                      ? CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(u.photoURL),
                        )
                      : CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.orangeLight,
                          child: Text(u.initials,
                              style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.orange600)),
                        ),
                  const SizedBox(height: 16),
                  Text(u.displayName, style: theme.textTheme.h3),
                  Text(u.email, style: theme.textTheme.muted),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      if (u.isAdmin) _badgeChip('ADMIN', AppColors.orangeLight, AppColors.orange600),
                      if (_isVerifiedValue) _badgeChip('XÁC MINH', Colors.blue[50]!, Colors.blue[700]!),
                      if (_isBlockedValue) _badgeChip('ĐÃ KHÓA', Colors.red[50]!, Colors.red[700]!),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _statCard(theme, 'Hoàn thành', u.tasksCompleted.toString(), LucideIcons.circleCheck)),
                    const SizedBox(width: 12),
                    Expanded(child: _statCard(theme, 'Đã đăng', u.tasksPosted.toString(), LucideIcons.clipboardList)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _statCard(theme, 'Tổng thu', formatVND(u.totalEarned), LucideIcons.banknote)),
                    const SizedBox(width: 12),
                    Expanded(child: _statCard(theme, 'Ngành học', u.pillar, LucideIcons.graduationCap)),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 24),
            
            // Management Form
            Text('Quản lý hồ sơ', style: theme.textTheme.large),
            const SizedBox(height: 20),
            
            // Rating Form
            Text('Đánh giá (Rating)', style: theme.textTheme.small),
            const SizedBox(height: 8),
            ShadInput(
              controller: _ratingController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              placeholder: const Text('0.0 - 5.0'),
            ),
            
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Xác minh', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: const Text('Cấp huy hiệu uy tín cho người dùng', style: TextStyle(fontSize: 12)),
              value: _isVerifiedValue,
              activeColor: AppColors.orange500,
              onChanged: (v) => setState(() => _isVerifiedValue = v),
              tileColor: theme.colorScheme.muted.withOpacity(0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Quyền Quản trị (Admin)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: const Text('Cho phép truy cập bảng Quản trị này', style: TextStyle(fontSize: 12)),
              value: _isAdminValue,
              activeColor: AppColors.orange500,
              onChanged: (v) => setState(() => _isAdminValue = v),
              tileColor: theme.colorScheme.muted.withOpacity(0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Khóa tài khoản (Block)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: const Text('Ngăn người dùng hoạt động trên ứng dụng', style: TextStyle(fontSize: 12)),
              value: _isBlockedValue,
              activeColor: Colors.red[600]!,
              onChanged: (v) => setState(() => _isBlockedValue = v),
              tileColor: theme.colorScheme.muted.withOpacity(0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            
            const SizedBox(height: 32),
            Text('Ghi chú của Admin', style: theme.textTheme.small),
            const SizedBox(height: 8),
            ShadInput(
              controller: _notesController,
              maxLines: 3,
              placeholder: const Text('Nhập ghi chú quan trọng về người dùng này...'),
            ),
            
            const SizedBox(height: 48),
            const Divider(),
            const SizedBox(height: 24),

            // Task History
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Lịch sử nhiệm vụ', style: theme.textTheme.large),
                Text('${_taskHistory.length} mục', style: theme.textTheme.muted),
              ],
            ),
            const SizedBox(height: 16),
            if (_loadingHistory)
              const Center(child: CircularProgressIndicator())
            else if (_taskHistory.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.muted.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Chưa có lịch sử nhiệm vụ nào.', textAlign: TextAlign.center),
              )
            else
              Column(
                children: _taskHistory.map((task) {
                  final isPoster = task.posterId == u.uid;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(task.category.emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(task.title, style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(isPoster ? 'Đã đăng' : 'Đã thực hiện', style: theme.textTheme.muted.copyWith(fontSize: 10)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(formatVND(task.compensation), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            Text(task.status.label, style: TextStyle(fontSize: 10, color: _getStatusColor(task.status))),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            
            const SizedBox(height: 60),
            
            // Actions
            SizedBox(
              width: double.infinity,
              child: ShadButton(
                size: ShadButtonSize.lg,
                onPressed: _isLoading ? null : _handleSave,
                child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Lưu thay đổi'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ShadButton.destructive(
                size: ShadButtonSize.lg,
                onPressed: _isLoading ? null : _confirmDelete,
                child: const Text('Xóa người dùng vĩnh viễn'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  );
}

  Widget _statCard(ShadThemeData theme, String label, String value, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.muted.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        leading: Icon(icon, size: 20, color: AppColors.orange500),
        title: Text(label, style: theme.textTheme.muted.copyWith(fontSize: 10)),
        subtitle: Text(value, 
            style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis),
        dense: true,
      ),
    );
  }

  Widget _badgeChip(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w800, color: text)),
    );
  }

  // Xóa _toggleTile vì đã dùng SwitchListTile trực tiếp

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.open: return Colors.blue;
      case TaskStatus.accepted: return Colors.indigo;
      case TaskStatus.inProgress: return Colors.orange;
      case TaskStatus.completed: return Colors.green;
      case TaskStatus.cancelled: return Colors.red;
    }
  }

  String formatVND(double amount) {
    return '${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ';
  }
}
