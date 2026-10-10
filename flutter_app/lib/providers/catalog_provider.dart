import 'dart:async';
import 'package:flutter/foundation.dart' hide Category;
import '../models/category.dart';
import '../models/product.dart';
import '../services/firestore/firestore_service.dart';

enum SortOption {
  featured('Featured'),
  priceLowToHigh('Price: Low to High'),
  priceHighToLow('Price: High to Low'),
  newest('Newest Arrivals');

  final String label;
  const SortOption(this.label);
}

/// Provider managing active categories, products, search queries, filtering, and sorting.
class CatalogProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;

  List<Category> _categories = [];
  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  String? _selectedCategoryId;
  String _searchQuery = '';
  SortOption _sortOption = SortOption.featured;
  double? _minPricePkr;
  double? _maxPricePkr;

  StreamSubscription<List<Category>>? _categoriesSub;
  StreamSubscription<List<Product>>? _productsSub;

  CatalogProvider(this._firestoreService) {
    _init();
  }

  List<Category> get categories => _categories;
  List<Product> get allProducts => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  SortOption get sortOption => _sortOption;
  double? get minPricePkr => _minPricePkr;
  double? get maxPricePkr => _maxPricePkr;

  /// Active products marked as featured for the Home screen banner/carousel.
  List<Product> get featuredProducts =>
      _products.where((p) => p.isFeatured && p.isActive).toList();

  /// Newest products for the Home screen "New Arrivals" section.
  List<Product> get newProducts {
    final list = _products.where((p) => p.isActive).toList();
    list.sort((a, b) {
      final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });
    return list.take(8).toList();
  }

  /// Filtered and sorted product list based on current UI controls.
  List<Product> get filteredProducts {
    var result = _products.where((p) => p.isActive).toList();

    // Filter by Category
    if (_selectedCategoryId != null && _selectedCategoryId!.isNotEmpty) {
      result = result.where((p) => p.categoryId == _selectedCategoryId).toList();
    }

    // Filter by Search Query
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      result = result.where((p) {
        return p.normalizedName.contains(query) ||
            p.name.toLowerCase().contains(query) ||
            p.description.toLowerCase().contains(query);
      }).toList();
    }

    // Filter by Price Range
    if (_minPricePkr != null) {
      result = result.where((p) => p.pricePkr >= _minPricePkr!).toList();
    }
    if (_maxPricePkr != null) {
      result = result.where((p) => p.pricePkr <= _maxPricePkr!).toList();
    }

    // Sort Results
    switch (_sortOption) {
      case SortOption.priceLowToHigh:
        result.sort((a, b) => a.priceMinor.compareTo(b.priceMinor));
        break;
      case SortOption.priceHighToLow:
        result.sort((a, b) => b.priceMinor.compareTo(a.priceMinor));
        break;
      case SortOption.newest:
        result.sort((a, b) {
          final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
          final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
          return bTime.compareTo(aTime);
        });
        break;
      case SortOption.featured:
        // Featured products first, then alphabetically
        result.sort((a, b) {
          if (a.isFeatured == b.isFeatured) {
            return a.name.compareTo(b.name);
          }
          return a.isFeatured ? -1 : 1;
        });
        break;
    }

    return result;
  }

  void _init() {
    _categoriesSub = _firestoreService.watchCategories().listen(
      (categories) {
        _categories = categories;
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = 'Failed to load categories.';
        notifyListeners();
      },
    );

    _productsSub = _firestoreService.watchProducts().listen(
      (products) {
        _products = products;
        _isLoading = false;
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = 'Failed to load products.';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // ==================== FILTER & SEARCH ACTIONS ====================

  void selectCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSortOption(SortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void setPriceRange({double? min, double? max}) {
    _minPricePkr = min;
    _maxPricePkr = max;
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategoryId = null;
    _searchQuery = '';
    _sortOption = SortOption.featured;
    _minPricePkr = null;
    _maxPricePkr = null;
    notifyListeners();
  }

  Product? findProductById(String productId) {
    for (final p in _products) {
      if (p.productId == productId) return p;
    }
    return null;
  }

  Category? findCategoryById(String categoryId) {
    for (final c in _categories) {
      if (c.categoryId == categoryId) return c;
    }
    return null;
  }

  @override
  void dispose() {
    _categoriesSub?.cancel();
    _productsSub?.cancel();
    super.dispose();
  }
}
