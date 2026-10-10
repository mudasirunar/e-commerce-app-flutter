import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerceapp/models/product.dart';

void main() {
  group('Product Model', () {
    test('parses from Firestore map correctly', () {
      final map = {
        'name': 'Wireless Noise-Cancelling Headphones',
        'normalizedName': 'wireless noise-cancelling headphones',
        'description': 'Over-ear headphones with 30-hour battery life.',
        'categoryId': 'cat_electronics',
        'imageUrl': 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e',
        'priceMinor': 2499900,
        'stockQuantity': 15,
        'isActive': true,
        'isFeatured': true,
      };

      final product = Product.fromMap(map, 'prod_elec_01');

      expect(product.productId, 'prod_elec_01');
      expect(product.name, 'Wireless Noise-Cancelling Headphones');
      expect(product.categoryId, 'cat_electronics');
      expect(product.priceMinor, 2499900);
      expect(product.pricePkr, 24999.0);
      expect(product.formattedPrice, 'PKR 24,999.00');
      expect(product.stockQuantity, 15);
      expect(product.isInStock, isTrue);
      expect(product.isOutOfStock, isFalse);
      expect(product.isLowStock, isFalse);
      expect(product.isActive, isTrue);
      expect(product.isFeatured, isTrue);
    });

    test('correctly identifies low stock and out of stock states', () {
      final lowStockProduct = Product(
        productId: 'prod_low',
        name: 'Low Stock Item',
        categoryId: 'cat_test',
        imageUrl: '',
        priceMinor: 50000,
        stockQuantity: 3,
      );
      expect(lowStockProduct.isInStock, isTrue);
      expect(lowStockProduct.isLowStock, isTrue);
      expect(lowStockProduct.isOutOfStock, isFalse);

      final outOfStockProduct = Product(
        productId: 'prod_out',
        name: 'Out of Stock Item',
        categoryId: 'cat_test',
        imageUrl: '',
        priceMinor: 50000,
        stockQuantity: 0,
      );
      expect(outOfStockProduct.isInStock, isFalse);
      expect(outOfStockProduct.isLowStock, isFalse);
      expect(outOfStockProduct.isOutOfStock, isTrue);
    });

    test('serializes to map round-trip', () {
      final original = Product(
        productId: 'prod_01',
        name: 'Test Product',
        normalizedName: 'test product',
        description: 'Test Description',
        categoryId: 'cat_01',
        imageUrl: 'https://example.com/image.jpg',
        priceMinor: 100000,
        stockQuantity: 10,
        isActive: true,
        isFeatured: false,
      );

      final map = original.toMap();
      final reconstructed = Product.fromMap(map, 'prod_01');

      expect(reconstructed.name, original.name);
      expect(reconstructed.priceMinor, original.priceMinor);
      expect(reconstructed.stockQuantity, original.stockQuantity);
      expect(reconstructed.isActive, original.isActive);
    });
  });
}
