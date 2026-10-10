import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/orders/order_status_badge.dart';

/// Screen allowing administrators to review and advance order fulfillment states
/// across the backend-enforced order lifecycle state machine.
class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  String _selectedFilter = 'All';

  final List<String> _filters = const [
    'All',
    'Pending',
    'Processing',
    'Shipped',
    'Delivered',
    'Cancelled',
  ];

  List<String> _getAllowedNextStatuses(OrderStatus currentStatus) {
    switch (currentStatus) {
      case OrderStatus.pending:
        return ['Processing', 'Cancelled'];
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

  Future<void> _handleStatusChange(OrderModel order, String newStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Update to $newStatus?'),
        content: Text(
          'Are you sure you want to transition Order #${order.orderId.substring(0, 8).toUpperCase()} from ${order.status.value} to $newStatus?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final admin = context.read<AdminProvider>();
      final success = await admin.updateOrderStatus(
        order.orderId,
        newStatus.toLowerCase(),
        note: 'Status advanced by administrator in admin portal',
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order status updated to $newStatus'),
              backgroundColor: AppTheme.success,
            ),
          );
        } else if (admin.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(admin.errorMessage!),
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
    final admin = context.watch<AdminProvider>();

    final orders = admin.allOrders.where((o) {
      if (_selectedFilter == 'All') return true;
      return o.status.value.toLowerCase() == _selectedFilter.toLowerCase();
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders Management'),
      ),
      body: Column(
        children: [
          // Filter horizontal list
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
              itemCount: _filters.length,
              separatorBuilder: (context, index) => const SizedBox(width: AppTheme.space8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedFilter = filter),
                );
              },
            ),
          ),
          const SizedBox(height: AppTheme.space8),

          Expanded(
            child: admin.isLoading && admin.allOrders.isEmpty
                ? const LoadingView(message: 'Loading orders...')
                : orders.isEmpty
                    ? EmptyView(
                        icon: Icons.inbox_outlined,
                        title: 'No Orders',
                        subtitle: 'No orders found for "$_selectedFilter".',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppTheme.space16),
                        itemCount: orders.length,
                        separatorBuilder: (context, index) => const SizedBox(height: AppTheme.space12),
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          final nextStatuses = _getAllowedNextStatuses(order.status);

                          return Container(
                            padding: const EdgeInsets.all(AppTheme.space16),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceWarm,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              border: Border.all(
                                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '#${order.orderId.substring(0, 8).toUpperCase()}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    OrderStatusBadge(status: order.status),
                                  ],
                                ),
                                const SizedBox(height: AppTheme.space8),

                                Text(
                                  'Customer: ${order.deliveryName} • ${order.deliveryPhone}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Address: ${order.deliveryAddress}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.space8),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${order.totalQuantity} items • Cash on Delivery',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      order.formattedTotal,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                                      ),
                                    ),
                                  ],
                                ),

                                if (nextStatuses.isNotEmpty) ...[
                                  const SizedBox(height: AppTheme.space12),
                                  Divider(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                                  const SizedBox(height: AppTheme.space8),
                                  Row(
                                    children: [
                                      Text(
                                        'Move status to: ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                        ),
                                      ),
                                      const Spacer(),
                                      ...nextStatuses.map((target) {
                                        return Padding(
                                          padding: const EdgeInsets.only(left: 8),
                                          child: OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              minimumSize: const Size(60, 32),
                                            ),
                                            onPressed: () => _handleStatusChange(order, target),
                                            child: Text(target, style: const TextStyle(fontSize: 12)),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ],
                              ],
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
