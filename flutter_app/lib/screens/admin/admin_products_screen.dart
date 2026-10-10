import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/catalog_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/catalog/stock_badge.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/state_views.dart';
import 'admin_product_edit_screen.dart';

/// Screen listing all catalog products with administrative stock controls.
class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final _searchController = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catalog = context.watch<CatalogProvider>();

    final products = catalog.allProducts.where((p) {
      if (_filter.isEmpty) return true;
      return p.name.toLowerCase().contains(_filter.toLowerCase()) ||
          p.productId.toLowerCase().contains(_filter.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalog & Stock Inventory'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space12),
            child: CustomTextField(
              controller: _searchController,
              hint: 'Search products by name...',
              prefixIcon: Icons.search_rounded,
              onChanged: (val) => setState(() => _filter = val.trim()),
            ),
          ),
          Expanded(
            child: catalog.isLoading
                ? const LoadingView(message: 'Loading inventory...')
                : products.isEmpty
                    ? const EmptyView(
                        icon: Icons.inventory_2_outlined,
                        title: 'No Products Match',
                        subtitle: 'No items match your search filter.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppTheme.space16),
                        itemCount: products.length,
                        separatorBuilder: (context, index) => const SizedBox(height: AppTheme.space12),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceWarm,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              border: Border.all(
                                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                child: Container(
                                  height: 48,
                                  width: 48,
                                  color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                                  child: product.imageUrl.isNotEmpty
                                      ? Image.network(
                                          product.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.chair_outlined),
                                        )
                                      : const Icon(Icons.chair_outlined),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      product.name,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                  ),
                                  if (!product.isActive)
                                    Container(
                                      margin: const EdgeInsets.only(left: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade400,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Hidden',
                                        style: TextStyle(fontSize: 10, color: Colors.black87),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Text(
                                      product.formattedPrice,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                                      ),
                                    ),
                                    const SizedBox(width: AppTheme.space12),
                                    StockBadge(product: product),
                                  ],
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AdminProductEditScreen(product: product),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
