import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/catalog/product_card.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/home/category_story_bubble.dart';
import '../../widgets/home/circular_product_item.dart';
import '../../widgets/home/promo_carousel_banner.dart';
import '../../widgets/navigation/app_navigation_shell.dart';
import '../catalog/catalog_screen.dart';
import '../catalog/product_detail_screen.dart';
import '../profile/profile_screen.dart';

/// Comprehensive modern e-commerce Home storefront featuring an auto-advancing
/// promotional banner carousel, Instagram-style circular category stories,
/// flash deals row with countdown, circular trending product picks, featured
/// collection carousel, new arrivals grid, and a bottom catalog exploration anchor.
class HomeScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Timer _countdownTimer;
  int _remainingSeconds = 6 * 3600 + 42 * 60 + 18; // 06:42:18 simulation
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          if (_remainingSeconds > 0) _remainingSeconds--;
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatCountdown(int totalSeconds) {
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  static const Map<String, String> _categoryImages = {
    'electronics': 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&q=80',
    'clothing': 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=400&q=80',
    'home-kitchen': 'https://images.unsplash.com/photo-1616046229478-9901c5536a45?w=400&q=80',
    'personal-care': 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=400&q=80',
  };

  static const List<PromoSlideItem> _promoSlides = [
    PromoSlideItem(
      title: 'Spring Awakening\nFlash Sale',
      subtitle: 'Artisanal homeware & bespoke seating with up to 30% savings.',
      badgeText: 'Limited Drop',
      ctaText: 'Shop Home',
      categoryId: 'home-kitchen',
      imageUrl: 'https://images.unsplash.com/photo-1616046229478-9901c5536a45?w=900&q=80',
      gradientColors: [Color(0xFFC2410C), Color(0xFF7C2D12)],
    ),
    PromoSlideItem(
      title: 'Engineered Sound\n& Acoustics',
      subtitle: 'Wireless studio headphones and wearable smart devices.',
      badgeText: 'New Tech',
      ctaText: 'Explore Tech',
      categoryId: 'electronics',
      imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=900&q=80',
      gradientColors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    ),
    PromoSlideItem(
      title: 'Artisanal Linens\n& Apparel',
      subtitle: 'Breathable organic fabrics, jackets, and timeless silhouettes.',
      badgeText: 'Trending',
      ctaText: 'View Clothing',
      categoryId: 'clothing',
      imageUrl: 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=900&q=80',
      gradientColors: [Color(0xFF9A3412), Color(0xFF431407)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catalog = context.watch<CatalogProvider>();
    final auth = context.watch<AuthProvider>();

    if (catalog.isLoading) {
      return const Scaffold(
        body: LoadingView(message: 'Loading products...'),
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
    final allProducts = catalog.allProducts;
    final flashDeals = allProducts.take(6).toList();
    final trendingPicks = allProducts.reversed.take(6).toList();

    final hasBottomBar = ShellNavigationScope.hasBottomBarOf(context);
    final bottomClearance = hasBottomBar ? 100.0 : 36.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Commerce App'),
        actions: [
          _buildProfileAvatarAction(context, auth, isDark),
          const SizedBox(width: AppTheme.space16),
        ],
      ),
      body: ScrollToTopListener(
        tabIndex: 0,
        scrollController: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppTheme.space8),

            // 1. Auto-Scrolling Hero Promotional Banner Carousel
            PromoCarouselBanner(
              slides: _promoSlides,
              onSlideTap: (slide) {
                if (slide.categoryId != null) {
                  catalog.setCategory(slide.categoryId);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CatalogScreen(initialCategoryId: slide.categoryId),
                    ),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CatalogScreen()),
                  );
                }
              },
            ),

            const SizedBox(height: AppTheme.space20),

            // 2. Instagram-Style Circular Category Stories
            _buildCategoryStories(context, catalog.categories, isDark),

            const SizedBox(height: AppTheme.space24),

            // 3. Flash Deals & Limited-Time Offers (Horizontal Scroll)
            if (flashDeals.isNotEmpty) ...[
              _buildFlashDealsSection(context, flashDeals, isDark),
              const SizedBox(height: AppTheme.space24),
            ],

            // 4. "Trending Essentials" — Circular Product Spotlights
            if (trendingPicks.isNotEmpty) ...[
              _buildCircularTrendingSection(context, trendingPicks, isDark),
              const SizedBox(height: AppTheme.space24),
            ],

            // 5. Featured Collection Carousel
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
              const SizedBox(height: AppTheme.space12),
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
              const SizedBox(height: AppTheme.space24),
            ],

            // 6. New Arrivals Section (2-Column Grid)
            if (newArrivals.isNotEmpty) ...[
              _buildSectionHeader(
                context,
                title: 'New Arrivals',
                subtitle: 'Recently introduced pieces in our gallery',
                onSeeAll: () {
                  catalog.setCategory(null);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CatalogScreen()),
                  );
                },
                isDark: isDark,
              ),
              const SizedBox(height: AppTheme.space12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: AppTheme.space12,
                    mainAxisSpacing: AppTheme.space12,
                  ),
                  itemCount: newArrivals.length,
                  itemBuilder: (context, index) {
                    final product = newArrivals[index];
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
                ),
              ),
              const SizedBox(height: AppTheme.space16),
            ],

            // 7. Redesigned Bottom "Explore Entire Gallery" Action Card
            _buildBottomExploreBanner(context, allProducts.length, isDark),

            // Responsive clearance so content stops cleanly above bottom bar
            SizedBox(height: bottomClearance),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildCategoryStories(BuildContext context, List<Category> categories, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Explore Collections',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                'Stories',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.space12),
        SizedBox(
          height: 98,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),
            itemCount: categories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                // "All Pieces" special story avatar
                return CategoryStoryBubble(
                  category: const Category(categoryId: '', name: 'All Pieces'),
                  imageUrl: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=300&q=80',
                  iconFallback: Icons.dashboard_outlined,
                  onTap: () {
                    context.read<CatalogProvider>().setCategory(null);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CatalogScreen()),
                    );
                  },
                );
              }

              final cat = categories[index - 1];
              final imgUrl = _categoryImages[cat.categoryId];

              return CategoryStoryBubble(
                category: cat,
                imageUrl: imgUrl,
                iconFallback: Icons.category_outlined,
                onTap: () {
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

  Widget _buildFlashDealsSection(BuildContext context, List<Product> deals, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      size: 16,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Limited Flash Deals',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                ],
              ),

              // Countdown badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF27272A) : const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  border: Border.all(
                    color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE4E4E7),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 13,
                      color: isDark ? const Color(0xFFFB923C) : const Color(0xFFEA580C),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatCountdown(_remainingSeconds),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.space12),

        // Deals Horizontal Cards
        SizedBox(
          height: 255,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
            itemCount: deals.length,
            separatorBuilder: (context, index) => const SizedBox(width: AppTheme.space12),
            itemBuilder: (context, index) {
              final product = deals[index];
              return SizedBox(
                width: 170,
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
      ],
    );
  }

  Widget _buildCircularTrendingSection(BuildContext context, List<Product> products, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trending Picks',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Handcrafted artisanal spotlight selections',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CatalogScreen()),
                  );
                },
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
        ),
        const SizedBox(height: AppTheme.space12),
        SizedBox(
          height: 152,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(width: AppTheme.space4),
            itemBuilder: (context, index) {
              final product = products[index];
              return CircularProductItem(
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
      ],
    );
  }

  Widget _buildBottomExploreBanner(BuildContext context, int totalCount, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF221915), Color(0xFF141418)]
              : const [Color(0xFFFFF8F1), Color(0xFFF9F6F3)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: isDark ? const Color(0xFF432A1E) : const Color(0xFFF5D6C4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Stack(
          children: [
            // Decorative background glowing accent sphere
            Positioned(
              right: -25,
              top: -25,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (isDark ? AppTheme.darkAccent : AppTheme.lightAccent)
                          .withValues(alpha: isDark ? 0.20 : 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Subtle decorative watermark icon
            Positioned(
              right: 14,
              top: 14,
              child: Icon(
                Icons.grid_view_rounded,
                size: 64,
                color: (isDark ? AppTheme.darkAccent : AppTheme.lightAccent)
                    .withValues(alpha: isDark ? 0.07 : 0.05),
              ),
            ),

            // Foreground Content
            Padding(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top badge row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isDark ? AppTheme.darkAccent : AppTheme.lightAccent)
                              .withValues(alpha: 0.16),
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
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: 11,
                              color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'CURATED ARCHIVE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$totalCount Pieces Live',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppTheme.space12),

                  // Headline
                  Text(
                    'Explore Full Gallery',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),

                  const SizedBox(height: 3),

                  // Subtitle
                  Text(
                    'Discover over $totalCount handcrafted pieces across all categories with real-time stock and quick filtering.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),

                  const SizedBox(height: AppTheme.space12),

                  // Micro perk chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildExplorePerkChip(
                        icon: Icons.verified_outlined,
                        label: 'Artisanal Verified',
                        isDark: isDark,
                      ),
                      _buildExplorePerkChip(
                        icon: Icons.tune_rounded,
                        label: 'Custom Filters',
                        isDark: isDark,
                      ),
                      _buildExplorePerkChip(
                        icon: Icons.local_shipping_outlined,
                        label: 'Fast Dispatch',
                        isDark: isDark,
                      ),
                    ],
                  ),

                  const SizedBox(height: AppTheme.space16),

                  // Elevated Gradient Action Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        context.read<CatalogProvider>().setCategory(null);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CatalogScreen()),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12.5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFC2410C),
                              Color(0xFFEA580C),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFC2410C).withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Browse Complete Collection',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplorePerkChip({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(
          color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
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

  Widget _buildProfileAvatarAction(BuildContext context, AuthProvider auth, bool isDark) {
    final avatarColor = isDark ? const Color(0xFFC2410C) : const Color(0xFFEA580C);
    final initial = auth.isAuthenticated && auth.displayName.trim().isNotEmpty
        ? auth.displayName.trim()[0].toUpperCase()
        : 'U';

    return Center(
      child: Tooltip(
        message: 'My Profile',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey('home_profile_avatar'),
            borderRadius: BorderRadius.circular(17),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: avatarColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: auth.isAuthenticated
                    ? Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0,
                        ),
                      )
                    : const Icon(
                        Icons.person_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
