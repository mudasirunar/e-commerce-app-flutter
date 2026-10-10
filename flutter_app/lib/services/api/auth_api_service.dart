import 'api_client.dart';

/// Service managing remote authentication OTP and password-reset API flows.
class AuthApiService {
  final ApiClient _apiClient;

  AuthApiService(this._apiClient);

  /// Requests a 6-digit OTP sent to the user's email.
  /// Purpose can be 'email_verification' or 'password_reset'.
  Future<Map<String, dynamic>> sendOtp({
    required String email,
    required String purpose,
  }) async {
    return await _apiClient.post(
      '/api/auth/send-otp',
      body: {
        'email': email.trim(),
        'purpose': purpose,
      },
      requiresAuth: false,
    );
  }

  /// Verifies the submitted 6-digit OTP.
  /// Returns response map containing resetToken if purpose is password_reset.
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
    required String purpose,
  }) async {
    return await _apiClient.post(
      '/api/auth/verify-otp',
      body: {
        'email': email.trim(),
        'otp': otp.trim(),
        'purpose': purpose,
      },
      requiresAuth: false,
    );
  }

  /// Consumes the single-use resetToken and updates the password via Firebase Admin.
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {
    return await _apiClient.post(
      '/api/auth/reset-password',
      body: {
        'email': email.trim(),
        'resetToken': resetToken.trim(),
        'newPassword': newPassword,
      },
      requiresAuth: false,
    );
  }
}
