import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../providers/catalog_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/catalog/product_card.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/state_views.dart';
import 'product_detail_screen.dart';

/// Screen displaying the full browsable product catalog with search,
/// category filtering, price sorting, and responsive grid layout.
class CatalogScreen extends StatefulWidget {
  final String? initialCategoryId;

  const CatalogScreen({super.key, this.initialCategoryId});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _searchController = TextEditingController();
  final _categoryScrollController = ScrollController();
  final Map<String?, GlobalKey> _chipKeys = {};
  String? _lastCenteredCategoryId;
  bool _didInitialScroll = false;

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
    super.dispose();
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

  void _showSortSheet(BuildContext context, CatalogProvider catalog) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppTheme.space24,
              horizontal: AppTheme.space16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space8,
                  ),
                  child: Text(
                    'Sort Collection',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space16),
                ...SortOption.values.map((option) {
                  final isSelected = catalog.sortOption == option;
                  return ListTile(
                    title: Text(
                      option.label,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? (isDark
                                  ? AppTheme.darkAccent
                                  : AppTheme.lightAccent)
                            : (isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.lightTextPrimary),
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_rounded,
                            color: isDark
                                ? AppTheme.darkAccent
                                : AppTheme.lightAccent,
                          )
                        : null,
                    onTap: () {
                      catalog.setSortOption(option);
                      Navigator.of(ctx).pop();
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catalog = context.watch<CatalogProvider>();
    final products = catalog.filteredProducts;
    final selectedId = catalog.selectedCategoryId;

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
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort Collection',
            onPressed: () => _showSortSheet(context, catalog),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter header
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
                      },
                    )
                  : null,
              onChanged: (val) => catalog.setSearchQuery(val),
            ),
          ),

          // Categories horizontal scroll list with centered auto-scroll
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
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Results count indicator
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space16,
              vertical: AppTheme.space8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${products.length} ${products.length == 1 ? "item" : "items"} available',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
                Text(
                  catalog.sortOption.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                  ),
                ),
              ],
            ),
          ),

          // Product Grid or Empty/Loading state
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
                    subtitle: 'Try adjusting your search keywords or category filters.',
                    actionText: 'Reset Filters',
                    onAction: () {
                      _searchController.clear();
                      catalog.resetFilters();
                    },
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                        categoryName: category.name.isNotEmpty
                            ? category.name
                            : null,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductDetailScreen(product: product),
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
