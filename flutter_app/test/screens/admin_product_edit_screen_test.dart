import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ecommerceapp/models/category.dart';
import 'package:ecommerceapp/models/product.dart';
import 'package:ecommerceapp/providers/admin_provider.dart';
import 'package:ecommerceapp/providers/catalog_provider.dart';
import 'package:ecommerceapp/screens/admin/admin_product_edit_screen.dart';

class FakeAdminProvider extends ChangeNotifier implements AdminProvider {
  String? lastUpdatedProductId;
  int? lastUpdatedStock;
  bool? lastToggledActive;

  @override
  Future<bool> updateStock(String productId, int newStock) async {
    lastUpdatedProductId = productId;
    lastUpdatedStock = newStock;
    return true;
  }

  @override
  Future<bool> toggleActive(String productId, bool isActive) async {
    lastUpdatedProductId = productId;
    lastToggledActive = isActive;
    return true;
  }

  @override
  String? get errorMessage => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCatalogProvider extends ChangeNotifier implements CatalogProvider {
  bool didRefresh = false;

  @override
  List<Category> get categories => const [
        Category(categoryId: 'cat_living', name: 'Living Room'),
      ];

  @override
  Future<void> refresh() async {
    didRefresh = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const sampleProduct = Product(
    productId: 'p_chair_01',
    name: 'Walnut Armchair',
    categoryId: 'cat_living',
    imageUrl: '',
    priceMinor: 4500000,
    stockQuantity: 4, // Initial: Low stock
    isActive: true,
  );

  Widget buildTestWidget({
    required FakeAdminProvider adminProvider,
    required FakeCatalogProvider catalogProvider,
    Product product = sampleProduct,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AdminProvider>.value(value: adminProvider),
        ChangeNotifierProvider<CatalogProvider>.value(value: catalogProvider),
      ],
      child: MaterialApp(
        home: AdminProductEditScreen(product: product),
      ),
    );
  }

  group('AdminProductEditScreen', () {
    testWidgets('renders product hero preview, initial stock count, and dynamic health indicator', (tester) async {
      final fakeAdmin = FakeAdminProvider();
      final fakeCatalog = FakeCatalogProvider();

      await tester.pumpWidget(buildTestWidget(
        adminProvider: fakeAdmin,
        catalogProvider: fakeCatalog,
      ));
      await tester.pumpAndSettle();

      // Product hero
      expect(find.text('Walnut Armchair'), findsOneWidget);
      expect(find.text('#p_chair_01'), findsOneWidget);
      expect(find.text('Living Room'), findsOneWidget);
      expect(find.text('Edit Product Inventory'), findsOneWidget);

      // Initial stock in text field is 4
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, equals('4'));

      // Dynamic health indicator for 4 units: Low Stock Alert
      expect(find.text('Low Stock Alert (4 units left)'), findsOneWidget);
    });

    testWidgets('stepper increments and decrements stock quantity and updates health indicator', (tester) async {
      final fakeAdmin = FakeAdminProvider();
      final fakeCatalog = FakeCatalogProvider();

      await tester.pumpWidget(buildTestWidget(
        adminProvider: fakeAdmin,
        catalogProvider: fakeCatalog,
      ));
      await tester.pumpAndSettle();

      // Tap increment [+] button 3 times: 4 -> 7 (Healthy)
      final incrementBtn = find.byIcon(Icons.add_rounded);
      await tester.tap(incrementBtn);
      await tester.tap(incrementBtn);
      await tester.tap(incrementBtn);
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, equals('7'));
      expect(find.text('Healthy Inventory (7 units)'), findsOneWidget);

      // Tap decrement [-] button 7 times down to 0: Out of stock
      final decrementBtn = find.byIcon(Icons.remove_rounded);
      for (int i = 0; i < 7; i++) {
        await tester.tap(decrementBtn);
      }
      await tester.pumpAndSettle();

      expect(textField.controller?.text, equals('0'));
      expect(find.text('Out of Stock'), findsOneWidget);
    });

    testWidgets('quick delta preset chips update stock correctly', (tester) async {
      final fakeAdmin = FakeAdminProvider();
      final fakeCatalog = FakeCatalogProvider();

      await tester.pumpWidget(buildTestWidget(
        adminProvider: fakeAdmin,
        catalogProvider: fakeCatalog,
      ));
      await tester.pumpAndSettle();

      // Tap '+10 units'
      await tester.tap(find.text('+10 units'));
      await tester.pumpAndSettle();

      var textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, equals('14'));
      expect(find.text('Healthy Inventory (14 units)'), findsOneWidget);

      // Tap 'Set to 0'
      await tester.tap(find.text('Set to 0'));
      await tester.pumpAndSettle();

      textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, equals('0'));
      expect(find.text('Out of Stock'), findsOneWidget);
    });

    testWidgets('saving changes invokes AdminProvider.updateStock and refreshes catalog', (tester) async {
      final fakeAdmin = FakeAdminProvider();
      final fakeCatalog = FakeCatalogProvider();

      await tester.pumpWidget(buildTestWidget(
        adminProvider: fakeAdmin,
        catalogProvider: fakeCatalog,
      ));
      await tester.pumpAndSettle();

      // Increment stock to 5
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      // Tap Save button
      await tester.tap(find.text('Save Inventory Changes'));
      await tester.pump(); // Start saving

      await tester.pumpAndSettle();

      expect(fakeAdmin.lastUpdatedProductId, equals('p_chair_01'));
      expect(fakeAdmin.lastUpdatedStock, equals(5));
      expect(fakeCatalog.didRefresh, isTrue);
    });
  });
}
