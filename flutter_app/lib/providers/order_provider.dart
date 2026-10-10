import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/api/api_exception.dart';
import '../services/api/order_api_service.dart';
import '../services/firestore/firestore_service.dart';

/// Provider managing customer order history, detail views, and realtime status updates.
class OrderProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final OrderApiService? _orderApiService;
  String? _userId;

  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<List<OrderModel>>? _ordersSub;

  OrderProvider(this._firestoreService, [this._orderApiService]);

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _orders.isEmpty;

  void updateAuth(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _ordersSub?.cancel();
    _orders = [];

    if (userId != null && userId.isNotEmpty) {
      _subscribeToOrders(userId);
    } else {
      notifyListeners();
    }
  }

  void _subscribeToOrders(String uid) {
    _isLoading = true;
    notifyListeners();

    _ordersSub = _firestoreService.watchCustomerOrders(uid).listen(
      (orderList) {
        _orders = orderList;
        _isLoading = false;
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = 'Failed to load order history.';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  OrderModel? getOrderById(String orderId) {
    for (final o in _orders) {
      if (o.orderId == orderId) return o;
    }
    return null;
  }

  /// Cancels an eligible Pending order via backend API and restores inventory.
  Future<bool> cancelOrder(String orderId, {String? reason}) async {
    if (_orderApiService == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _orderApiService.cancelOrder(orderId: orderId, reason: reason);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to cancel order.';
      _isLoading = false;
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
