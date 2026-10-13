import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../providers/admin_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/common/app_confirmation_dialog.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/orders/order_status_badge.dart';
import '../orders/order_detail_screen.dart';

/// Screen allowing administrators to review and advance order fulfillment states
/// across the backend-enforced order lifecycle state machine.
/// Features:
/// - Real-time search by Customer Name, Phone, or Order ID
/// - Modern filled filter tabs without checkmarks and live count badges
/// - Rich order cards with product image thumbnails and tap-to-inspect navigation
/// - In-dialog loader during status update with backdrop protection
/// - Auto-dismissing confirmation SnackBars
class AdminOrdersScreen extends StatefulWidget {
  final String initialFilter;
  const AdminOrdersScreen({super.key, this.initialFilter = 'All'});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  late String _selectedFilter;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _snackBarTimer;
  ScaffoldMessengerState? _messenger;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    _snackBarTimer?.cancel();
    _messenger?.clearSnackBars();
    _searchController.dispose();
    super.dispose();
  }

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

  Future<void> _handleStatusChange(OrderModel order, String newStatus) async {
    final confirmed = await AppConfirmationDialog.show(
      context: context,
      title: 'Update to $newStatus?',
      message:
          'Are you sure you want to transition Order ${order.displayId} from ${order.status.value} to $newStatus?',
      icon: Icons.sync_alt_rounded,
      confirmLabel: 'Confirm',
      cancelLabel: 'Cancel',
      isDestructive: newStatus.toLowerCase() == 'cancelled',
      onAsyncConfirm: () async {
        final admin = context.read<AdminProvider>();
        final success = await admin.updateOrderStatus(
          order.orderId,
          newStatus,
          note: 'Status advanced by administrator in admin portal',
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
          duration: const Duration(milliseconds: 2000),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      _snackBarTimer?.cancel();
      _snackBarTimer = Timer(const Duration(milliseconds: 2000), () {
        messenger.clearSnackBars();
      });
    } else if (confirmed == false && mounted) {
      final admin = context.read<AdminProvider>();
      if (admin.errorMessage != null) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Text(admin.errorMessage!),
            backgroundColor: AppTheme.error,
            duration: const Duration(milliseconds: 2500),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        _snackBarTimer?.cancel();
        _snackBarTimer = Timer(const Duration(milliseconds: 2500), () {
          messenger.clearSnackBars();
        });
      }
    }
  }

  int _countForFilter(List<OrderModel> allOrders, String filter) {
    if (filter == 'All') return allOrders.length;
    if (filter == 'Processing') {
      return allOrders.where((o) => o.status == OrderStatus.processing || o.status == OrderStatus.confirmed).length;
    }
    return allOrders.where((o) => o.status.value.toLowerCase() == filter.toLowerCase()).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final admin = context.watch<AdminProvider>();
    final allOrders = admin.allOrders;

    // Filter by Tab and Search Query
    final filteredOrders = allOrders.where((o) {
      // 1. Tab status match
      final matchesStatus = _selectedFilter == 'All' ||
          (_selectedFilter == 'Processing'
              ? (o.status == OrderStatus.processing || o.status == OrderStatus.confirmed)
              : o.status.value.toLowerCase() == _selectedFilter.toLowerCase());

      if (!matchesStatus) return false;

      // 2. Search query match
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return o.displayId.toLowerCase().contains(q) ||
          o.deliveryName.toLowerCase().contains(q) ||
          o.deliveryPhone.toLowerCase().contains(q) ||
          o.deliveryAddress.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders Management'),
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(AppTheme.space16, AppTheme.space8, AppTheme.space16, AppTheme.space12),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFF4EFEA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search by Customer, Phone, or Order ID...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // 2. Modern Filter Tabs (No checkmark, solid terracotta fill on selected)
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
              itemCount: _filters.length,
              separatorBuilder: (context, index) => const SizedBox(width: AppTheme.space8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter.toLowerCase() == filter.toLowerCase();
                final count = _countForFilter(allOrders, filter);
                final accentColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

                return ChoiceChip(
                  showCheckmark: false,
                  label: Text(
                    '$filter ($count)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: accentColor,
                  backgroundColor: isDark ? const Color(0xFF27272A) : const Color(0xFFF4EFEA),
                  side: BorderSide(
                    color: isSelected
                        ? accentColor
                        : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  onSelected: (_) => setState(() => _selectedFilter = filter),
                );
              },
            ),
          ),
          const SizedBox(height: AppTheme.space12),

          // 3. Orders List
          Expanded(
            child: admin.isLoading && admin.allOrders.isEmpty
                ? const LoadingView(message: 'Loading orders...')
                : filteredOrders.isEmpty
                    ? EmptyView(
                        icon: Icons.inbox_outlined,
                        title: 'No Orders Found',
                        subtitle: _searchQuery.isNotEmpty
                            ? 'No orders match "$_searchQuery".'
                            : 'No orders found for "$_selectedFilter".',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppTheme.space16,
                          0,
                          AppTheme.space16,
                          AppTheme.space24,
                        ),
                        itemCount: filteredOrders.length,
                        separatorBuilder: (context, index) => const SizedBox(height: AppTheme.space12),
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          final nextStatuses = _getAllowedNextStatuses(order.status);

                          return _AdminOrderCard(
                            order: order,
                            nextStatuses: nextStatuses,
                            isDark: isDark,
                            onStatusChange: (target) => _handleStatusChange(order, target),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => OrderDetailScreen(order: order),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

/// Rich, interactive retail command card for order management.
class _AdminOrderCard extends StatelessWidget {
  final OrderModel order;
  final List<String> nextStatuses;
  final bool isDark;
  final ValueChanged<String> onStatusChange;
  final VoidCallback onTap;

  const _AdminOrderCard({
    required this.order,
    required this.nextStatuses,
    required this.isDark,
    required this.onStatusChange,
    required this.onTap,
  });

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

  Widget _buildThumbnail(String? imageUrl, {required int quantity}) {
    Widget imageWidget;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        imageWidget = Image.network(
          imageUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackThumbnail(),
        );
      } else if (imageUrl.startsWith('assets/')) {
        imageWidget = Image.asset(
          imageUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackThumbnail(),
        );
      } else {
        imageWidget = Image.network(
          imageUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackThumbnail(),
        );
      }
    } else {
      imageWidget = _buildFallbackThumbnail();
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 50,
            height: 50,
            color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF4EFEA),
            child: imageWidget,
          ),
        ),
        if (quantity > 1)
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  width: 1.2,
                ),
              ),
              child: Text(
                'x$quantity',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFallbackThumbnail() {
    return Center(
      child: Icon(
        Icons.shopping_bag_outlined,
        size: 22,
        color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final accentColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Tappable Main Body (Opens OrderDetailScreen)
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Order ID, Date & Live Status Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            order.displayId,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 12,
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateFormatter.formatDate(order.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      OrderStatusBadge(status: order.status),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space12),

                  // Customer & Phone Info
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 16,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${order.deliveryName} • ${order.deliveryPhone}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Address Info
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          order.deliveryAddress,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Product Thumbnails Row / Carousel
                  if (order.items.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.space12),
                    SizedBox(
                      height: 54,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: order.items.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 10),
                        itemBuilder: (ctx, itemIdx) {
                          final item = order.items[itemIdx];
                          final imgUrl = _resolveItemImage(context, item);
                          return _buildThumbnail(imgUrl, quantity: item.quantity);
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: AppTheme.space12),

                  // Financial Summary & View Details Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF27272A) : const Color(0xFFF4EFEA),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${order.totalQuantity} items • COD',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            order.formattedTotal,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'Details',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: accentColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 2. Status Advancement Controls (Interactive)
          if (nextStatuses.isNotEmpty) ...[
            Divider(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              height: 1,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.swap_horiz_rounded,
                        size: 15,
                        color: accentColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Move status to:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: nextStatuses.map((target) {
                      final isCancel = target.toLowerCase() == 'cancelled';
                      final color = isCancel ? AppTheme.statusCancelled : accentColor;

                      return OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: color,
                          side: BorderSide(
                            color: color.withValues(alpha: 0.4),
                            width: 1,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          minimumSize: const Size(60, 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => onStatusChange(target),
                        child: Text(
                          target,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
