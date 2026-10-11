import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ecommerceapp/models/category.dart';
import 'package:ecommerceapp/models/product.dart';
import 'package:ecommerceapp/providers/catalog_provider.dart';
import 'package:ecommerceapp/screens/catalog/catalog_screen.dart';
import 'package:ecommerceapp/widgets/catalog/catalog_promo_banner.dart';
import 'package:ecommerceapp/widgets/catalog/product_card.dart';
import 'package:ecommerceapp/widgets/catalog/product_list_tile.dart';

class _FakeCatalogProvider extends ChangeNotifier implements CatalogProvider {
  @override
  bool isLoading = false;

  @override
  String? errorMessage;

  @override
  List<Category> categories = const [
    Category(categoryId: 'home-kitchen', name: 'Home & Kitchen'),
  ];

  @override
  List<Product> filteredProducts = const [
    Product(
      productId: 'prod_chair',
      name: 'Scandinavian Oak Lounge Chair',
      categoryId: 'home-kitchen',
      imageUrl: '',
      priceMinor: 3800000,
      stockQuantity: 4,
      rating: 4.8,
      reviewCount: 12,
    ),
  ];

  @override
  SortOption sortOption = SortOption.featured;

  @override
  String? selectedCategoryId;

  @override
  String searchQuery = '';

  @override
  double? minPricePkr;

  @override
  double? maxPricePkr;

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
  void setSortOption(SortOption option) {
    sortOption = option;
    notifyListeners();
  }

  @override
  void setPriceRange({double? min, double? max}) {
    minPricePkr = min;
    maxPricePkr = max;
    notifyListeners();
  }

  @override
  void resetFilters() {
    selectedCategoryId = null;
    searchQuery = '';
    minPricePkr = null;
    maxPricePkr = null;
    sortOption = SortOption.featured;
    notifyListeners();
  }
}

void main() {
  group('Catalog Redesign Widgets', () {
    testWidgets('ProductListTile renders thumbnail, title, rating, price, and responds to tap', (tester) async {
      bool tapped = false;

      const product = Product(
        productId: 'prod_chair',
        name: 'Scandinavian Oak Lounge Chair',
        categoryId: 'home-kitchen',
        imageUrl: '',
        priceMinor: 3800000,
        stockQuantity: 4,
        rating: 4.8,
        reviewCount: 12,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductListTile(
              product: product,
              categoryName: 'Home & Kitchen',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('HOME & KITCHEN'), findsOneWidget);
      expect(find.text('Scandinavian Oak Lounge Chair'), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);
      expect(find.text('(12)'), findsOneWidget);
      expect(find.text('Only 4 left'), findsOneWidget);
      expect(find.text('PKR 38,000.00'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);

      await tester.tap(find.text('Scandinavian Oak Lounge Chair'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('CatalogPromoBanner renders category specific headline and responds to dismiss', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CatalogPromoBanner(
              categoryId: 'electronics',
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      expect(find.text('STUDIO SOUND'), findsOneWidget);
      expect(find.text('1-Year Coverage Included'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      expect(dismissed, isTrue);
    });

    testWidgets('CatalogScreen toggles between Grid and List view modes', (tester) async {
      final fake = _FakeCatalogProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<CatalogProvider>.value(
          value: fake,
          child: const MaterialApp(
            home: CatalogScreen(),
          ),
        ),
      );

      // Initially in Grid mode
      expect(find.byType(ProductCard), findsOneWidget);
      expect(find.byType(ProductListTile), findsNothing);

      // Toggle to List mode
      await tester.tap(find.byTooltip('Switch to List view'));
      await tester.pumpAndSettle();

      expect(find.byType(ProductListTile), findsOneWidget);
      expect(find.byType(ProductCard), findsNothing);

      // Toggle back to Grid mode
      await tester.tap(find.byTooltip('Switch to Grid view'));
      await tester.pumpAndSettle();

      expect(find.byType(ProductCard), findsOneWidget);
      expect(find.byType(ProductListTile), findsNothing);
    });
  });
}
