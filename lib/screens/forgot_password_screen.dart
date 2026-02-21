import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  final _emailController = TextEditingController();
  
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
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

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.resetPassword(_emailController.text.trim());

      if (!mounted) return;

      setState(() {
        _emailSent = true;
        _isLoading = false;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String errorMessage = 'Lỗi: ${e.code}';

      switch (e.code) {
        case 'user-not-found':
          // For security, don't reveal if user exists
          setState(() {
            _emailSent = true;
            _isLoading = false;
          });
          return;
        case 'invalid-email':
          errorMessage = 'Email không hợp lệ.';
          break;
        default:
          errorMessage = e.message ?? errorMessage;
      }

      setState(() => _isLoading = false);

      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('Không thể gửi email'),
          description: Text(errorMessage),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('Không thể gửi email'),
          description: Text('Lỗi không mong đợi: $e'),
        ),
      );
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
                // Logo
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
                  _emailSent ? 'Email đã được gửi!' : 'Quên mật khẩu',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.foreground,
                  ),
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                
                const SizedBox(height: 12),
                
                Text(
                  _emailSent
                      ? 'Kiểm tra hộp thư của bạn'
                      : 'Nhập email để nhận liên kết đặt lại mật khẩu',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.colorScheme.mutedForeground,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                
                const SizedBox(height: 48),
                
                // Form or success message
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.card,
                    border: Border.all(color: theme.colorScheme.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _emailSent
                      ? Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.orangeLight,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                LucideIcons.check,
                                size: 32,
                                color: AppColors.orange600,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Chúng tôi đã gửi email đặt lại mật khẩu đến:',
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.colorScheme.mutedForeground,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _emailController.text,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.foreground,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ShadButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                size: ShadButtonSize.lg,
                                child: const Text('Quay lại đăng nhập'),
                              ),
                            ),
                          ],
                        )
                      : Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Email field
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

                              const SizedBox(height: 24),

                              // Send button
                              SizedBox(
                                width: double.infinity,
                                child: ShadButton(
                                  onPressed: _isLoading ? null : _handleResetPassword,
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
                                      : const Text('Gửi email đặt lại mật khẩu'),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Back to login link
                              Center(
                                child: ShadButton.ghost(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    'Quay lại đăng nhập',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
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
