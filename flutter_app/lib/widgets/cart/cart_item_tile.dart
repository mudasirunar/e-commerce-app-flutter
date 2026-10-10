import 'package:flutter/material.dart';
import '../../models/cart_item.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_config.dart';
import '../common/quantity_stepper.dart';

/// Horizontal cart item row with thumbnail, stepper, subtotal, and stock error alert.
class CartItemTile extends StatelessWidget {
  final CartItem item;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  const CartItemTile({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final product = item.product;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.space12),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  child: Container(
                    height: 72,
                    width: 72,
                    color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceWarm,
                    child: product != null && product.imageUrl.isNotEmpty
                        ? Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(isDark),
                          )
                        : _buildPlaceholder(isDark),
                  ),
                ),

                const SizedBox(width: AppTheme.space12),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              product?.name ?? 'Item ${item.productId}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.lightTextPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: onRemove,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                        ],
                      ),

                      const SizedBox(height: AppTheme.space4),

                      Text(
                        product != null ? product.formattedPrice : 'Loading...',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                      ),

                      const SizedBox(height: AppTheme.space12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          QuantityStepper(
                            value: item.quantity,
                            max: product != null
                                ? (product.stockQuantity < AppConfig.maxCartItemQuantity
                                    ? product.stockQuantity
                                    : AppConfig.maxCartItemQuantity)
                                : AppConfig.maxCartItemQuantity,
                            onChanged: onQuantityChanged,
                          ),
                          Text(
                            item.formattedSubtotal,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Warning Banner for Stock Errors
            if (item.exceedsStock || item.isUnavailable) ...[
              const SizedBox(height: AppTheme.space8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space8, vertical: AppTheme.space4),
                decoration: BoxDecoration(
                  color: AppTheme.errorContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  item.isUnavailable
                      ? 'This product is no longer available.'
                      : 'Only ${product?.stockQuantity ?? 0} units left in stock.',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.error,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Center(
      child: Icon(
        Icons.inventory_2_outlined,
        size: 24,
        color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
      ),
    );
  }
}
