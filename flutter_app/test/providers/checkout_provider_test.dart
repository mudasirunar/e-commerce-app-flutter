import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecommerceapp/models/cart_item.dart';
import 'package:ecommerceapp/models/category.dart';
import 'package:ecommerceapp/models/delivery_info.dart';
import 'package:ecommerceapp/models/order.dart';
import 'package:ecommerceapp/models/product.dart';
import 'package:ecommerceapp/providers/cart_provider.dart';
import 'package:ecommerceapp/providers/catalog_provider.dart';
import 'package:ecommerceapp/providers/checkout_provider.dart';
import 'package:ecommerceapp/services/api/api_client.dart';
import 'package:ecommerceapp/services/api/api_exception.dart';
import 'package:ecommerceapp/services/api/order_api_service.dart';
import 'package:ecommerceapp/services/firestore/firestore_service.dart';
import 'package:ecommerceapp/services/local/local_storage_service.dart';

class MockOrderApiService extends OrderApiService {
  bool shouldFail = false;
  String? failMessage;
  int failCode = 400;
  String? lastAttemptId;

  MockOrderApiService() : super(ApiClient(baseUrl: 'https://example.com'));

  @override
  Future<OrderModel> checkout({
    required String attemptId,
    required List<Map<String, dynamic>> items,
    required DeliveryInfo deliveryInfo,
  }) async {
    lastAttemptId = attemptId;
    if (shouldFail) {
      throw ApiException(message: failMessage ?? 'Stock unavailable', statusCode: failCode);
    }

    return OrderModel(
      orderId: 'ord_test_123',
      userId: 'user_1',
      attemptId: attemptId,
      items: const [],
      subtotalMinor: 500000,
      deliveryFeeMinor: 0,
      totalMinor: 500000,
      deliveryName: deliveryInfo.fullName,
      deliveryPhone: deliveryInfo.phone,
      deliveryAddress: deliveryInfo.address,
      status: OrderStatus.pending,
    );
  }
}

class FakeCartFirestore extends FirestoreService {
  bool cartCleared = false;
  final StreamController<List<CartItem>> _controller = StreamController.broadcast();
  final StreamController<List<Product>> _prodController = StreamController.broadcast();
  final StreamController<List<Category>> _catController = StreamController.broadcast();
  final Map<String, int> _cart = {};

  @override
  Stream<List<CartItem>> watchCart(String uid) => _controller.stream;

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
    _cart[productId] = quantity;
    _emit();
  }

  @override
  Future<void> clearCart(String uid) async {
    cartCleared = true;
    _cart.clear();
    _emit();
  }

  void _emit() {
    _controller.add(
      _cart.entries.map((e) => CartItem(productId: e.key, quantity: e.value)).toList(),
    );
  }

  void dispose() {
    _controller.close();
    _prodController.close();
    _catController.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CheckoutProvider Workflow & Recovery', () {
    late LocalStorageService storage;
    late MockOrderApiService mockApi;
    late CheckoutProvider checkoutProvider;
    late FakeCartFirestore fakeFirestore;
    late CatalogProvider catalogProvider;
    late CartProvider cartProvider;

    final product = Product(
      productId: 'prod_1',
      name: 'Item 1',
      categoryId: 'cat_1',
      imageUrl: '',
      priceMinor: 500000,
      stockQuantity: 10,
    );

    const validDelivery = DeliveryInfo(
      fullName: 'Ahmad Khan',
      phone: '03001234567',
      address: 'House 12, Street 3, Islamabad',
      city: 'Islamabad',
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = await LocalStorageService.create();
      mockApi = MockOrderApiService();
      fakeFirestore = FakeCartFirestore();
      catalogProvider = CatalogProvider(fakeFirestore);
      cartProvider = CartProvider(fakeFirestore);
      checkoutProvider = CheckoutProvider(mockApi, storage);

      fakeFirestore.emitProducts([product]);
      checkoutProvider.updateDeliveryInfo(validDelivery);
    });

    tearDown(() {
      fakeFirestore.dispose();
      catalogProvider.dispose();
      cartProvider.dispose();
      checkoutProvider.dispose();
    });

    test('blocks checkout with empty cart', () async {
      final success = await checkoutProvider.submitCheckout(cartProvider);
      expect(success, isFalse);
      expect(checkoutProvider.errorMessage, 'Your cart is empty.');
    });

    test('retains attempt ID and cart items on recoverable API failure', () async {
      await pumpEventQueue();
      cartProvider.updateAuth('user_1', catalogProvider);
      await pumpEventQueue();

      await cartProvider.addToCart(product, quantity: 1);
      await pumpEventQueue();

      mockApi.shouldFail = true;
      mockApi.failMessage = 'Not enough stock for Item 1.';

      final success = await checkoutProvider.submitCheckout(cartProvider);
      expect(success, isFalse);
      expect(checkoutProvider.errorMessage, 'Not enough stock for Item 1.');

      // Cart MUST NOT be cleared on failure!
      expect(fakeFirestore.cartCleared, isFalse);
      expect(cartProvider.isEmpty, isFalse);

      // Attempt ID must be retained for idempotency on retry
      final savedAttemptId = storage.getLatestAttemptId();
      expect(savedAttemptId, isNotNull);
      expect(mockApi.lastAttemptId, savedAttemptId);
    });

    test('clears attempt ID and cart upon successful checkout confirmation', () async {
      await pumpEventQueue();
      cartProvider.updateAuth('user_1', catalogProvider);
      await pumpEventQueue();

      await cartProvider.addToCart(product, quantity: 1);
      await pumpEventQueue();

      mockApi.shouldFail = false;

      final success = await checkoutProvider.submitCheckout(cartProvider);
      expect(success, isTrue);
      expect(checkoutProvider.confirmedOrder, isNotNull);
      expect(checkoutProvider.confirmedOrder!.orderId, 'ord_test_123');

      // Attempt ID cleared and cart cleared
      expect(storage.getLatestAttemptId(), isNull);
      expect(fakeFirestore.cartCleared, isTrue);
      expect(cartProvider.isEmpty, isTrue);
    });
  });
}
