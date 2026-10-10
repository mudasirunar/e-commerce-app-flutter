import 'api_client.dart';

/// Service managing privileged administrator backend operations.
class AdminApiService {
  final ApiClient _apiClient;

  AdminApiService(this._apiClient);

  /// Transitions order to a new lifecycle status following state machine rules.
  Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String newStatus,
    String? note,
  }) async {
    return await _apiClient.post(
      '/api/admin/orders/update-status',
      body: {
        'orderId': orderId,
        'newStatus': newStatus,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
      requiresAuth: true,
    );
  }

  /// Updates inventory stock count for a catalog product.
  Future<Map<String, dynamic>> updateProductStock({
    required String productId,
    required int newStock,
  }) async {
    return await _apiClient.post(
      '/api/admin/products/manage',
      body: {
        'action': 'update-stock',
        'productId': productId,
        'stockQuantity': newStock,
      },
      requiresAuth: true,
    );
  }

  /// Toggles active/inactive visibility for a catalog product.
  Future<Map<String, dynamic>> toggleProductActive({
    required String productId,
    required bool isActive,
  }) async {
    return await _apiClient.post(
      '/api/admin/products/manage',
      body: {
        'action': 'toggle-active',
        'productId': productId,
        'isActive': isActive,
      },
      requiresAuth: true,
    );
  }

  /// Creates a new product in the catalog.
  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    return await _apiClient.post(
      '/api/admin/products/manage',
      body: {
        'action': 'create',
        ...data,
      },
      requiresAuth: true,
    );
  }

  /// Updates details for an existing catalog product.
  Future<Map<String, dynamic>> updateProduct(String productId, Map<String, dynamic> data) async {
    return await _apiClient.post(
      '/api/admin/products/manage',
      body: {
        'action': 'update',
        'productId': productId,
        ...data,
      },
      requiresAuth: true,
    );
  }
}
