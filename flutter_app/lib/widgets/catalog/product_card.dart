import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../theme/app_theme.dart';
import 'stock_badge.dart';

/// Boutique luxury product card designed for grid and list browsing.
class ProductCard extends StatelessWidget {
  final Product product;
  final String? categoryName;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    this.categoryName,
    this.onTap,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with aspect ratio and fallback
            AspectRatio(
              aspectRatio: 1.1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceWarm,
                    child: product.imageUrl.isNotEmpty
                        ? Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(isDark),
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Center(
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    value: progress.expectedTotalBytes != null
                                        ? progress.cumulativeBytesLoaded /
                                            progress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                          )
                        : _buildPlaceholder(isDark),
                  ),
                  if (product.isFeatured)
                    Positioned(
                      top: AppTheme.space8,
                      left: AppTheme.space8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: Text(
                          'Featured',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.space12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (categoryName != null) ...[
                      Text(
                        categoryName!.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppTheme.space4),
                    ],

                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.formattedPrice,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                                ),
                              ),
                              const SizedBox(height: AppTheme.space4),
                              StockBadge(product: product),
                            ],
                          ),
                        ),
                        if (onAddToCart != null && product.isInStock)
                          InkWell(
                            onTap: onAddToCart,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                              ),
                              child: Icon(
                                Icons.add_shopping_cart_rounded,
                                size: 16,
                                color: isDark ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Center(
      child: Icon(
        Icons.inventory_2_outlined,
        size: 32,
        color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
      ),
    );
  }
}
