import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerceapp/models/product.dart';
import 'package:ecommerceapp/widgets/catalog/stock_badge.dart';

void main() {
  Product makeProduct({required int stock}) {
    return Product(
      productId: 'p-1',
      name: 'Sample Product',
      categoryId: 'cat-1',
      imageUrl: 'https://example.com/p1.jpg',
      priceMinor: 100000,
      stockQuantity: stock,
    );
  }

  group('StockBadge Widget', () {
    testWidgets('displays "Out of Stock" when stock is 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StockBadge(product: makeProduct(stock: 0)),
          ),
        ),
      );

      expect(find.text('Out of Stock'), findsOneWidget);
    });

    testWidgets('displays "Only X left" when stock is low (1 to 5)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StockBadge(product: makeProduct(stock: 3)),
          ),
        ),
      );

      expect(find.text('Only 3 left'), findsOneWidget);
    });

    testWidgets('displays "In Stock" when stock is healthy (> 5)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StockBadge(product: makeProduct(stock: 20)),
          ),
        ),
      );

      expect(find.text('In Stock'), findsOneWidget);
    });
  });
}
