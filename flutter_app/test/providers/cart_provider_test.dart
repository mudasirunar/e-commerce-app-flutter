import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerceapp/models/cart_item.dart';
import 'package:ecommerceapp/models/category.dart';
import 'package:ecommerceapp/models/product.dart';
import 'package:ecommerceapp/providers/cart_provider.dart';
import 'package:ecommerceapp/providers/catalog_provider.dart';
import 'package:ecommerceapp/services/firestore/firestore_service.dart';

class MockCartFirestoreService extends FirestoreService {
  final StreamController<List<CartItem>> _cartController = StreamController.broadcast();
  final StreamController<List<Product>> _prodController = StreamController.broadcast();
  final StreamController<List<Category>> _catController = StreamController.broadcast();
  final Map<String, int> storedCart = {};

  @override
  Stream<List<CartItem>> watchCart(String uid) => _cartController.stream;

  @override
  Stream<List<Product>> watchProducts({String? categoryId}) => _prodController.stream;

  @override
  Stream<List<Category>> watchCategories() => _catController.stream;

  void emitProducts(List<Product> list) => _prodController.add(list);

  @override
  Future<void> setCartItem({
    required String uid,
    required String productId,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      storedCart.remove(productId);
    } else {
      storedCart[productId] = quantity;
    }
    _emitCurrentCart();
  }

  @override
  Future<void> removeCartItem({
    required String uid,
    required String productId,
  }) async {
    storedCart.remove(productId);
    _emitCurrentCart();
  }

  void _emitCurrentCart() {
    final list = storedCart.entries
        .map((e) => CartItem(productId: e.key, quantity: e.value))
        .toList();
    _cartController.add(list);
  }

  void dispose() {
    _cartController.close();
    _prodController.close();
    _catController.close();
  }
}

void main() {
  group('CartProvider Logic & Calculations', () {
    late MockCartFirestoreService fakeService;
    late CatalogProvider catalogProvider;
    late CartProvider cartProvider;

    final productA = Product(
      productId: 'p_a',
      name: 'Product A',
      categoryId: 'c1',
      imageUrl: '',
      priceMinor: 200000, // PKR 2,000
      stockQuantity: 5,
    );

    final productB = Product(
      productId: 'p_b',
      name: 'Product B',
      categoryId: 'c1',
      imageUrl: '',
      priceMinor: 350000, // PKR 3,500
      stockQuantity: 10,
    );

    setUp(() {
      fakeService = MockCartFirestoreService();
      catalogProvider = CatalogProvider(fakeService);
      cartProvider = CartProvider(fakeService);

      fakeService.emitProducts([productA, productB]);
    });

    tearDown(() {
      cartProvider.dispose();
      catalogProvider.dispose();
      fakeService.dispose();
    });

    test('calculates subtotal and flat delivery fee when below threshold', () async {
      await pumpEventQueue();
      cartProvider.updateAuth('user_1', catalogProvider);
      await pumpEventQueue();

      // Add 1 unit of product A (PKR 2,000)
      await cartProvider.addToCart(productA, quantity: 1);
      await pumpEventQueue();

      // Subtotal = 2,000 PKR (200,000 paisa)
      // Since < 5,000 PKR threshold, delivery fee is 250 PKR (25,000 paisa)
      // Grand total = 2,250 PKR (225,000 paisa)
      expect(cartProvider.subtotalMinor, 200000);
      expect(cartProvider.deliveryFeeMinor, 25000);
      expect(cartProvider.totalMinor, 225000);
      expect(cartProvider.formattedDeliveryFee, 'PKR 250.00');
    });

    test('grants free delivery when subtotal meets or exceeds threshold', () async {
      await pumpEventQueue();
      cartProvider.updateAuth('user_1', catalogProvider);
      await pumpEventQueue();

      // Add 1 unit of product A (2,000 PKR) + 1 unit of product B (3,500 PKR) = 5,500 PKR
      await cartProvider.addToCart(productA, quantity: 1);
      await cartProvider.addToCart(productB, quantity: 1);
      await pumpEventQueue();

      expect(cartProvider.subtotalMinor, 550000);
      expect(cartProvider.deliveryFeeMinor, 0); // Free delivery
      expect(cartProvider.formattedDeliveryFee, 'Free');
      expect(cartProvider.totalMinor, 550000);
    });

    test('enforces stock limits when adding items', () async {
      await pumpEventQueue();
      cartProvider.updateAuth('user_1', catalogProvider);
      await pumpEventQueue();

      // Product A only has 5 units in stock. Trying to add 6 should fail.
      final success = await cartProvider.addToCart(productA, quantity: 6);
      expect(success, isFalse);
      expect(cartProvider.errorMessage, contains('Only 5 units available'));
    });
  });
}
