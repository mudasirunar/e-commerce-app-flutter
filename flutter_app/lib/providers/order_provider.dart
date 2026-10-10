import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/firestore/firestore_service.dart';

/// Provider managing customer order history, detail views, and realtime status updates.
class OrderProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  String? _userId;

  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<List<OrderModel>>? _ordersSub;

  OrderProvider(this._firestoreService);

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
    try {
      return _orders.firstWhere((o) => o.orderId == orderId);
    } catch (_) {
      return null;
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
