import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerceapp/models/category.dart';
import 'package:ecommerceapp/models/product.dart';
import 'package:ecommerceapp/providers/catalog_provider.dart';
import 'package:ecommerceapp/services/firestore/firestore_service.dart';

class FakeFirestoreService extends FirestoreService {
  final StreamController<List<Category>> _catController = StreamController.broadcast();
  final StreamController<List<Product>> _prodController = StreamController.broadcast();

  @override
  Stream<List<Category>> watchCategories() => _catController.stream;

  @override
  Stream<List<Product>> watchProducts({String? categoryId}) => _prodController.stream;

  void emitCategories(List<Category> list) => _catController.add(list);
  void emitProducts(List<Product> list) => _prodController.add(list);

  void dispose() {
    _catController.close();
    _prodController.close();
  }
}

void main() {
  group('CatalogProvider Logic', () {
    late FakeFirestoreService fakeService;
    late CatalogProvider provider;

    final catElectronics = Category(
      categoryId: 'cat_elec',
      name: 'Electronics',
      sortOrder: 1,
    );
    final catClothing = Category(
      categoryId: 'cat_clothing',
      name: 'Clothing',
      sortOrder: 2,
    );

    final prod1 = Product(
      productId: 'p1',
      name: 'Noise Cancelling Headphones',
      categoryId: 'cat_elec',
      imageUrl: '',
      priceMinor: 2500000, // PKR 25,000
      stockQuantity: 10,
      isFeatured: true,
      createdAt: DateTime(2026, 1, 1),
    );

    final prod2 = Product(
      productId: 'p2',
      name: 'Vintage Denim Jacket',
      categoryId: 'cat_clothing',
      imageUrl: '',
      priceMinor: 850000, // PKR 8,500
      stockQuantity: 5,
      isFeatured: false,
      createdAt: DateTime(2026, 2, 1),
    );

    final prod3 = Product(
      productId: 'p3',
      name: 'Cotton T-Shirt',
      categoryId: 'cat_clothing',
      imageUrl: '',
      priceMinor: 250000, // PKR 2,500
      stockQuantity: 20,
      isFeatured: false,
      createdAt: DateTime(2026, 3, 1),
    );

    setUp(() {
      fakeService = FakeFirestoreService();
      provider = CatalogProvider(fakeService);
      fakeService.emitCategories([catElectronics, catClothing]);
      fakeService.emitProducts([prod1, prod2, prod3]);
    });

    tearDown(() {
      provider.dispose();
      fakeService.dispose();
    });

    test('initializes products and filters by category', () async {
      await pumpEventQueue();

      expect(provider.allProducts.length, 3);
      expect(provider.categories.length, 2);

      // Select clothing category
      provider.selectCategory('cat_clothing');
      expect(provider.filteredProducts.length, 2);
      expect(provider.filteredProducts.map((p) => p.productId), containsAll(['p2', 'p3']));
    });

    test('searches products by query across name and description', () async {
      await pumpEventQueue();

      provider.setSearchQuery('Denim');
      expect(provider.filteredProducts.length, 1);
      expect(provider.filteredProducts.first.productId, 'p2');

      provider.setSearchQuery('Headphones');
      expect(provider.filteredProducts.length, 1);
      expect(provider.filteredProducts.first.productId, 'p1');

      provider.setSearchQuery('NonExistent');
      expect(provider.filteredProducts.isEmpty, isTrue);
    });

    test('sorts products low to high and high to low', () async {
      await pumpEventQueue();

      provider.setSortOption(SortOption.priceLowToHigh);
      final sortedLow = provider.filteredProducts;
      expect(sortedLow[0].productId, 'p3'); // 2,500
      expect(sortedLow[1].productId, 'p2'); // 8,500
      expect(sortedLow[2].productId, 'p1'); // 25,000

      provider.setSortOption(SortOption.priceHighToLow);
      final sortedHigh = provider.filteredProducts;
      expect(sortedHigh[0].productId, 'p1'); // 25,000
      expect(sortedHigh[1].productId, 'p2'); // 8,500
      expect(sortedHigh[2].productId, 'p3'); // 2,500
    });

    test('filters by price range', () async {
      await pumpEventQueue();

      // Between 5,000 and 10,000 PKR
      provider.setPriceRange(min: 5000, max: 10000);
      expect(provider.filteredProducts.length, 1);
      expect(provider.filteredProducts.first.productId, 'p2');
    });

    test('clears all active filters', () async {
      await pumpEventQueue();

      provider.selectCategory('cat_clothing');
      provider.setSearchQuery('Denim');
      provider.setPriceRange(min: 1000);

      expect(provider.filteredProducts.length, 1);

      provider.clearFilters();
      expect(provider.filteredProducts.length, 3);
      expect(provider.selectedCategoryId, isNull);
      expect(provider.searchQuery, isEmpty);
    });
  });
}
