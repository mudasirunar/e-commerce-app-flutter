import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ecommerceapp/models/category.dart';
import 'package:ecommerceapp/models/product.dart';
import 'package:ecommerceapp/providers/catalog_provider.dart';
import 'package:ecommerceapp/screens/admin/admin_product_edit_screen.dart';
import 'package:ecommerceapp/screens/admin/admin_products_screen.dart';

class FakeCatalogProvider extends ChangeNotifier implements CatalogProvider {
  @override
  final List<Category> categories;
  @override
  final List<Product> allProducts;

  FakeCatalogProvider({
    required this.categories,
    required List<Product> products,
  }) : allProducts = products;

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final sampleCategories = [
    const Category(categoryId: 'cat_living', name: 'Living Room'),
    const Category(categoryId: 'cat_bedroom', name: 'Bedroom'),
  ];

  final sampleProducts = [
    const Product(
      productId: 'p_chair_01',
      name: 'Walnut Armchair',
      categoryId: 'cat_living',
      imageUrl: '',
      priceMinor: 4500000,
      stockQuantity: 12, // Healthy
      isActive: true,
    ),
    const Product(
      productId: 'p_table_02',
      name: 'Marble Coffee Table',
      categoryId: 'cat_living',
      imageUrl: '',
      priceMinor: 6500000,
      stockQuantity: 3, // Low Stock
      isActive: true,
    ),
    const Product(
      productId: 'p_bed_03',
      name: 'Oak Bed Frame',
      categoryId: 'cat_bedroom',
      imageUrl: '',
      priceMinor: 12000000,
      stockQuantity: 0, // Out of Stock
      isActive: false, // Hidden
    ),
  ];

  Widget buildTestWidget(FakeCatalogProvider provider) {
    return ChangeNotifierProvider<CatalogProvider>.value(
      value: provider,
      child: const MaterialApp(
        home: AdminProductsScreen(),
      ),
    );
  }

  group('AdminProductsScreen', () {
    testWidgets('renders metric overview, search, category chips, and product cards without ink warnings', (tester) async {
      final provider = FakeCatalogProvider(
        categories: sampleCategories,
        products: sampleProducts,
      );

      await tester.pumpWidget(buildTestWidget(provider));
      await tester.pumpAndSettle();

      // Metric pills
      expect(find.text('Total SKUs'), findsOneWidget);
      expect(find.text('3'), findsOneWidget); // 3 Total
      expect(find.text('Low Stock'), findsOneWidget);
      expect(find.text('Out of Stock'), findsOneWidget);
      expect(find.text('Hidden'), findsNWidgets(2)); // metric pill label + card badge
      expect(find.text('1'), findsNWidgets(3)); // 1 Low stock, 1 Out of Stock, 1 Hidden

      // Search field
      expect(find.byType(TextField), findsOneWidget);

      // Category chips (checkmarks must be hidden)
      expect(find.text('All (3)'), findsOneWidget);
      expect(find.text('Living Room (2)'), findsOneWidget);
      expect(find.text('Bedroom (1)'), findsOneWidget);

      final choiceChips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
      for (final chip in choiceChips) {
        expect(chip.showCheckmark, isFalse);
      }

      // Products rendered
      expect(find.text('Walnut Armchair'), findsOneWidget);
      expect(find.text('Marble Coffee Table'), findsOneWidget);
      expect(find.text('Oak Bed Frame'), findsOneWidget);

      // Stock badges
      expect(find.text('In Stock (12)'), findsOneWidget);
      expect(find.text('Low Stock (3)'), findsOneWidget);
      expect(find.text('Out of Stock (0)'), findsOneWidget);
    });

    testWidgets('filters items accurately with real-time text search', (tester) async {
      final provider = FakeCatalogProvider(
        categories: sampleCategories,
        products: sampleProducts,
      );

      await tester.pumpWidget(buildTestWidget(provider));
      await tester.pumpAndSettle();

      // Search for 'Marble'
      await tester.enterText(find.byType(TextField), 'Marble');
      await tester.pumpAndSettle();

      expect(find.text('Marble Coffee Table'), findsOneWidget);
      expect(find.text('Walnut Armchair'), findsNothing);
      expect(find.text('Oak Bed Frame'), findsNothing);
    });

    testWidgets('filters items by category chip selection', (tester) async {
      final provider = FakeCatalogProvider(
        categories: sampleCategories,
        products: sampleProducts,
      );

      await tester.pumpWidget(buildTestWidget(provider));
      await tester.pumpAndSettle();

      // Tap 'Bedroom (1)' chip
      await tester.tap(find.text('Bedroom (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Oak Bed Frame'), findsOneWidget);
      expect(find.text('Walnut Armchair'), findsNothing);
      expect(find.text('Marble Coffee Table'), findsNothing);
    });

    testWidgets('filters items by stock metric filter pill', (tester) async {
      final provider = FakeCatalogProvider(
        categories: sampleCategories,
        products: sampleProducts,
      );

      await tester.pumpWidget(buildTestWidget(provider));
      await tester.pumpAndSettle();

      // Tap 'Out of Stock' metric pill
      await tester.tap(find.text('Out of Stock'));
      await tester.pumpAndSettle();

      expect(find.text('Oak Bed Frame'), findsOneWidget);
      expect(find.text('Walnut Armchair'), findsNothing);
      expect(find.text('Marble Coffee Table'), findsNothing);
    });

    testWidgets('tapping product card navigates to AdminProductEditScreen', (tester) async {
      final provider = FakeCatalogProvider(
        categories: sampleCategories,
        products: sampleProducts,
      );

      await tester.pumpWidget(buildTestWidget(provider));
      await tester.pumpAndSettle();

      // Tap on the first card
      await tester.tap(find.text('Walnut Armchair'));
      await tester.pumpAndSettle();

      // Verify AdminProductEditScreen is opened
      expect(find.byType(AdminProductEditScreen), findsOneWidget);
      expect(find.text('Edit Product Inventory'), findsOneWidget);
      expect(find.text('Units available'), findsOneWidget);
    });

    testWidgets('renders dynamic status dots with hidden taking highest priority', (tester) async {
      final productsWithHiddenHighStock = [
        const Product(
          productId: 'p_healthy',
          name: 'Healthy Item',
          categoryId: 'cat_living',
          imageUrl: '',
          priceMinor: 100000,
          stockQuantity: 20,
          isActive: true,
        ),
        const Product(
          productId: 'p_low',
          name: 'Low Stock Item',
          categoryId: 'cat_living',
          imageUrl: '',
          priceMinor: 100000,
          stockQuantity: 3,
          isActive: true,
        ),
        const Product(
          productId: 'p_oos',
          name: 'OOS Item',
          categoryId: 'cat_living',
          imageUrl: '',
          priceMinor: 100000,
          stockQuantity: 0,
          isActive: true,
        ),
        const Product(
          productId: 'p_hidden_high_stock',
          name: 'Hidden High Stock Item',
          categoryId: 'cat_living',
          imageUrl: '',
          priceMinor: 100000,
          stockQuantity: 1000, // Stock is 1000, but hidden!
          isActive: false,
        ),
      ];

      final provider = FakeCatalogProvider(
        categories: sampleCategories,
        products: productsWithHiddenHighStock,
      );

      await tester.pumpWidget(buildTestWidget(provider));
      await tester.pumpAndSettle();

      // Helper to find dot decoration color
      Color getDotColor(String productId) {
        final containerFinder = find.byKey(ValueKey('status_dot_$productId'));
        expect(containerFinder, findsOneWidget);
        final container = tester.widget<Container>(containerFinder);
        final decoration = container.decoration as BoxDecoration;
        return decoration.color!;
      }

      // Healthy + active -> Green
      expect(getDotColor('p_healthy'), const Color(0xFF10B981));

      // Low stock + active -> Amber
      expect(getDotColor('p_low'), const Color(0xFFF59E0B));

      // Out of stock + active -> Red
      expect(getDotColor('p_oos'), const Color(0xFFEF4444));

      // Hidden even with 1000 stock -> Grey (highest priority)
      expect(getDotColor('p_hidden_high_stock'), const Color(0xFF9CA3AF));
    });
  });
}
