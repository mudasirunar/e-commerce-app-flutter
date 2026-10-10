import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/state_views.dart';
import '../../widgets/orders/order_card.dart';
import '../auth/login_screen.dart';
import '../catalog/catalog_screen.dart';
import 'order_detail_screen.dart';

/// Screen displaying the customer's chronological order history and status overview.
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
      ),
      body: !auth.isAuthenticated
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.space32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                    ),
                    const SizedBox(height: AppTheme.space16),
                    Text(
                      'Sign In to View Orders',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      'Sign in to see past purchases, shipment tracking, and item receipts.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space24),
                    CustomButton(
                      text: 'Sign In Now',
                      width: 180,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            )
          : orderProvider.isLoading && orderProvider.isEmpty
              ? const LoadingView(message: 'Loading your orders...')
              : orderProvider.errorMessage != null && orderProvider.isEmpty
                  ? ErrorView(
                      message: orderProvider.errorMessage!,
                      onRetry: () => auth.isAuthenticated ? orderProvider.updateAuth(auth.uid) : null,
                    )
                  : orderProvider.isEmpty
                      ? EmptyView(
                          icon: Icons.receipt_long_outlined,
                          title: 'No Orders Yet',
                          subtitle: 'You have not placed any boutique orders yet.',
                          actionText: 'Explore Gallery',
                          onAction: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const CatalogScreen()),
                            );
                          },
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(AppTheme.space16),
                          itemCount: orderProvider.orders.length,
                          separatorBuilder: (context, index) => const SizedBox(height: AppTheme.space12),
                          itemBuilder: (context, index) {
                            final order = orderProvider.orders[index];
                            return OrderCard(
                              order: order,
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
    );
  }
}
