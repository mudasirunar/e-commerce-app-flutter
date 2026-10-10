import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ecommerceapp/models/category.dart';
import 'package:ecommerceapp/models/product.dart';
import 'package:ecommerceapp/providers/catalog_provider.dart';
import 'package:ecommerceapp/screens/catalog/catalog_screen.dart';

class TestCatalogProvider extends ChangeNotifier implements CatalogProvider {
  @override
  bool isLoading = false;

  @override
  String? errorMessage;

  @override
  List<Category> categories = const [
    Category(categoryId: 'cat_living', name: 'Living Room'),
    Category(categoryId: 'cat_dining', name: 'Dining Room'),
  ];

  @override
  List<Product> filteredProducts = const [
    Product(
      productId: 'p_chair',
      name: 'Walnut Armchair',
      categoryId: 'cat_living',
      imageUrl: 'https://example.com/chair.jpg',
      priceMinor: 4500000,
      stockQuantity: 10,
    ),
  ];

  @override
  SortOption sortOption = SortOption.featured;

  @override
  String? selectedCategoryId;

  @override
  String searchQuery = '';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  void setCategory(String? categoryId) {
    selectedCategoryId = categoryId;
    notifyListeners();
  }

  @override
  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  @override
  void resetFilters() {
    selectedCategoryId = null;
    searchQuery = '';
    notifyListeners();
  }
}

void main() {
  group('CatalogScreen Widget', () {
    testWidgets('renders search field, category chips, and product cards', (tester) async {
      final fakeCatalog = TestCatalogProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<CatalogProvider>.value(
          value: fakeCatalog,
          child: const MaterialApp(
            home: CatalogScreen(),
          ),
        ),
      );

      expect(find.text('Catalog'), findsOneWidget);
      expect(find.text('All Pieces'), findsOneWidget);
      expect(find.text('Living Room'), findsOneWidget);
      expect(find.text('Dining Room'), findsOneWidget);
      expect(find.text('Walnut Armchair'), findsOneWidget);
      expect(find.text('1 item available'), findsOneWidget);
    });

    testWidgets('displays empty view when no products match filters', (tester) async {
      final fakeCatalog = TestCatalogProvider()..filteredProducts = [];

      await tester.pumpWidget(
        ChangeNotifierProvider<CatalogProvider>.value(
          value: fakeCatalog,
          child: const MaterialApp(
            home: CatalogScreen(),
          ),
        ),
      );

      expect(find.text('No Items Found'), findsOneWidget);
      expect(find.text('Reset Filters'), findsOneWidget);
    });

    testWidgets('initialCategoryId selects category and centers filter tab chip', (tester) async {
      final fakeCatalog = TestCatalogProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<CatalogProvider>.value(
          value: fakeCatalog,
          child: const MaterialApp(
            home: CatalogScreen(initialCategoryId: 'cat_living'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(fakeCatalog.selectedCategoryId, equals('cat_living'));
      final chip = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Living Room'));
      expect(chip.selected, isTrue);
    });
  });
}
