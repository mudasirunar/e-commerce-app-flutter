import '../../models/delivery_info.dart';
import '../../models/order.dart';
import 'api_client.dart';

/// Service managing remote order checkout and customer cancellation API flows.
class OrderApiService {
  final ApiClient _apiClient;

  OrderApiService(this._apiClient);

  /// Submits checkout attempt to the backend transaction handler.
  /// Deducts stock atomically, verifies prices authoritatively, and records order.
  Future<OrderModel> checkout({
    required String attemptId,
    required List<Map<String, dynamic>> items,
    required DeliveryInfo deliveryInfo,
  }) async {
    final payload = {
      'attemptId': attemptId,
      'items': items,
      ...deliveryInfo.toCheckoutPayload(),
    };

    final response = await _apiClient.post(
      '/api/orders/checkout',
      body: payload,
      requiresAuth: true,
    );

    final orderData = response['order'] as Map<String, dynamic>?;
    final orderId = response['orderId'] as String? ?? orderData?['orderId'] ?? '';

    if (orderData != null) {
      return OrderModel.fromMap(orderData, orderId);
    }

    throw const FormatException('Server did not return a valid order object.');
  }

  /// Requests customer cancellation for a Pending order.
  /// Restores reserved stock atomically on the backend.
  Future<Map<String, dynamic>> cancelOrder({
    required String orderId,
    String? reason,
  }) async {
    return await _apiClient.post(
      '/api/orders/cancel',
      body: {
        'orderId': orderId,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
      requiresAuth: true,
    );
  }
}
