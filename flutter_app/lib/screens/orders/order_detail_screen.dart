import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
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
  Timer? _snackBarTimer;
  ScaffoldMessengerState? _messenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    _snackBarTimer?.cancel();
    _messenger?.clearSnackBars();
    super.dispose();
  }

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

  List<String> _getAllowedNextStatuses(OrderStatus currentStatus) {
    switch (currentStatus) {
      case OrderStatus.pending:
        return ['Confirmed', 'Processing', 'Cancelled'];
      case OrderStatus.confirmed:
        return ['Processing', 'Cancelled'];
      case OrderStatus.processing:
        return ['Shipped', 'Cancelled'];
      case OrderStatus.shipped:
        return ['Delivered'];
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
        return [];
    }
  }

  Future<void> _handleAdminStatusChange(OrderModel order, String newStatus) async {
    final isCancel = newStatus.toLowerCase() == 'cancelled';
    final confirmed = await AppConfirmationDialog.show(
      context: context,
      title: 'Update to $newStatus?',
      message:
          'Are you sure you want to transition Order ${order.displayId} from ${order.status.value} to $newStatus?',
      icon: isCancel ? Icons.cancel_outlined : Icons.sync_alt_rounded,
      confirmLabel: 'Confirm',
      cancelLabel: 'Cancel',
      isDestructive: isCancel,
      onAsyncConfirm: () async {
        final admin = context.read<AdminProvider>();
        final success = await admin.updateOrderStatus(
          order.orderId,
          newStatus,
          note: 'Status advanced by administrator in order detail screen',
        );
        return success;
      },
    );

    if (confirmed == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Order status updated to $newStatus'),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _snackBarTimer?.cancel();
      _snackBarTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          messenger.clearSnackBars();
        }
      });
    }
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

    AuthProvider? auth;
    try {
      auth = context.watch<AuthProvider>();
    } catch (_) {}

    AdminProvider? adminProvider;
    try {
      adminProvider = context.watch<AdminProvider>();
    } catch (_) {}

    final isAdmin = auth?.isAdmin ?? false;

    OrderProvider? orderProvider;
    try {
      orderProvider = context.watch<OrderProvider>();
    } catch (_) {}

    final liveOrder = (isAdmin ? adminProvider?.getOrderById(widget.order.orderId) : null) ??
        orderProvider?.getOrderById(widget.order.orderId) ??
        widget.order;

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

            // Bottom Action Area: Admin Management Panel vs Customer Cancel
            if (isAdmin) ...[
              _buildAdminControlsCard(liveOrder, isDark),
              const SizedBox(height: AppTheme.space16),
            ] else if (liveOrder.canBeCancelledByCustomer) ...[
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

  Widget _buildAdminControlsCard(OrderModel liveOrder, bool isDark) {
    final accentColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final nextStatuses = _getAllowedNextStatuses(liveOrder.status);

    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? accentColor.withValues(alpha: 0.3)
              : accentColor.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.admin_panel_settings_rounded,
                        size: 20,
                        color: accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Admin Order Controls',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Fulfillment lifecycle',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF27272A) : const Color(0xFFF4EFEA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 12,
                      color: accentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Store Manager',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? const Color(0xFF2E2E34) : const Color(0xFFF0EFEB),
          ),
          const SizedBox(height: 14),

          // Action Section
          if (nextStatuses.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.swap_horiz_rounded,
                  size: 15,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Move order lifecycle to:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSymmetricalActionButtons(liveOrder, nextStatuses, isDark, accentColor),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFF5F5F4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 16,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This order is ${liveOrder.status.value}. No further status transitions are available.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSymmetricalActionButtons(
    OrderModel liveOrder,
    List<String> nextStatuses,
    bool isDark,
    Color accentColor,
  ) {
    final forwardStatuses = nextStatuses.where((s) => s.toLowerCase() != 'cancelled').toList();
    final hasCancel = nextStatuses.any((s) => s.toLowerCase() == 'cancelled');

    // Case 1: 2 forward statuses and 1 cancel (e.g., Pending -> Confirmed, Processing + Cancelled)
    if (forwardStatuses.length == 2 && hasCancel) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionButton(liveOrder, forwardStatuses[0], false, isDark, accentColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(liveOrder, forwardStatuses[1], false, isDark, accentColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: _buildActionButton(liveOrder, 'Cancelled', true, isDark, accentColor),
          ),
        ],
      );
    }

    // Case 2: 1 forward status and 1 cancel (e.g., Confirmed or Processing -> Next + Cancelled)
    if (forwardStatuses.length == 1 && hasCancel) {
      return Row(
        children: [
          Expanded(
            child: _buildActionButton(liveOrder, forwardStatuses[0], false, isDark, accentColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildActionButton(liveOrder, 'Cancelled', true, isDark, accentColor),
          ),
        ],
      );
    }

    // Case 3: 1 forward status only (e.g., Shipped -> Delivered)
    if (forwardStatuses.length == 1 && !hasCancel) {
      return SizedBox(
        width: double.infinity,
        child: _buildActionButton(liveOrder, forwardStatuses[0], false, isDark, accentColor),
      );
    }

    // Case 4: Cancel only
    if (forwardStatuses.isEmpty && hasCancel) {
      return SizedBox(
        width: double.infinity,
        child: _buildActionButton(liveOrder, 'Cancelled', true, isDark, accentColor),
      );
    }

    // Fallback: Equal-width row
    return Row(
      children: nextStatuses.map((target) {
        final isCancel = target.toLowerCase() == 'cancelled';
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildActionButton(liveOrder, target, isCancel, isDark, accentColor),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButton(
    OrderModel liveOrder,
    String target,
    bool isCancel,
    bool isDark,
    Color accentColor,
  ) {
    final color = isCancel ? const Color(0xFFEF4444) : accentColor;
    final isDelivered = target.toLowerCase() == 'delivered';

    final IconData icon = isCancel
        ? Icons.cancel_outlined
        : isDelivered
            ? Icons.check_circle_outline_rounded
            : Icons.arrow_forward_rounded;

    return OutlinedButton.icon(
      icon: Icon(
        icon,
        size: 15,
        color: color,
      ),
      label: Text(
        target,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        backgroundColor: color.withValues(alpha: isDark ? 0.08 : 0.05),
        side: BorderSide(
          color: color.withValues(alpha: 0.45),
          width: 1.2,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        minimumSize: const Size(0, 42),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: () => _handleAdminStatusChange(liveOrder, target),
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
