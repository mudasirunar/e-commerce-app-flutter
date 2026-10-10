import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/firestore/firestore_service.dart';

/// Provider managing privileged admin operations (all-orders view, status overview).
class AdminProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  bool _isAdmin = false;

  List<OrderModel> _allOrders = [];
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<List<OrderModel>>? _ordersSub;

  AdminProvider(this._firestoreService);

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
    try {
      return _allOrders.firstWhere((o) => o.orderId == orderId);
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
