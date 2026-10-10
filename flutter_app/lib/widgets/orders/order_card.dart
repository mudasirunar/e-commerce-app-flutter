import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_formatter.dart';
import 'order_status_badge.dart';

/// Card summarizing customer order details in order history listings.
class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onTap;

  const OrderCard({super.key, required this.order, this.onTap});

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
