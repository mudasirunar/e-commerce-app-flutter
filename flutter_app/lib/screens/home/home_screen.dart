import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category.dart';
import '../../providers/catalog_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/catalog/product_card.dart';
import '../../widgets/common/state_views.dart';
import '../catalog/catalog_screen.dart';
import '../catalog/product_detail_screen.dart';

/// Home destination with luxury hero banner, curated category highlights,
/// featured items carousel, and new arrivals grid.
class HomeScreen extends StatelessWidget {
  final ValueChanged<int>? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catalog = context.watch<CatalogProvider>();

    if (catalog.isLoading) {
      return const Scaffold(
        body: LoadingView(message: 'Curating boutique collection...'),
      );
    }

    if (catalog.errorMessage != null && catalog.allProducts.isEmpty) {
      return Scaffold(
        body: ErrorView(
          message: catalog.errorMessage!,
          onRetry: () => catalog.refresh(),
        ),
      );
    }

    final featured = catalog.featuredProducts;
    final newArrivals = catalog.newProducts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Boutique Luxury'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CatalogScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
        onRefresh: () => catalog.refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Editorial Banner
              _buildHeroBanner(context, isDark),
              const SizedBox(height: AppTheme.space24),

              // Curated Categories Section
              _buildCategoriesSection(context, catalog.categories, isDark),
              const SizedBox(height: AppTheme.space32),

              // Featured Collection Section
              if (featured.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  title: 'Featured Collection',
                  subtitle: 'Architectural lines & artisanal materials',
                  onSeeAll: () {
                    catalog.setCategory(null);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CatalogScreen()),
                    );
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: AppTheme.space16),
                SizedBox(
                  height: 260,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
                    itemCount: featured.length,
                    separatorBuilder: (context, index) => const SizedBox(width: AppTheme.space12),
                    itemBuilder: (context, index) {
                      final product = featured[index];
                      return SizedBox(
                        width: 175,
                        child: ProductCard(
                          product: product,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(product: product),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppTheme.space32),
              ],

              // New Arrivals Section
              if (newArrivals.isNotEmpty) ...[
                _buildSectionHeader(
                  context,
                  title: 'New Arrivals',
                  subtitle: 'Recently introduced to the gallery',
                  onSeeAll: () {
                    catalog.setCategory(null);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CatalogScreen()),
                    );
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: AppTheme.space16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.68,
                      crossAxisSpacing: AppTheme.space12,
                      mainAxisSpacing: AppTheme.space12,
                    ),
                    itemCount: newArrivals.length,
                    itemBuilder: (context, index) {
                      final product = newArrivals[index];
                      return ProductCard(
                        product: product,
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
                const SizedBox(height: AppTheme.space32),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space8),
      padding: const EdgeInsets.all(AppTheme.space24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceWarm,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkAccent.withValues(alpha: 0.15) : AppTheme.lightAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Text(
              'EDITORIAL • 2026',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space12),
          Text(
            'Warm Earth &\nTerracotta',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1.15,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            'Crafted minimalist homeware, bespoke seating, and earthy artisanal accessories.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.space16),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CatalogScreen()),
              );
            },
            child: const Text('Explore Gallery'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(BuildContext context, List<Category> categories, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
          child: Text(
            'Curated Collections',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.space12),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: AppTheme.space8),
            itemBuilder: (context, index) {
              final cat = categories[index];
              return ActionChip(
                label: Text(cat.name),
                onPressed: () {
                  context.read<CatalogProvider>().setCategory(cat.categoryId);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CatalogScreen(initialCategoryId: cat.categoryId),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
    required VoidCallback onSeeAll,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: onSeeAll,
            child: Text(
              'See All',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
