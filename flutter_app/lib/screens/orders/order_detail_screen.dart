import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_confirmation_dialog.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/orders/order_status_badge.dart';

/// Screen displaying detailed immutable snapshots and lifecycle progress for an order.
class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _isCancelling = false;

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

  Widget _buildProductThumbnail(String? imageUrl, {required bool isDark, double size = 56}) {
    Widget content;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        content = Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(isDark),
        );
      } else if (imageUrl.startsWith('assets/')) {
        content = Image.asset(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(isDark),
        );
      } else {
        content = Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(isDark),
        );
      }
    } else {
      content = _buildFallbackIcon(isDark);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: size,
        height: size,
        color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        child: content,
      ),
    );
  }

  Widget _buildFallbackIcon(bool isDark) {
    return Center(
      child: Icon(
        Icons.inventory_2_outlined,
        size: 24,
        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
      ),
    );
  }

  Future<void> _handleCancelOrder(OrderModel liveOrder) async {
    final confirmed = await AppConfirmationDialog.show(
      context: context,
      title: 'Cancel Order?',
      message:
          'Are you sure you want to cancel Order ${liveOrder.displayId}?\n\nReserved items will be restored to store inventory immediately.',
      icon: Icons.cancel_outlined,
      confirmLabel: 'Confirm',
      cancelLabel: 'Keep Order',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      setState(() => _isCancelling = true);
      final orderProvider = context.read<OrderProvider>();
      final success = await orderProvider.cancelOrder(
        liveOrder.orderId,
        reason: 'Customer requested cancellation via app',
      );

      if (mounted) {
        setState(() => _isCancelling = false);
        if (success) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order cancelled and inventory restored.'),
              backgroundColor: AppTheme.success,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (orderProvider.errorMessage != null) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(orderProvider.errorMessage!),
              backgroundColor: AppTheme.error,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final orderProvider = context.watch<OrderProvider>();
    final liveOrder = orderProvider.getOrderById(widget.order.orderId) ?? widget.order;

    return Scaffold(
      appBar: AppBar(
        title: Text('Order ${liveOrder.displayId}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20, vertical: AppTheme.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Header Card
            Container(
              padding: const EdgeInsets.all(AppTheme.space20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceWarm,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Order Status',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      OrderStatusBadge(status: liveOrder.status),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space16),
                  _buildStatusStepper(liveOrder.status, isDark),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space24),

            // Item Snapshots Section
            Text(
              'Items Purchased (${liveOrder.totalQuantity})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.space12),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: liveOrder.items.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppTheme.space12),
              itemBuilder: (context, index) {
                final item = liveOrder.items[index];
                return Container(
                  padding: const EdgeInsets.all(AppTheme.space12),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceWarm,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                  ),
                  child: Row(
                    children: [
                      _buildProductThumbnail(
                        _resolveItemImage(context, item),
                        isDark: isDark,
                        size: 54,
                      ),
                      const SizedBox(width: AppTheme.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.nameSnapshot,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.quantity} × ${item.formattedUnitPrice}',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        item.formattedSubtotal,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppTheme.space24),

            // Delivery Details Section
            Text(
              'Delivery Destination',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.space12),

            Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceWarm,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 18),
                      const SizedBox(width: AppTheme.space8),
                      Text(
                        liveOrder.deliveryName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space8),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 18),
                      const SizedBox(width: AppTheme.space8),
                      Text(
                        liveOrder.deliveryPhone,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.home_outlined, size: 18),
                      const SizedBox(width: AppTheme.space8),
                      Expanded(
                        child: Text(
                          liveOrder.deliveryAddress,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space24),

            // Financial Summary Section
            Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceWarm,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Items Subtotal',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                      Text(
                        liveOrder.formattedSubtotal,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Delivery Fee',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                      Text(
                        liveOrder.formattedDeliveryFee,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total (Cash on Delivery)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        liveOrder.formattedTotal,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space32),

            // Cancel Order Button (Permitted for Pending orders only!)
            if (liveOrder.canBeCancelledByCustomer) ...[
              CustomButton(
                text: 'Cancel Order',
                variant: ButtonVariant.secondary,
                isLoading: _isCancelling,
                onPressed: () => _handleCancelOrder(liveOrder),
              ),
              const SizedBox(height: AppTheme.space16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusStepper(OrderStatus status, bool isDark) {
    if (status == OrderStatus.cancelled) {
      final bannerBg = isDark ? const Color(0xFF2C1316) : const Color(0xFFFEF2F2);
      final bannerBorder = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA);
      final bannerFg = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C);
      final iconColor = isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626);

      return Container(
        padding: const EdgeInsets.all(AppTheme.space12),
        decoration: BoxDecoration(
          color: bannerBg,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(color: bannerBorder, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.cancel_outlined, color: iconColor, size: 20),
            const SizedBox(width: AppTheme.space8),
            Text(
              'This order was cancelled and closed.',
              style: TextStyle(color: bannerFg, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    final steps = [
      OrderStatus.pending,
      OrderStatus.processing,
      OrderStatus.shipped,
      OrderStatus.delivered,
    ];

    final currentIndex = steps.indexOf(status);

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector line
          final stepBefore = index ~/ 2;
          final isCompleted = currentIndex > stepBefore;
          return Expanded(
            child: Container(
              height: 2,
              color: isCompleted
                  ? (isDark ? AppTheme.darkAccent : AppTheme.lightAccent)
                  : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            ),
          );
        }

        final stepIndex = index ~/ 2;
        final isReached = currentIndex >= stepIndex;

        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isReached
                ? (isDark ? AppTheme.darkAccent : AppTheme.lightAccent)
                : (isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceWarm),
            border: Border.all(
              color: isReached
                  ? (isDark ? AppTheme.darkAccent : AppTheme.lightAccent)
                  : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              width: 1.5,
            ),
          ),
          child: Center(
            child: isReached
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : Text(
                    '${stepIndex + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
          ),
        );
      }),
    );
  }
}
