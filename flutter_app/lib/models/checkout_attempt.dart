import '../utils/date_formatter.dart';

/// Represents an idempotency record for checkout operations, stored in
/// `users/{uid}/checkoutAttempts/{attemptId}`.
///
/// Ensures double-taps or network retry replays do not duplicate orders or stock debits.
class CheckoutAttempt {
  final String attemptId;
  final String? orderId;
  final String? requestFingerprint;
  final DateTime? createdAt;
  final String status;

  const CheckoutAttempt({
    required this.attemptId,
    this.orderId,
    this.requestFingerprint,
    this.createdAt,
    this.status = 'completed',
  });

  bool get isCompleted => orderId != null && orderId!.isNotEmpty;

  factory CheckoutAttempt.fromMap(Map<String, dynamic> data, String attemptId) {
    return CheckoutAttempt(
      attemptId: attemptId,
      orderId: (data['orderId'] as String?)?.trim(),
      requestFingerprint: (data['requestFingerprint'] as String?)?.trim(),
      createdAt: DateFormatter.parse(data['createdAt']),
      status: (data['status'] as String?)?.trim() ?? 'completed',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'attemptId': attemptId,
      if (orderId != null) 'orderId': orderId,
      if (requestFingerprint != null) 'requestFingerprint': requestFingerprint,
      if (createdAt != null) 'createdAt': DateFormatter.toSerializable(createdAt),
      'status': status,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckoutAttempt &&
          runtimeType == other.runtimeType &&
          attemptId == other.attemptId;

  @override
  int get hashCode => attemptId.hashCode;
}
