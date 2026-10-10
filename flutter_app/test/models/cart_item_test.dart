import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerceapp/models/cart_item.dart';
import 'package:ecommerceapp/models/product.dart';

void main() {
  group('CartItem Model', () {
    final testProduct = Product(
      productId: 'prod_01',
      name: 'Sample Mug',
      categoryId: 'cat_home',
      imageUrl: '',
      priceMinor: 150000, // PKR 1,500.00
      stockQuantity: 5,
    );

    test('calculates subtotal based on joined product price and quantity', () {
      final cartItem = CartItem(
        productId: 'prod_01',
        quantity: 3,
        product: testProduct,
      );

      expect(cartItem.subtotalMinor, 450000); // 150000 * 3 = 450000
      expect(cartItem.formattedSubtotal, 'PKR 4,500.00');
    });

    test('flags stock overflow correctly', () {
      final validItem = CartItem(
        productId: 'prod_01',
        quantity: 4,
        product: testProduct,
      );
      expect(validItem.exceedsStock, isFalse);

      final excessItem = CartItem(
        productId: 'prod_01',
        quantity: 6,
        product: testProduct,
      );
      expect(excessItem.exceedsStock, isTrue);
    });

    test('flags unavailable products correctly', () {
      final inStockItem = CartItem(
        productId: 'prod_01',
        quantity: 1,
        product: testProduct,
      );
      expect(inStockItem.isUnavailable, isFalse);

      final outOfStockProduct = testProduct.copyWith(stockQuantity: 0);
      final unavailableItem = CartItem(
        productId: 'prod_01',
        quantity: 1,
        product: outOfStockProduct,
      );
      expect(unavailableItem.isUnavailable, isTrue);

      final inactiveProduct = testProduct.copyWith(isActive: false);
      final inactiveItem = CartItem(
        productId: 'prod_01',
        quantity: 1,
        product: inactiveProduct,
      );
      expect(inactiveItem.isUnavailable, isTrue);
    });

    test('serializes to Firestore map without client price fields', () {
      final item = CartItem(
        productId: 'prod_01',
        quantity: 2,
        product: testProduct,
      );

      final map = item.toMap();
      expect(map['productId'], 'prod_01');
      expect(map['quantity'], 2);
      expect(map.containsKey('priceMinor'), isFalse);
      expect(map.containsKey('subtotalMinor'), isFalse);
    });
  });
}
