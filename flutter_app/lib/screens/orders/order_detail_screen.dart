import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
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

  Future<void> _handleCancelOrder(OrderModel liveOrder) async {
    final confirmed = await AppConfirmationDialog.show(
      context: context,
      title: 'Cancel Order?',
      message:
          'Are you sure you want to cancel Order #${liveOrder.orderId.substring(0, 8).toUpperCase()}?\n\nReserved items will be restored to store inventory immediately.',
      icon: Icons.cancel_outlined,
      confirmLabel: 'Confirm Cancellation',
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order cancelled and inventory restored.'),
              backgroundColor: AppTheme.success,
            ),
          );
        } else if (orderProvider.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(orderProvider.errorMessage!),
              backgroundColor: AppTheme.error,
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
        title: Text('Order #${liveOrder.orderId.substring(0, 8).toUpperCase()}'),
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        child: Container(
                          height: 52,
                          width: 52,
                          color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
                          child: item.imageUrlSnapshot != null && item.imageUrlSnapshot!.isNotEmpty
                              ? Image.network(
                                  item.imageUrlSnapshot!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.chair_outlined),
                                )
                              : const Icon(Icons.chair_outlined),
                        ),
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
                                fontWeight: FontWeight.w600,
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
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
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
      return Container(
        padding: const EdgeInsets.all(AppTheme.space12),
        decoration: BoxDecoration(
          color: AppTheme.errorContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: AppTheme.error, size: 20),
            SizedBox(width: AppTheme.space8),
            Text(
              'This order was cancelled and closed.',
              style: TextStyle(color: AppTheme.error, fontSize: 13, fontWeight: FontWeight.w600),
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
