import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../providers/catalog_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/catalog/catalog_promo_banner.dart';
import '../../widgets/catalog/product_card.dart';
import '../../widgets/catalog/product_list_tile.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/navigation/app_navigation_shell.dart';
import 'product_detail_screen.dart';

/// Screen displaying the full browsable product catalog with search,
/// category filtering, price sorting, dual grid/list view modes,
/// and contextual promotional drops.
class CatalogScreen extends StatefulWidget {
  final String? initialCategoryId;

  const CatalogScreen({super.key, this.initialCategoryId});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _searchController = TextEditingController();
  final _categoryScrollController = ScrollController();
  final _productsScrollController = ScrollController();
  final Map<String?, GlobalKey> _chipKeys = {};
  String? _lastCenteredCategoryId;
  bool _didInitialScroll = false;

  // View Mode: true for 2-column Grid, false for 1-column List
  bool _isGridView = true;

  // Track banner dismissal per category
  String? _dismissedCategoryId;
  bool _isPromoBannerDismissed = false;

  GlobalKey _getChipKey(String? categoryId) {
    return _chipKeys.putIfAbsent(categoryId, () => GlobalKey());
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialCategoryId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<CatalogProvider>().setCategory(widget.initialCategoryId);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _categoryScrollController.dispose();
    _productsScrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_productsScrollController.hasClients) {
        _productsScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _scrollToCategory(String? categoryId, {bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = _chipKeys[categoryId];
      final targetContext = key?.currentContext;
      if (targetContext != null) {
        Scrollable.ensureVisible(
          targetContext,
          alignment: 0.5,
          duration: animated ? const Duration(milliseconds: 350) : Duration.zero,
          curve: Curves.easeInOutCubic,
        );
        _lastCenteredCategoryId = categoryId;
      }
    });
  }

  void _showFilterSortSheet(BuildContext context, CatalogProvider catalog) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      builder: (ctx) {
        SortOption selectedSort = catalog.sortOption;
        double? selectedMin = catalog.minPricePkr;
        double? selectedMax = catalog.maxPricePkr;

        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final hasActivePriceFilter = selectedMin != null || selectedMax != null;
            final isFiltered = hasActivePriceFilter || selectedSort != SortOption.featured;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.space20,
                  AppTheme.space20,
                  AppTheme.space20,
                  AppTheme.space16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sheet Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sort & Filter',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          ),
                        ),
                        if (isFiltered)
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                selectedSort = SortOption.featured;
                                selectedMin = null;
                                selectedMax = null;
                              });
                            },
                            child: Text(
                              'Reset All',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: AppTheme.space16),

                    // Section 1: Sort By
                    Text(
                      'SORT BY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: SortOption.values.map((option) {
                        final isSelected = selectedSort == option;
                        return ChoiceChip(
                          label: Text(option.label),
                          selected: isSelected,
                          showCheckmark: false,
                          onSelected: (val) {
                            if (val) {
                              setSheetState(() => selectedSort = option);
                            }
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: AppTheme.space20),

                    // Section 2: Price Range
                    Text(
                      'PRICE RANGE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildPriceChip(
                          label: 'All Prices',
                          isSelected: selectedMin == null && selectedMax == null,
                          onTap: () {
                            setSheetState(() {
                              selectedMin = null;
                              selectedMax = null;
                            });
                          },
                        ),
                        _buildPriceChip(
                          label: 'Under PKR 5,000',
                          isSelected: selectedMin == null && selectedMax == 5000,
                          onTap: () {
                            setSheetState(() {
                              selectedMin = null;
                              selectedMax = 5000;
                            });
                          },
                        ),
                        _buildPriceChip(
                          label: 'PKR 5k – 15k',
                          isSelected: selectedMin == 5000 && selectedMax == 15000,
                          onTap: () {
                            setSheetState(() {
                              selectedMin = 5000;
                              selectedMax = 15000;
                            });
                          },
                        ),
                        _buildPriceChip(
                          label: 'Over PKR 15,000',
                          isSelected: selectedMin == 15000 && selectedMax == null,
                          onTap: () {
                            setSheetState(() {
                              selectedMin = 15000;
                              selectedMax = null;
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: AppTheme.space24),

                    // Apply Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          catalog.setSortOption(selectedSort);
                          catalog.setPriceRange(min: selectedMin, max: selectedMax);
                          Navigator.of(ctx).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPriceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catalog = context.watch<CatalogProvider>();
    final products = catalog.filteredProducts;
    final selectedId = catalog.selectedCategoryId;
    final hasBottomBar = ShellNavigationScope.hasBottomBarOf(context);
    final bottomClearance = hasBottomBar ? 100.0 : 36.0;

    // Check if promo banner is dismissed for this specific category
    final showPromoBanner = !_isPromoBannerDismissed || _dismissedCategoryId != selectedId;

    // Active price filter string
    final hasActivePriceFilter = catalog.minPricePkr != null || catalog.maxPricePkr != null;
    String? priceFilterLabel;
    if (catalog.minPricePkr == null && catalog.maxPricePkr == 5000) {
      priceFilterLabel = '< PKR 5k';
    } else if (catalog.minPricePkr == 5000 && catalog.maxPricePkr == 15000) {
      priceFilterLabel = 'PKR 5k-15k';
    } else if (catalog.minPricePkr == 15000 && catalog.maxPricePkr == null) {
      priceFilterLabel = '> PKR 15k';
    }

    final isNonDefaultFiltered = hasActivePriceFilter || catalog.sortOption != SortOption.featured;

    // Auto-scroll to center on arrival or when category filter changes
    if (!_didInitialScroll) {
      final targetId = widget.initialCategoryId ?? selectedId;
      if (targetId != null) {
        final hasTarget = catalog.categories.any((c) => c.categoryId == targetId);
        if (hasTarget) {
          _didInitialScroll = true;
          _scrollToCategory(targetId, animated: true);
        }
      }
    } else if (selectedId != _lastCenteredCategoryId && selectedId != null) {
      _scrollToCategory(selectedId, animated: true);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalog'),
        actions: [
          // Filter & Sort Action
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                tooltip: 'Filter & Sort Collection',
                onPressed: () => _showFilterSortSheet(context, catalog),
              ),
              if (isNonDefaultFiltered)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppTheme.space8),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space16,
              vertical: AppTheme.space8,
            ),
            child: CustomTextField(
              controller: _searchController,
              hint: 'Search furniture, decor, lighting...',
              prefixIcon: Icons.search_rounded,
              suffix: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        catalog.setSearchQuery('');
                        _scrollToTop();
                      },
                    )
                  : null,
              onChanged: (val) {
                catalog.setSearchQuery(val);
                _scrollToTop();
              },
            ),
          ),

          // 2. Categories Horizontal Scroll Chips
          SizedBox(
            height: 48,
            child: SingleChildScrollView(
              controller: _categoryScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
              child: Row(
                children: [
                  ChoiceChip(
                    key: _getChipKey(null),
                    label: const Text('All Pieces'),
                    selected: catalog.selectedCategoryId == null,
                    showCheckmark: false,
                    onSelected: (_) {
                      catalog.setCategory(null);
                      _scrollToCategory(null);
                      _scrollToTop();
                    },
                  ),
                  for (final category in catalog.categories) ...[
                    const SizedBox(width: AppTheme.space8),
                    ChoiceChip(
                      key: _getChipKey(category.categoryId),
                      label: Text(category.name),
                      selected: catalog.selectedCategoryId == category.categoryId,
                      showCheckmark: false,
                      onSelected: (_) {
                        catalog.setCategory(category.categoryId);
                        _scrollToCategory(category.categoryId);
                        _scrollToTop();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 3. Contextual Category Offer / Drop Banner
          if (showPromoBanner)
            CatalogPromoBanner(
              categoryId: selectedId,
              onDismiss: () {
                setState(() {
                  _isPromoBannerDismissed = true;
                  _dismissedCategoryId = selectedId;
                });
              },
            ),

          // 4. Interactive Toolbar: Results Count, Active Price Tag, View Switcher
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space16,
              AppTheme.space4,
              AppTheme.space16,
              AppTheme.space4,
            ),
            child: Row(
              children: [
                // Item count
                Text(
                  '${products.length} ${products.length == 1 ? "item" : "items"} available',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),

                const SizedBox(width: 8),

                // Active price filter tag if active
                if (priceFilterLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isDark ? AppTheme.darkAccent : AppTheme.lightAccent)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      border: Border.all(
                        color: (isDark ? AppTheme.darkAccent : AppTheme.lightAccent)
                            .withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          priceFilterLabel,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                          ),
                        ),
                        const SizedBox(width: 3),
                        GestureDetector(
                          onTap: () => catalog.setPriceRange(min: null, max: null),
                          child: Icon(
                            Icons.close_rounded,
                            size: 11,
                            color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                          ),
                        ),
                      ],
                    ),
                  ),

                const Spacer(),

                // Active sort label
                Text(
                  catalog.sortOption.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                  ),
                ),

                const SizedBox(width: 8),

                // View Mode Toggle (Grid vs List)
                IconButton(
                  tooltip: _isGridView ? 'Switch to List view' : 'Switch to Grid view',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: Icon(
                    _isGridView ? Icons.view_agenda_outlined : Icons.grid_view_rounded,
                    size: 20,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                  onPressed: () {
                    setState(() => _isGridView = !_isGridView);
                  },
                ),
              ],
            ),
          ),

          // 5. Product Grid or List View with Empty / Loading states
          Expanded(
            child: catalog.isLoading
                ? const LoadingView(message: 'Loading collection...')
                : catalog.errorMessage != null
                ? ErrorView(
                    message: catalog.errorMessage!,
                    onRetry: () => catalog.refresh(),
                  )
                : products.isEmpty
                ? EmptyView(
                    icon: Icons.search_off_rounded,
                    title: 'No Items Found',
                    subtitle: 'Try adjusting your search keywords or filters.',
                    actionText: 'Reset Filters',
                    onAction: () {
                      _searchController.clear();
                      catalog.resetFilters();
                    },
                  )
                : _isGridView
                ? GridView.builder(
                    controller: _productsScrollController,
                    padding: EdgeInsets.fromLTRB(
                      AppTheme.space16,
                      AppTheme.space8,
                      AppTheme.space16,
                      bottomClearance,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: AppTheme.space12,
                      mainAxisSpacing: AppTheme.space12,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final category = catalog.categories.firstWhere(
                        (c) => c.categoryId == product.categoryId,
                        orElse: () => const Category(categoryId: '', name: ''),
                      );
                      return ProductCard(
                        product: product,
                        categoryName: category.name.isNotEmpty ? category.name : null,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(product: product),
                            ),
                          );
                        },
                      );
                    },
                  )
                : ListView.separated(
                    controller: _productsScrollController,
                    padding: EdgeInsets.fromLTRB(
                      AppTheme.space16,
                      AppTheme.space8,
                      AppTheme.space16,
                      bottomClearance,
                    ),
                    itemCount: products.length,
                    separatorBuilder: (context, index) => const SizedBox(height: AppTheme.space12),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final category = catalog.categories.firstWhere(
                        (c) => c.categoryId == product.categoryId,
                        orElse: () => const Category(categoryId: '', name: ''),
                      );
                      return ProductListTile(
                        product: product,
                        categoryName: category.name.isNotEmpty ? category.name : null,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(product: product),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
