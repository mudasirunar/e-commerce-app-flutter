import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api/auth_api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import 'login_screen.dart';
import 'verify_otp_screen.dart';

/// Screen allowing new customers to register for an account.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    final success = await auth.signUpWithEmail(
      email: email,
      password: password,
      displayName: name,
    );

    if (success && mounted) {
      // Send email verification OTP in the background via Brevo
      try {
        final authApi = context.read<AuthApiService>();
        await authApi.sendOtp(email: email, purpose: 'email_verification');
        if (mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VerifyOtpScreen(email: email, purpose: 'email_verification'),
            ),
          );
        }
      } catch (_) {
        // If OTP delivery encounters an error, account is still created and user is signed in
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24, vertical: AppTheme.space32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Join Us',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      'Create an account to save your delivery addresses and track orders.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space32),

                    if (auth.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppTheme.space12),
                        decoration: BoxDecoration(
                          color: AppTheme.errorContainer,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 20, color: AppTheme.error),
                            const SizedBox(width: AppTheme.space8),
                            Expanded(
                              child: Text(
                                auth.errorMessage!,
                                style: const TextStyle(
                                  color: AppTheme.error,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.space16),
                    ],

                    CustomTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'Mudasir Unar',
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.space16),

                    CustomTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      hint: 'name@example.com',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.space16),

                    CustomTextField(
                      controller: _passwordController,
                      label: 'Password',
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.space16),

                    CustomTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      hint: '••••••••',
                      obscureText: _obscurePassword,
                      prefixIcon: Icons.lock_outline_rounded,
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.space24),

                    CustomButton(
                      text: 'Create Account',
                      isLoading: auth.isLoading,
                      onPressed: _handleSignup,
                    ),
                    const SizedBox(height: AppTheme.space24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                                settings: const RouteSettings(name: '/login'),
                              ),
                            );
                          },
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
