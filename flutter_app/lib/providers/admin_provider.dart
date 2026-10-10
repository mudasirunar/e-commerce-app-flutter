import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/api/admin_api_service.dart';
import '../services/api/api_exception.dart';
import '../services/firestore/firestore_service.dart';

/// Provider managing privileged administrator backend operations and order oversight.
class AdminProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final AdminApiService? _adminApiService;
  bool _isAdmin = false;

  List<OrderModel> _allOrders = [];
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<List<OrderModel>>? _ordersSub;

  AdminProvider(this._firestoreService, [this._adminApiService]);

  List<OrderModel> get allOrders => _allOrders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void updateAdminState(bool isAdmin) {
    if (_isAdmin == isAdmin) return;
    _isAdmin = isAdmin;
    _ordersSub?.cancel();
    _allOrders = [];

    if (isAdmin) {
      _subscribeToAllOrders();
    } else {
      notifyListeners();
    }
  }

  void _subscribeToAllOrders() {
    _isLoading = true;
    notifyListeners();

    _ordersSub = _firestoreService.watchAllOrdersAdmin().listen(
      (orderList) {
        _allOrders = orderList;
        _isLoading = false;
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = 'Failed to load admin orders.';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  OrderModel? getOrderById(String orderId) {
    for (final o in _allOrders) {
      if (o.orderId == orderId) return o;
    }
    return null;
  }

  /// Advances order status through the enforced backend state machine.
  Future<bool> updateOrderStatus(String orderId, String newStatus, {String? note}) async {
    if (_adminApiService == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _adminApiService.updateOrderStatus(
        orderId: orderId,
        newStatus: newStatus,
        note: note,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update order status.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Updates inventory stock count for a catalog item.
  Future<bool> updateStock(String productId, int newStock) async {
    if (_adminApiService == null) return false;
    try {
      await _adminApiService.updateProductStock(
        productId: productId,
        newStock: newStock,
      );
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  /// Toggles visibility for a product.
  Future<bool> toggleActive(String productId, bool isActive) async {
    if (_adminApiService == null) return false;
    try {
      await _adminApiService.toggleProductActive(
        productId: productId,
        isActive: isActive,
      );
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _ordersSub?.cancel();
    super.dispose();
  }
}
