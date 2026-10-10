import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../providers/admin_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../theme/app_theme.dart';
import 'admin_orders_screen.dart';
import 'admin_products_screen.dart';

/// Screen providing the main administration dashboard with key retail metrics
/// and navigation to product and order management.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final admin = context.watch<AdminProvider>();
    final catalog = context.watch<CatalogProvider>();

    final totalOrders = admin.allOrders.length;
    final pendingOrders = admin.allOrders.where((o) => o.status == OrderStatus.pending).length;
    final lowStockItems = catalog.allProducts.where((p) => p.isLowStock || p.isOutOfStock).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Operations'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20, vertical: AppTheme.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Store Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.space16),

            // Metrics row
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Orders',
                    value: '$totalOrders',
                    icon: Icons.receipt_long_outlined,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Pending',
                    value: '$pendingOrders',
                    icon: Icons.hourglass_top_rounded,
                    isDark: isDark,
                    color: AppTheme.warning,
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Low Stock',
                    value: '$lowStockItems',
                    icon: Icons.warning_amber_rounded,
                    isDark: isDark,
                    color: AppTheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space32),

            Text(
              'Management Modules',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.space16),

            _buildActionTile(
              context,
              title: 'Catalog & Inventory Management',
              subtitle: 'Update stock levels, pricing visibility, and catalog entries.',
              icon: Icons.inventory_2_outlined,
              isDark: isDark,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminProductsScreen()),
                );
              },
            ),
            const SizedBox(height: AppTheme.space12),

            _buildActionTile(
              context,
              title: 'Order Fulfillment & Lifecycle',
              subtitle: 'Advance order statuses through Pending, Processing, Shipped, Delivered.',
              icon: Icons.local_shipping_outlined,
              isDark: isDark,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required bool isDark,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceWarm,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color ?? (isDark ? AppTheme.darkAccent : AppTheme.lightAccent)),
          const SizedBox(height: AppTheme.space12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurfaceWarm,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppTheme.space16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
