import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cart/cart_item_tile.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/state_views.dart';
import '../auth/login_screen.dart';
import '../catalog/catalog_screen.dart';
import '../checkout/checkout_screen.dart';

/// Screen displaying the customer's persistent shopping bag, item quantities,
/// stock validation warnings, and authoritative delivery/subtotal calculations.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Bag'),
        actions: [
          if (cart.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear Bag',
              onPressed: () => _confirmClearCart(context, cart),
            ),
        ],
      ),
      body: !auth.isAuthenticated
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.space32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 64,
                      color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                    ),
                    const SizedBox(height: AppTheme.space16),
                    Text(
                      'Sign In to View Bag',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      'Your cart items are synchronized with your account for seamless shopping.',
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
          : cart.isLoading && cart.isEmpty
              ? const LoadingView(message: 'Loading your shopping bag...')
              : cart.isEmpty
                  ? EmptyView(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Your Bag is Empty',
                      subtitle: 'Explore our curated boutique collection to find handcrafted furniture and decor.',
                      actionText: 'Explore Collection',
                      onAction: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CatalogScreen()),
                        );
                      },
                    )
                  : Column(
                      children: [
                        // Stock warning banner if any item exceeds inventory
                        if (cart.hasStockErrors || cart.hasUnavailableItems) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.space16,
                              vertical: AppTheme.space12,
                            ),
                            color: AppTheme.warningContainer,
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 20),
                                const SizedBox(width: AppTheme.space8),
                                const Expanded(
                                  child: Text(
                                    'One or more items in your bag exceed available inventory. Please adjust quantities before checkout.',
                                    style: TextStyle(
                                      color: Color(0xFF92400E),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Items list
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(AppTheme.space16),
                            itemCount: cart.items.length,
                            separatorBuilder: (context, index) => const SizedBox(height: AppTheme.space12),
                            itemBuilder: (context, index) {
                              final item = cart.items[index];
                              return CartItemTile(
                                item: item,
                                onQuantityChanged: (newQty) {
                                  cart.updateQuantity(item.productId, newQty);
                                },
                                onRemove: () {
                                  cart.removeItem(item.productId);
                                },
                              );
                            },
                          ),
                        ),

                        // Order Summary & Checkout Bottom Sheet
                        _buildCartSummary(context, cart, isDark),
                      ],
                    ),
    );
  }

  Widget _buildCartSummary(BuildContext context, CartProvider cart, bool isDark) {
    final canCheckout = !cart.isEmpty && !cart.hasStockErrors && !cart.hasUnavailableItems;

    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightBackground,
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Subtotal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal (${cart.totalUnits} items)',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
                Text(
                  cart.formattedSubtotal,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space8),

            // Delivery
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Standard Delivery',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
                Text(
                  cart.formattedDeliveryFee,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cart.deliveryFeeMinor == 0
                        ? AppTheme.success
                        : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space12),

            Divider(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            const SizedBox(height: AppTheme.space12),

            // Grand Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
                Text(
                  cart.formattedTotal,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space16),

            // Checkout CTA
            CustomButton(
              text: canCheckout ? 'Proceed to Checkout' : 'Resolve Stock Before Checkout',
              onPressed: canCheckout
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                      );
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearCart(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Shopping Bag?'),
        content: const Text('Are you sure you want to remove all items from your bag?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () {
              cart.clearCart();
              Navigator.of(ctx).pop();
            },
            child: const Text('Clear Bag'),
          ),
        ],
      ),
    );
  }
}
