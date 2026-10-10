/// Structured exception thrown for API request failures.
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, dynamic>? data;

  const ApiException({
    required this.message,
    required this.statusCode,
    this.data,
  });

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isBadRequest => statusCode == 400;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode >= 500;

  /// Retries remaining if this was an OTP validation failure.
  int? get attemptsLeft => (data?['attemptsLeft'] as num?)?.toInt();

  /// Cooldown seconds remaining if rate limited.
  int? get retryAfterSeconds => (data?['retryAfterSeconds'] as num?)?.toInt();

  @override
  String toString() => 'ApiException($statusCode): $message';
}
