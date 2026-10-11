import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../providers/catalog_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_formatter.dart';
import 'order_status_badge.dart';

/// Card summarizing customer order details in order history listings.
class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onTap;

  const OrderCard({super.key, required this.order, this.onTap});

  String? _resolveItemImage(BuildContext context, OrderItemSnapshot item) {
    if (item.imageUrlSnapshot != null && item.imageUrlSnapshot!.isNotEmpty) {
      return item.imageUrlSnapshot;
    }
    try {
      final catalog = context.read<CatalogProvider>();
      final products = catalog.allProducts;
      for (final p in products) {
        if (p.productId == item.productId && p.imageUrl.isNotEmpty) {
          return p.imageUrl;
        }
      }
      for (final p in products) {
        if (p.name.trim().toLowerCase() == item.nameSnapshot.trim().toLowerCase() &&
            p.imageUrl.isNotEmpty) {
          return p.imageUrl;
        }
      }
    } catch (_) {}
    return null;
  }

  Widget _buildThumbnail(String? imageUrl, {required bool isDark, required double size}) {
    Widget content;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        content = Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallback(isDark),
        );
      } else if (imageUrl.startsWith('assets/')) {
        content = Image.asset(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallback(isDark),
        );
      } else {
        content = Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallback(isDark),
        );
      }
    } else {
      content = _buildFallback(isDark);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: size,
        height: size,
        color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        child: content,
      ),
    );
  }

  Widget _buildFallback(bool isDark) {
    return Center(
      child: Icon(
        Icons.inventory_2_outlined,
        size: 18,
        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.space12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Order ID & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.orderId.substring(0, order.orderId.length > 8 ? 8 : order.orderId.length)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                  OrderStatusBadge(status: order.status),
                ],
              ),

              const SizedBox(height: AppTheme.space8),

              // Date & Item Count
              Text(
                '${DateFormatter.formatDateTime(order.createdAt)} • ${order.totalItemCount} ${order.totalItemCount == 1 ? 'item' : 'items'}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),

              // Items Product Preview with Images
              if (order.items.isNotEmpty) ...[
                const SizedBox(height: AppTheme.space12),
                if (order.items.length == 1) ...[
                  Row(
                    children: [
                      _buildThumbnail(
                        _resolveItemImage(context, order.items.first),
                        isDark: isDark,
                        size: 46,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.items.first.nameSnapshot,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Qty: ${order.items.first.quantity} • ${order.items.first.formattedUnitPrice}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 42,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: order.items.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            final item = order.items[idx];
                            return _buildThumbnail(
                              _resolveItemImage(context, item),
                              isDark: isDark,
                              size: 42,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${order.items.first.nameSnapshot} and ${order.items.length - 1} other ${order.items.length - 1 == 1 ? 'item' : 'items'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ],

              const Divider(height: AppTheme.space24),

              // Total & View Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.formattedTotal,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                        ),
                      ),
                      const SizedBox(width: AppTheme.space4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
