import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập họ và tên';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu';
    }
    if (value != _passwordController.text) {
      return 'Mật khẩu không khớp';
    }
    return null;
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userCredential = await _authService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );

      if (!mounted) return;

      if (userCredential != null) {
        ShadToaster.of(context).show(
          const ShadToast(
            title: Text('Đăng ký thành công!'),
            description: Text('Chào mừng bạn đến với TaskHero. Đang chuyển đến trang chủ...'),
          ),
        );
        // Người dùng tự động đăng nhập sau khi đăng ký
        // StreamBuilder trong main.dart sẽ phát hiện thay đổi trạng thái và chuyển đến AppShell
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String errorMessage = 'Lỗi đăng ký: ${e.code}';

      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'Email này đã được sử dụng. Vui lòng đăng nhập hoặc dùng email khác.';
          break;
        case 'weak-password':
          errorMessage = 'Mật khẩu quá yếu. Vui lòng chọn mật khẩu mạnh hơn.';
          break;
        case 'invalid-email':
          errorMessage = 'Email không hợp lệ.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Đăng ký bằng email/password chưa được bật. Liên hệ quản trị viên.';
          break;
        default:
          errorMessage = e.message ?? errorMessage;
      }

      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('Đăng ký thất bại'),
          description: Text(errorMessage),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('Đăng ký thất bại'),
          description: Text('Lỗi không mong đợi: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 24 : 48),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo ứng dụng
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: AppColors.orangeGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    LucideIcons.shield,
                    size: 40,
                    color: Colors.white,
                  ),
                ).animate().scale(duration: 500.ms).fadeIn(),
                
                const SizedBox(height: 32),
                
                Text(
                  'Tạo tài khoản',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.foreground,
                  ),
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                
                const SizedBox(height: 12),
                
                Text(
                  'Đăng ký để bắt đầu sử dụng TaskHero',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.colorScheme.mutedForeground,
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                
                const SizedBox(height: 48),
                
                // Form đăng ký
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.card,
                    border: Border.all(color: theme.colorScheme.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Trường họ và tên
                        Text(
                          'Họ và tên',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.foreground,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ShadInput(
                          controller: _nameController,
                          placeholder: const Text('Nguyễn Văn A'),
                        ),
                        if (_formKey.currentState != null && _validateName(_nameController.text) != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _validateName(_nameController.text) ?? '',
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Trường email
                        Text(
                          'Email',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.foreground,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ShadInput(
                          controller: _emailController,
                          placeholder: const Text('email@example.com'),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        if (_formKey.currentState != null && _validateEmail(_emailController.text) != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _validateEmail(_emailController.text) ?? '',
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Trường mật khẩu
                        Text(
                          'Mật khẩu',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.foreground,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ShadInput(
                          controller: _passwordController,
                          placeholder: const Text('Tối thiểu 6 ký tự'),
                          obscureText: _obscurePassword,
                          trailing: IconButton(
                            icon: Icon(
                              _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                              size: 16,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                        ),
                        if (_formKey.currentState != null && _validatePassword(_passwordController.text) != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _validatePassword(_passwordController.text) ?? '',
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Trường xác nhận mật khẩu
                        Text(
                          'Xác nhận mật khẩu',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.foreground,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ShadInput(
                          controller: _confirmPasswordController,
                          placeholder: const Text('Nhập lại mật khẩu'),
                          obscureText: _obscureConfirmPassword,
                          trailing: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                              size: 16,
                            ),
                            onPressed: () {
                              setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                            },
                          ),
                        ),
                        if (_formKey.currentState != null && _validateConfirmPassword(_confirmPasswordController.text) != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _validateConfirmPassword(_confirmPasswordController.text) ?? '',
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Nút đăng ký
                        SizedBox(
                          width: double.infinity,
                          child: ShadButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            size: ShadButtonSize.lg,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Đăng ký'),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Đã có tài khoản?\nĐăng nhập',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.05, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
