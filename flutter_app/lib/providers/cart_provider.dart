import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../services/firestore/firestore_service.dart';
import '../utils/app_config.dart';
import '../utils/money_formatter.dart';
import 'catalog_provider.dart';

/// Provider managing the customer's persistent cart, stock limits, and authoritative totals.
class CartProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  String? _userId;
  CatalogProvider? _catalogProvider;

  Map<String, CartItem> _items = {};
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<List<CartItem>>? _cartSub;

  CartProvider(this._firestoreService);

  List<CartItem> get items => _items.values.toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _items.isEmpty;

  /// Number of distinct product lines in the cart.
  int get itemCount => _items.length;

  /// Total physical units in the cart.
  int get totalUnits => _items.values.fold(0, (sum, item) => sum + item.quantity);

  /// Subtotal in integer paisa.
  int get subtotalMinor {
    return _items.values.fold(0, (sum, item) => sum + item.subtotalMinor);
  }

  /// Calculated delivery fee in integer paisa.
  /// Free if subtotal exceeds AppConfig.freeDeliveryThresholdMinor.
  int get deliveryFeeMinor {
    if (isEmpty) return 0;
    if (subtotalMinor >= AppConfig.freeDeliveryThresholdMinor) {
      return 0;
    }
    return AppConfig.defaultDeliveryFeeMinor;
  }

  /// Grand total in integer paisa.
  int get totalMinor => subtotalMinor + deliveryFeeMinor;

  /// Formatted money strings
  String get formattedSubtotal => MoneyFormatter.format(subtotalMinor);
  String get formattedDeliveryFee =>
      deliveryFeeMinor == 0 ? 'Free' : MoneyFormatter.format(deliveryFeeMinor);
  String get formattedTotal => MoneyFormatter.format(totalMinor);

  /// Checks if any item in the cart exceeds available inventory.
  bool get hasStockErrors => _items.values.any((i) => i.exceedsStock);

  /// Checks if any item in the cart is completely inactive or out of stock.
  bool get hasUnavailableItems => _items.values.any((i) => i.isUnavailable);

  /// Updates authenticated user and re-subscribes to cart.
  void updateAuth(String? userId, CatalogProvider? catalogProvider) {
    final userChanged = _userId != userId;
    _userId = userId;
    _catalogProvider = catalogProvider;

    if (userChanged) {
      _cartSub?.cancel();
      _items = {};

      if (userId != null && userId.isNotEmpty) {
        _subscribeToCart(userId);
      } else {
        notifyListeners();
      }
    } else {
      // Re-hydrate products if catalog updated
      _rehydrateProducts();
    }
  }

  void _subscribeToCart(String uid) {
    _isLoading = true;
    notifyListeners();

    _cartSub = _firestoreService.watchCart(uid).listen(
      (cartList) {
        final newMap = <String, CartItem>{};
        for (final item in cartList) {
          final product = _catalogProvider?.findProductById(item.productId);
          newMap[item.productId] = item.copyWith(product: product);
        }
        _items = newMap;
        _isLoading = false;
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = 'Failed to sync cart.';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void _rehydrateProducts() {
    if (_catalogProvider == null || _items.isEmpty) return;
    bool changed = false;
    final updated = <String, CartItem>{};

    for (final entry in _items.entries) {
      final product = _catalogProvider!.findProductById(entry.key);
      if (entry.value.product != product) {
        changed = true;
        updated[entry.key] = entry.value.copyWith(product: product);
      } else {
        updated[entry.key] = entry.value;
      }
    }

    if (changed) {
      _items = updated;
      notifyListeners();
    }
  }

  // ==================== CART ACTIONS ====================

  /// Adds a product to the cart or increments its quantity.
  Future<bool> addToCart(Product product, {int quantity = 1}) async {
    if (_userId == null) {
      _errorMessage = 'Please sign in to add items to cart.';
      notifyListeners();
      return false;
    }

    final existing = _items[product.productId];
    final currentQty = existing?.quantity ?? 0;
    final targetQty = currentQty + quantity;

    if (targetQty > AppConfig.maxCartItemQuantity) {
      _errorMessage = 'Maximum ${AppConfig.maxCartItemQuantity} units allowed per product.';
      notifyListeners();
      return false;
    }

    if (targetQty > product.stockQuantity) {
      _errorMessage = 'Only ${product.stockQuantity} units available in stock.';
      notifyListeners();
      return false;
    }

    try {
      await _firestoreService.setCartItem(
        uid: _userId!,
        productId: product.productId,
        quantity: targetQty,
      );
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update cart.';
      notifyListeners();
      return false;
    }
  }

  /// Sets absolute quantity for an item in the cart.
  Future<bool> updateQuantity(String productId, int newQuantity) async {
    if (_userId == null) return false;

    if (newQuantity <= 0) {
      return removeFromCart(productId);
    }

    if (newQuantity > AppConfig.maxCartItemQuantity) {
      _errorMessage = 'Maximum ${AppConfig.maxCartItemQuantity} units allowed per product.';
      notifyListeners();
      return false;
    }

    final product = _items[productId]?.product;
    if (product != null && newQuantity > product.stockQuantity) {
      _errorMessage = 'Only ${product.stockQuantity} units available in stock.';
      notifyListeners();
      return false;
    }

    try {
      await _firestoreService.setCartItem(
        uid: _userId!,
        productId: productId,
        quantity: newQuantity,
      );
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update quantity.';
      notifyListeners();
      return false;
    }
  }

  /// Removes an item completely from the cart.
  Future<bool> removeFromCart(String productId) async {
    if (_userId == null) return false;
    try {
      await _firestoreService.removeCartItem(
        uid: _userId!,
        productId: productId,
      );
      return true;
    } catch (e) {
      _errorMessage = 'Failed to remove item.';
      notifyListeners();
      return false;
    }
  }

  /// Clears all items in the cart.
  Future<void> clearCart() async {
    if (_userId == null) return;
    try {
      await _firestoreService.clearCart(_userId!);
      _items = {};
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to clear cart.';
      notifyListeners();
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
    _cartSub?.cancel();
    super.dispose();
  }
}
