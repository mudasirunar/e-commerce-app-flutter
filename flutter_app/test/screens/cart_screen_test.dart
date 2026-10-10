import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ecommerceapp/models/cart_item.dart';
import 'package:ecommerceapp/models/product.dart';
import 'package:ecommerceapp/providers/auth_provider.dart';
import 'package:ecommerceapp/providers/cart_provider.dart';
import 'package:ecommerceapp/screens/cart/cart_screen.dart';

class FakeAuthForCart extends ChangeNotifier implements AuthProvider {
  @override
  bool isAuthenticated = false;

  @override
  bool isLoading = false;

  @override
  String? errorMessage;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCartProvider extends ChangeNotifier implements CartProvider {
  @override
  List<CartItem> items = [];

  @override
  bool isLoading = false;

  @override
  String? errorMessage;

  @override
  bool get isEmpty => items.isEmpty;

  @override
  int get itemCount => items.length;

  @override
  int get totalUnits => items.fold(0, (sum, i) => sum + i.quantity);

  @override
  int get subtotalMinor => 4500000;

  @override
  int get deliveryFeeMinor => 0;

  @override
  int get totalMinor => 4500000;

  @override
  String get formattedSubtotal => 'PKR 45,000.00';

  @override
  String get formattedDeliveryFee => 'Free';

  @override
  String get formattedTotal => 'PKR 45,000.00';

  @override
  bool get hasStockErrors => false;

  @override
  bool get hasUnavailableItems => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CartScreen Widget', () {
    testWidgets('shows sign in prompt when user is not authenticated', (tester) async {
      final fakeAuth = FakeAuthForCart()..isAuthenticated = false;
      final fakeCart = FakeCartProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: fakeAuth),
            ChangeNotifierProvider<CartProvider>.value(value: fakeCart),
          ],
          child: const MaterialApp(
            home: CartScreen(),
          ),
        ),
      );

      expect(find.text('Sign In to View Bag'), findsOneWidget);
      expect(find.text('Sign In Now'), findsOneWidget);
    });

    testWidgets('shows empty bag state when authenticated and cart has no items', (tester) async {
      final fakeAuth = FakeAuthForCart()..isAuthenticated = true;
      final fakeCart = FakeCartProvider()..items = [];

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: fakeAuth),
            ChangeNotifierProvider<CartProvider>.value(value: fakeCart),
          ],
          child: const MaterialApp(
            home: CartScreen(),
          ),
        ),
      );

      expect(find.text('Your Bag is Empty'), findsOneWidget);
      expect(find.text('Explore Collection'), findsOneWidget);
    });

    testWidgets('renders items and checkout button when cart contains products', (tester) async {
      final fakeAuth = FakeAuthForCart()..isAuthenticated = true;
      const product = Product(
        productId: 'p_chair',
        name: 'Walnut Armchair',
        categoryId: 'cat_living',
        imageUrl: 'https://example.com/chair.jpg',
        priceMinor: 4500000,
        stockQuantity: 5,
      );

      final fakeCart = FakeCartProvider()
        ..items = [
          const CartItem(productId: 'p_chair', quantity: 1, product: product),
        ];

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: fakeAuth),
            ChangeNotifierProvider<CartProvider>.value(value: fakeCart),
          ],
          child: const MaterialApp(
            home: CartScreen(),
          ),
        ),
      );

      expect(find.text('Walnut Armchair'), findsOneWidget);
      expect(find.text('Proceed to Checkout'), findsOneWidget);
      expect(find.text('PKR 45,000.00'), findsWidgets);
    });
  });
}
