import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api/api_exception.dart';
import '../../services/api/auth_api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

/// Screen allowing users to enter the 6-digit OTP sent to their email.
class VerifyOtpScreen extends StatefulWidget {
  final String email;
  final String purpose; // 'email_verification' or 'password_reset'

  const VerifyOtpScreen({
    super.key,
    required this.email,
    this.purpose = 'email_verification',
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  String? _successMessage;

  int _resendCooldown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldownTimer();
  }

  void _startCooldownTimer() {
    _resendCooldown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _errorMessage = 'Please enter a 6-digit OTP code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final authApi = context.read<AuthApiService>();
      final result = await authApi.verifyOtp(
        email: widget.email,
        otp: otp,
        purpose: widget.purpose,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _successMessage = 'Verification successful!';
        });

        // If for password reset, return the resetToken to caller
        if (widget.purpose == 'password_reset') {
          final resetToken = result['resetToken'] as String?;
          Navigator.of(context).pop(resetToken);
        } else {
          // If for email verification, show success and pop
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email verified successfully!')),
          );
          Navigator.of(context).pop(true);
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An error occurred. Please check the code and try again.';
        });
      }
    }
  }

  Future<void> _handleResend() async {
    if (_resendCooldown > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      final authApi = context.read<AuthApiService>();
      await authApi.sendOtp(
        email: widget.email,
        purpose: widget.purpose,
      );

      if (mounted) {
        setState(() {
          _isResending = false;
          _successMessage = 'A new 6-digit verification code was sent to ${widget.email}';
        });
        _startCooldownTimer();
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isResending = false;
          _errorMessage = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isResending = false;
          _errorMessage = 'Failed to resend code. Please try again shortly.';
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
        title: const Text('Verify Code'),
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
                  Container(
                    height: 64,
                    width: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceWarm,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mark_email_read_outlined,
                      size: 32,
                      color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space24),
                  Text(
                    'Enter Verification Code',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space8),
                  Text(
                    'We sent a 6-digit code to\n${widget.email}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      height: 1.4,
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
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space16),
                  ],

                  if (_successMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppTheme.space12),
                      decoration: BoxDecoration(
                        color: AppTheme.successContainer,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(color: AppTheme.success, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space16),
                  ],

                  CustomTextField(
                    controller: _otpController,
                    label: '6-Digit Code',
                    hint: '123456',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.security_rounded,
                    maxLength: 6,
                  ),
                  const SizedBox(height: AppTheme.space24),

                  CustomButton(
                    text: 'Verify Code',
                    isLoading: _isLoading,
                    onPressed: _handleVerify,
                  ),
                  const SizedBox(height: AppTheme.space24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't receive the email? ",
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: _resendCooldown == 0 && !_isResending ? _handleResend : null,
                        child: Text(
                          _resendCooldown > 0 ? 'Resend in ${_resendCooldown}s' : 'Resend Code',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _resendCooldown > 0
                                ? (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)
                                : (isDark ? AppTheme.darkAccent : AppTheme.lightAccent),
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
    );
  }
}
