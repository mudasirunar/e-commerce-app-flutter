import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api/api_exception.dart';
import '../../services/api/auth_api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import 'verify_otp_screen.dart';

/// Screen managing password reset via email OTP and single-use resetToken.
class ForgotPasswordScreen extends StatefulWidget {
  final String? initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _resetToken;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authApi = context.read<AuthApiService>();
      await authApi.sendOtp(
        email: email,
        purpose: 'password_reset',
      );

      if (mounted) {
        setState(() => _isLoading = false);

        // Navigate to VerifyOtpScreen to collect resetToken
        final token = await Navigator.of(context).push<String?>(
          MaterialPageRoute(
            builder: (_) => VerifyOtpScreen(
              email: email,
              purpose: 'password_reset',
            ),
          ),
        );

        if (token != null && mounted) {
          setState(() {
            _resetToken = token;
            _errorMessage = null;
          });
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to send reset code. Please try again.';
        });
      }
    }
  }

  Future<void> _handleResetPassword() async {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authApi = context.read<AuthApiService>();
      await authApi.resetPassword(
        email: _emailController.text.trim(),
        resetToken: _resetToken!,
        newPassword: password,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successfully. Please sign in with your new password.'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to reset password. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24, vertical: AppTheme.space32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _resetToken == null ? 'Forgot Password?' : 'Enter New Password',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space8),
                  Text(
                    _resetToken == null
                        ? 'Enter your registered email address and we will send a 6-digit verification code.'
                        : 'Choose a strong password with at least 6 characters.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space32),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppTheme.space12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorContainer,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppTheme.error, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: AppTheme.space16),
                  ],

                  if (_resetToken == null) ...[
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      hint: 'name@example.com',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                    ),
                    const SizedBox(height: AppTheme.space24),
                    CustomButton(
                      text: 'Send Reset Code',
                      isLoading: _isLoading,
                      onPressed: _handleSendOtp,
                    ),
                  ] else ...[
                    CustomTextField(
                      controller: _passwordController,
                      label: 'New Password',
                      hint: '••••••••',
                      obscureText: _obscurePassword,
                      prefixIcon: Icons.lock_outline_rounded,
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: AppTheme.space16),
                    CustomTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm New Password',
                      hint: '••••••••',
                      obscureText: _obscurePassword,
                      prefixIcon: Icons.lock_outline_rounded,
                    ),
                    const SizedBox(height: AppTheme.space24),
                    CustomButton(
                      text: 'Set New Password',
                      isLoading: _isLoading,
                      onPressed: _handleResetPassword,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
