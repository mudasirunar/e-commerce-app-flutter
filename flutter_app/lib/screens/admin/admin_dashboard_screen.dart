import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../providers/admin_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_formatter.dart';
import '../../utils/money_formatter.dart';
import '../../widgets/orders/order_status_badge.dart';
import '../orders/order_detail_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_products_screen.dart';

/// Redesigned Admin Operations Dashboard with an executive GMV revenue hero card,
/// a high-information 3-card operations bento grid, order pipeline distribution analytics,
/// rich management modules with live status tags, and recent store activity stream.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final admin = context.watch<AdminProvider>();
    final catalog = context.watch<CatalogProvider>();

    final allOrders = admin.allOrders;
    final allProducts = catalog.allProducts;

    // Order status categories
    final totalOrders = allOrders.length;
    final pendingOrders = allOrders.where((o) => o.status == OrderStatus.pending).toList();
    final processingOrders = allOrders.where((o) => o.status == OrderStatus.processing || o.status == OrderStatus.confirmed).toList();
    final shippedOrders = allOrders.where((o) => o.status == OrderStatus.shipped).toList();
    final deliveredOrders = allOrders.where((o) => o.status == OrderStatus.delivered).toList();
    final cancelledOrders = allOrders.where((o) => o.status == OrderStatus.cancelled).toList();

    // Financial aggregates
    int totalVolumeMinor = 0;
    int deliveredRevenueMinor = 0;
    int pipelineRevenueMinor = 0;

    for (final o in allOrders) {
      if (o.status != OrderStatus.cancelled) {
        totalVolumeMinor += o.totalMinor;
        if (o.status == OrderStatus.delivered) {
          deliveredRevenueMinor += o.totalMinor;
        } else {
          pipelineRevenueMinor += o.totalMinor;
        }
      }
    }

    // Catalog & inventory analytics
    final totalProducts = allProducts.length;
    final outOfStockProducts = allProducts.where((p) => p.isOutOfStock).toList();
    final lowStockProducts = allProducts.where((p) => p.isLowStock && !p.isOutOfStock).toList();
    final stockAlertsCount = outOfStockProducts.length + lowStockProducts.length;

    // Recent orders (newest first)
    final recentOrders = List<OrderModel>.from(allOrders)
      ..sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
    final latestOrders = recentOrders.take(3).toList();

    final cardBg = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Operations'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space16,
          vertical: AppTheme.space20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Executive GMV Revenue Hero Card
            _buildRevenueHeroCard(
              context,
              isDark: isDark,
              totalVolumeMinor: totalVolumeMinor,
              deliveredRevenueMinor: deliveredRevenueMinor,
              pipelineRevenueMinor: pipelineRevenueMinor,
              totalOrdersCount: totalOrders,
            ),

            const SizedBox(height: AppTheme.space20),

            // 2. Operations Bento Grid (3 Enhanced Metric Cards)
            _buildSectionHeader(
              title: 'Store Performance',
              isDark: isDark,
            ),
            const SizedBox(height: AppTheme.space12),

            Row(
              children: [
                Expanded(
                  child: _buildBentoMetricCard(
                    context,
                    title: 'Total Orders',
                    value: '$totalOrders',
                    badgeText: '${deliveredOrders.length} Completed',
                    badgeColor: const Color(0xFF10B981),
                    icon: Icons.receipt_long_outlined,
                    iconContainerColor: isDark ? const Color(0xFF2C1E12) : const Color(0xFFFFF7ED),
                    iconColor: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminOrdersScreen(initialFilter: 'All'),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppTheme.space8),
                Expanded(
                  child: _buildBentoMetricCard(
                    context,
                    title: 'Pending Action',
                    value: '${pendingOrders.length}',
                    badgeText: pendingOrders.isNotEmpty ? 'Needs Review' : 'All Clear',
                    badgeColor: pendingOrders.isNotEmpty ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                    icon: Icons.hourglass_top_rounded,
                    iconContainerColor: isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7),
                    iconColor: const Color(0xFFD97706),
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminOrdersScreen(initialFilter: 'Pending'),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppTheme.space8),
                Expanded(
                  child: _buildBentoMetricCard(
                    context,
                    title: 'Stock Alerts',
                    value: '$stockAlertsCount',
                    badgeText: outOfStockProducts.isNotEmpty ? '${outOfStockProducts.length} Out' : '${lowStockProducts.length} Low',
                    badgeColor: outOfStockProducts.isNotEmpty ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                    icon: Icons.warning_amber_rounded,
                    iconContainerColor: isDark ? const Color(0xFF3B1214) : const Color(0xFFFEE2E2),
                    iconColor: const Color(0xFFEF4444),
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminProductsScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.space24),

            // 3. Pipeline Distribution Analytics Bar
            _buildPipelineAnalyticsCard(
              context,
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
              totalOrders: totalOrders,
              pendingCount: pendingOrders.length,
              processingCount: processingOrders.length,
              shippedCount: shippedOrders.length,
              deliveredCount: deliveredOrders.length,
              cancelledCount: cancelledOrders.length,
            ),

            const SizedBox(height: AppTheme.space24),

            // 4. Management Modules (The 2 Enhanced Command Modules)
            _buildSectionHeader(
              title: 'Management Modules',
              isDark: isDark,
            ),
            const SizedBox(height: AppTheme.space12),

            _buildModuleCard(
              context,
              title: 'Catalog & Inventory Management',
              subtitle: 'Update stock levels, price visibility, and catalog listings',
              icon: Icons.inventory_2_outlined,
              iconColor: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
              iconContainerColor: isDark ? AppTheme.darkAccentContainer : AppTheme.lightAccentContainer,
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
              tags: [
                _ModuleTag(
                  label: '$totalProducts Products',
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  bg: isDark ? const Color(0xFF3F3F46).withValues(alpha: 0.4) : const Color(0xFFF4EFEA),
                ),
                if (outOfStockProducts.isNotEmpty)
                  _ModuleTag(
                    label: '${outOfStockProducts.length} Out of Stock',
                    color: const Color(0xFFEF4444),
                    bg: isDark ? const Color(0xFF3B1214) : const Color(0xFFFEE2E2),
                  ),
                if (lowStockProducts.isNotEmpty)
                  _ModuleTag(
                    label: '${lowStockProducts.length} Low Stock',
                    color: const Color(0xFFD97706),
                    bg: isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7),
                  ),
              ],
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminProductsScreen()),
                );
              },
            ),

            const SizedBox(height: AppTheme.space12),

            _buildModuleCard(
              context,
              title: 'Order Fulfillment & Lifecycle',
              subtitle: 'Advance lifecycle: Pending → Confirmed → Shipped → Delivered',
              icon: Icons.local_shipping_outlined,
              iconColor: const Color(0xFF0D9488),
              iconContainerColor: isDark ? const Color(0xFF042F2E) : const Color(0xFFCCFBF1),
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
              tags: [
                _ModuleTag(
                  label: '${pendingOrders.length} New Orders',
                  color: pendingOrders.isNotEmpty ? const Color(0xFFD97706) : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                  bg: isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7),
                ),
                _ModuleTag(
                  label: '${shippedOrders.length} In Transit',
                  color: const Color(0xFF0D9488),
                  bg: isDark ? const Color(0xFF042F2E) : const Color(0xFFCCFBF1),
                ),
                _ModuleTag(
                  label: '${deliveredOrders.length} Delivered',
                  color: const Color(0xFF16A34A),
                  bg: isDark ? const Color(0xFF052E16) : const Color(0xFFDCFCE7),
                ),
              ],
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
                );
              },
            ),

            const SizedBox(height: AppTheme.space24),

            // 5. Recent Store Activity Stream (Latest 3 Orders)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader(
                  title: 'Recent Store Activity',
                  isDark: isDark,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminOrdersScreen(initialFilter: 'All')),
                    );
                  },
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 14),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space8),

            if (latestOrders.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppTheme.space20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 1.2),
                ),
                child: Center(
                  child: Text(
                    'No orders placed yet in the store.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                ),
              )
            else
              ...latestOrders.map((order) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.space8),
                  child: _buildRecentOrderTile(
                    context,
                    order: order,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                  ),
                );
              }),

            const SizedBox(height: AppTheme.space32),
          ],
        ),
      ),
    );
  }

  // ==================== SECTION HEADER ====================

  Widget _buildSectionHeader({
    required String title,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
        ),
      ],
    );
  }

  // ==================== REVENUE HERO CARD ====================

  Widget _buildRevenueHeroCard(
    BuildContext context, {
    required bool isDark,
    required int totalVolumeMinor,
    required int deliveredRevenueMinor,
    required int pipelineRevenueMinor,
    required int totalOrdersCount,
  }) {
    final gradientColors = isDark
        ? [const Color(0xFF33160C), const Color(0xFF1E0D07)]
        : [const Color(0xFFFFF7ED), const Color(0xFFFEEAD9)];

    final cardBorder = isDark
        ? const Color(0xFF7C2D12).withValues(alpha: 0.6)
        : const Color(0xFFFDBA74);

    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.4) : const Color(0xFFEA580C).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: badge & subtitle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkAccentContainer : AppTheme.lightAccentContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.insights_rounded,
                        size: 18,
                        color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'STORE VOLUME',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF27272A) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  'Cash on Delivery',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.space16),

          // Big Main GMV Figure
          Text(
            MoneyFormatter.format(totalVolumeMinor),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Gross sales from $totalOrdersCount non-cancelled store orders',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),

          const SizedBox(height: AppTheme.space16),
          Divider(
            color: isDark ? const Color(0xFF7C2D12).withValues(alpha: 0.3) : const Color(0xFFFDBA74).withValues(alpha: 0.5),
            height: 1,
          ),
          const SizedBox(height: AppTheme.space12),

          // Financial breakdown chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMiniFinancialPill(
                icon: Icons.check_circle_outline_rounded,
                label: 'Settled: ${MoneyFormatter.format(deliveredRevenueMinor)}',
                color: const Color(0xFF10B981),
                bg: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFD1FAE5),
              ),
              _buildMiniFinancialPill(
                icon: Icons.local_shipping_outlined,
                label: 'In Transit: ${MoneyFormatter.format(pipelineRevenueMinor)}',
                color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                bg: isDark ? const Color(0xFF451A03).withValues(alpha: 0.5) : const Color(0xFFFEF3C7),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniFinancialPill({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BENTO METRIC CARD ====================

  Widget _buildBentoMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String badgeText,
    required Color badgeColor,
    required IconData icon,
    required Color iconContainerColor,
    required Color iconColor,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Icon badge + forward arrow
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconContainerColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(icon, size: 16, color: iconColor),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: isDark ? AppTheme.darkTextSecondary.withValues(alpha: 0.4) : AppTheme.lightTextSecondary.withValues(alpha: 0.4),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Main Stat Value
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),

            const SizedBox(height: 2),

            // Metric Title
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),

            const SizedBox(height: 8),

            // Status Badge Chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badgeText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: badgeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== PIPELINE DISTRIBUTION ANALYTICS ====================

  Widget _buildPipelineAnalyticsCard(
    BuildContext context, {
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required int totalOrders,
    required int pendingCount,
    required int processingCount,
    required int shippedCount,
    required int deliveredCount,
    required int cancelledCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.timeline_rounded,
                    size: 18,
                    color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Fulfillment Pipeline',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '$totalOrders Orders Total',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.space12),

          // Multi-Segment Visual Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: totalOrders == 0
                  ? Container(color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7))
                  : Row(
                      children: [
                        if (pendingCount > 0)
                          Expanded(flex: pendingCount, child: Container(color: const Color(0xFFF59E0B))),
                        if (processingCount > 0)
                          Expanded(flex: processingCount, child: Container(color: const Color(0xFF6366F1))),
                        if (shippedCount > 0)
                          Expanded(flex: shippedCount, child: Container(color: const Color(0xFFEA580C))),
                        if (deliveredCount > 0)
                          Expanded(flex: deliveredCount, child: Container(color: const Color(0xFF10B981))),
                        if (cancelledCount > 0)
                          Expanded(flex: cancelledCount, child: Container(color: const Color(0xFF991B1B))),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: AppTheme.space12),

          // Interactive Status Pills
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildPipelineStatusChip(context, label: 'Pending', count: pendingCount, color: const Color(0xFFF59E0B), isDark: isDark),
              _buildPipelineStatusChip(context, label: 'Processing', count: processingCount, color: const Color(0xFF6366F1), isDark: isDark),
              _buildPipelineStatusChip(context, label: 'Shipped', count: shippedCount, color: const Color(0xFFEA580C), isDark: isDark),
              _buildPipelineStatusChip(context, label: 'Delivered', count: deliveredCount, color: const Color(0xFF10B981), isDark: isDark),
              _buildPipelineStatusChip(context, label: 'Cancelled', count: cancelledCount, color: const Color(0xFF991B1B), isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineStatusChip(
    BuildContext context, {
    required String label,
    required int count,
    required Color color,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AdminOrdersScreen(initialFilter: label)),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF27272A) : const Color(0xFFF4EFEA),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$label ($count)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== MANAGEMENT MODULE CARDS ====================

  Widget _buildModuleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconContainerColor,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required List<_ModuleTag> tags,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Icon Badge
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconContainerColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(icon, size: 22, color: iconColor),
              ),
            ),

            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Tag Row
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: tags.map((t) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: t.bg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          t.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: t.color,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Right Chevron
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== RECENT ORDER TILE ====================

  Widget _buildRecentOrderTile(
    BuildContext context, {
    required OrderModel order,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
  }) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          children: [
            // Left info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        order.displayId,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormatter.formatDate(order.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${order.deliveryName} • ${order.totalQuantity} item(s)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Right amount & status badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  order.formattedTotal,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                  ),
                ),
                const SizedBox(height: 4),
                OrderStatusBadge(status: order.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleTag {
  final String label;
  final Color color;
  final Color bg;

  const _ModuleTag({
    required this.label,
    required this.color,
    required this.bg,
  });
}
