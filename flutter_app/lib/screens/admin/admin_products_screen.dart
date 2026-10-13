import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../providers/admin_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/state_views.dart';
import 'admin_product_edit_screen.dart';

/// Screen listing all catalog products with administrative stock controls,
/// category filters, stock health metrics, and search.
class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategoryId = 'All';
  String _selectedStockFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getCategoryName(String categoryId, List<Category> categories) {
    for (final c in categories) {
      if (c.categoryId == categoryId) return c.name;
    }
    return categoryId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    AdminProvider? admin;
    try {
      admin = context.watch<AdminProvider>();
    } catch (_) {}
    final catalog = context.watch<CatalogProvider>();

    final allProducts = (admin != null && admin.allProducts.isNotEmpty)
        ? admin.allProducts
        : catalog.allProducts;
    final categories = catalog.categories;

    // Operational Metrics
    final totalSkus = allProducts.length;
    final lowStockCount = allProducts.where((p) => p.isLowStock).length;
    final outOfStockCount = allProducts.where((p) => p.isOutOfStock).length;
    final hiddenCount = allProducts.where((p) => !p.isActive).length;

    // Filter Products
    final filteredProducts = allProducts.where((p) {
      // 1. Text Search Filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = p.name.toLowerCase().contains(q);
        final matchesId = p.productId.toLowerCase().contains(q);
        final catName = _getCategoryName(p.categoryId, categories).toLowerCase();
        final matchesCat = catName.contains(q);
        if (!matchesName && !matchesId && !matchesCat) return false;
      }

      // 2. Category Filter
      if (_selectedCategoryId != 'All' && p.categoryId != _selectedCategoryId) {
        return false;
      }

      // 3. Stock Health Filter
      if (_selectedStockFilter == 'Low Stock' && !p.isLowStock) {
        return false;
      } else if (_selectedStockFilter == 'Out of Stock' && !p.isOutOfStock) {
        return false;
      } else if (_selectedStockFilter == 'Hidden' && p.isActive) {
        return false;
      }

      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalog & Stock Inventory'),
      ),
      body: Column(
        children: [
          // 1. Overview Metrics Summary Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: 10),
            color: isDark ? const Color(0xFF18181B) : const Color(0xFFF9F7F5),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricPill(
                    label: 'Total SKUs',
                    count: '$totalSkus',
                    isSelected: _selectedStockFilter == 'All',
                    color: accentColor,
                    isDark: isDark,
                    onTap: () => setState(() => _selectedStockFilter = 'All'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricPill(
                    label: 'Low Stock',
                    count: '$lowStockCount',
                    isSelected: _selectedStockFilter == 'Low Stock',
                    color: const Color(0xFFF59E0B),
                    isDark: isDark,
                    onTap: () => setState(() {
                      _selectedStockFilter = _selectedStockFilter == 'Low Stock' ? 'All' : 'Low Stock';
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricPill(
                    label: 'Out of Stock',
                    count: '$outOfStockCount',
                    isSelected: _selectedStockFilter == 'Out of Stock',
                    color: const Color(0xFFEF4444),
                    isDark: isDark,
                    onTap: () => setState(() {
                      _selectedStockFilter = _selectedStockFilter == 'Out of Stock' ? 'All' : 'Out of Stock';
                    }),
                  ),
                ),
                if (hiddenCount > 0) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricPill(
                      label: 'Hidden',
                      count: '$hiddenCount',
                      isSelected: _selectedStockFilter == 'Hidden',
                      color: const Color(0xFF8B5CF6),
                      isDark: isDark,
                      onTap: () => setState(() {
                        _selectedStockFilter = _selectedStockFilter == 'Hidden' ? 'All' : 'Hidden';
                      }),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 2. Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(AppTheme.space16, AppTheme.space12, AppTheme.space16, 6),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFF4EFEA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search products by name, category, or ID...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: accentColor,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // 3. Category Filter Chips (Tick-free, solid fill on selected)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: 4),
              children: [
                // "All" Category Chip
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildCategoryChip(
                    id: 'All',
                    label: 'All (${allProducts.length})',
                    isSelected: _selectedCategoryId == 'All',
                    accentColor: accentColor,
                    isDark: isDark,
                  ),
                ),
                // Category Chips
                ...categories.map((cat) {
                  final catCount = allProducts.where((p) => p.categoryId == cat.categoryId).length;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildCategoryChip(
                      id: cat.categoryId,
                      label: '${cat.name} ($catCount)',
                      isSelected: _selectedCategoryId == cat.categoryId,
                      accentColor: accentColor,
                      isDark: isDark,
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // 4. Products List View
          Expanded(
            child: catalog.isLoading
                ? const LoadingView(message: 'Loading inventory...')
                : filteredProducts.isEmpty
                    ? const EmptyView(
                        icon: Icons.inventory_2_outlined,
                        title: 'No Products Match',
                        subtitle: 'No items match your active search and category filters.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(AppTheme.space16, 8, AppTheme.space16, AppTheme.space24),
                        itemCount: filteredProducts.length,
                        separatorBuilder: (context, index) => const SizedBox(height: AppTheme.space12),
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          final categoryName = _getCategoryName(product.categoryId, categories);
                          return _buildInventoryCard(
                            context: context,
                            product: product,
                            categoryName: categoryName,
                            isDark: isDark,
                            accentColor: accentColor,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required String label,
    required String count,
    required bool isSelected,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected
          ? color.withValues(alpha: isDark ? 0.22 : 0.12)
          : (isDark ? const Color(0xFF27272A) : Colors.white),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? color.withValues(alpha: 0.6)
                  : (isDark ? const Color(0xFF3F3F46) : const Color(0xFFE5E5E5)),
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                count,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? color : (isDark ? Colors.white : Colors.black87),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? color : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required String id,
    required String label,
    required bool isSelected,
    required Color accentColor,
    required bool isDark,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      showCheckmark: false,
      onSelected: (_) => setState(() => _selectedCategoryId = id),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected
            ? Colors.white
            : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
      ),
      selectedColor: accentColor,
      backgroundColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF4EFEA),
      side: BorderSide(
        color: isSelected
            ? accentColor
            : (isDark ? const Color(0xFF3F3F46) : const Color(0xFFE5E5E5)),
        width: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(9),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    );
  }

  Widget _buildInventoryCard({
    required BuildContext context,
    required Product product,
    required String categoryName,
    required bool isDark,
    required Color accentColor,
  }) {
    final stockColor = product.isOutOfStock
        ? const Color(0xFFEF4444)
        : product.isLowStock
            ? const Color(0xFFF59E0B)
            : const Color(0xFF10B981);

    final stockLabel = product.isOutOfStock
        ? 'Out of Stock (0)'
        : product.isLowStock
            ? 'Low Stock (${product.stockQuantity})'
            : 'In Stock (${product.stockQuantity})';

    // Dynamic status dot priority:
    // 1. Hidden (isActive == false) is always top priority -> grey dot (regardless of stock quantity)
    // 2. Visible & Out of stock -> red dot
    // 3. Visible & Low stock -> amber / gold dot
    // 4. Visible & Healthy inventory -> green dot
    final Color statusDotColor;
    if (!product.isActive) {
      statusDotColor = const Color(0xFF9CA3AF);
    } else if (product.isOutOfStock) {
      statusDotColor = const Color(0xFFEF4444);
    } else if (product.isLowStock) {
      statusDotColor = const Color(0xFFF59E0B);
    } else {
      statusDotColor = const Color(0xFF10B981);
    }

    // Using Material + InkWell fixes the "ListTile background color or ink splashes may be invisible" warning
    return Material(
      color: isDark ? const Color(0xFF1E1E22) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AdminProductEditScreen(product: product),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(AppTheme.space12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF2E2E34) : const Color(0xFFE7E5E4),
              width: 1.1,
            ),
          ),
          child: Row(
            children: [
              // Product Image with dynamic status indicator dot
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 64,
                      width: 64,
                      color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                      child: product.imageUrl.isNotEmpty
                          ? Image.network(
                              product.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.chair_outlined, size: 28),
                            )
                          : const Icon(Icons.chair_outlined, size: 28),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      key: ValueKey('status_dot_${product.productId}'),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: statusDotColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF1E1E22) : Colors.white,
                          width: 1.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppTheme.space12),

              // Product Info & Stock
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              letterSpacing: -0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!product.isActive)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Hidden',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF27272A) : const Color(0xFFF4EFEA),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            categoryName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '#${product.productId}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          product.formattedPrice,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: stockColor.withValues(alpha: isDark ? 0.16 : 0.10),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: stockColor.withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: stockColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                stockLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: stockColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Action Chevron
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
