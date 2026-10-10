import 'package:flutter/foundation.dart';
import '../models/delivery_info.dart';
import '../models/order.dart';
import '../services/api/api_exception.dart';
import '../services/api/order_api_service.dart';
import '../services/local/local_storage_service.dart';
import 'cart_provider.dart';

/// Provider managing the checkout workflow, delivery destination, idempotency tokens, and recovery.
class CheckoutProvider extends ChangeNotifier {
  final OrderApiService _orderApiService;
  final LocalStorageService _localStorageService;

  DeliveryInfo _deliveryInfo = const DeliveryInfo(
    fullName: '',
    phone: '',
    address: '',
    city: 'Karachi',
  );

  bool _isSubmitting = false;
  String? _errorMessage;
  OrderModel? _confirmedOrder;
  String? _activeAttemptId;

  CheckoutProvider(this._orderApiService, this._localStorageService);

  DeliveryInfo get deliveryInfo => _deliveryInfo;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  OrderModel? get confirmedOrder => _confirmedOrder;
  String? get activeAttemptId => _activeAttemptId;

  void updateDeliveryInfo(DeliveryInfo info) {
    _deliveryInfo = info;
    notifyListeners();
  }

  /// Submits the order atomically to the remote backend.
  /// Reuses or generates a stable attemptId to guarantee idempotency.
  Future<bool> submitCheckout(CartProvider cartProvider) async {
    if (cartProvider.isEmpty) {
      _errorMessage = 'Your cart is empty.';
      notifyListeners();
      return false;
    }

    if (!_deliveryInfo.isValid) {
      _errorMessage = 'Please provide a valid recipient name, address, and phone number.';
      notifyListeners();
      return false;
    }

    if (cartProvider.hasStockErrors || cartProvider.hasUnavailableItems) {
      _errorMessage = 'Some items in your cart exceed stock or are unavailable.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    // Recover or generate attempt ID for idempotency protection
    _activeAttemptId = _localStorageService.getLatestAttemptId();
    if (_activeAttemptId == null || _activeAttemptId!.isEmpty) {
      _activeAttemptId = 'att_${DateTime.now().millisecondsSinceEpoch}_${cartProvider.itemCount}';
      await _localStorageService.setLatestAttemptId(_activeAttemptId!);
    }

    final itemsPayload = cartProvider.items.map((item) {
      return {
        'productId': item.productId,
        'quantity': item.quantity,
      };
    }).toList();

    try {
      final order = await _orderApiService.checkout(
        attemptId: _activeAttemptId!,
        items: itemsPayload,
        deliveryInfo: _deliveryInfo,
      );

      _confirmedOrder = order;

      // Successful order: clear attempt ID and customer cart
      await _localStorageService.clearLatestAttemptId();
      _activeAttemptId = null;
      await cartProvider.clearCart();

      _isSubmitting = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isSubmitting = false;
      // Retain activeAttemptId and cart items for safe retry!
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Checkout failed. Please check your connection and try again.';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  void resetCheckoutState() {
    _confirmedOrder = null;
    _errorMessage = null;
    _isSubmitting = false;
    notifyListeners();
  }
}
