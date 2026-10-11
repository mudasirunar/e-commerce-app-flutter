import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/navigation/app_navigation_shell.dart';
import '../orders/order_detail_screen.dart';

/// Screen displayed immediately following confirmed server checkout.
class OrderConfirmedScreen extends StatelessWidget {
  final OrderModel order;

  const OrderConfirmedScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          AppNavigationShell.globalTabNotifier.value = 0;
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Order Confirmed'),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24, vertical: AppTheme.space32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Success check icon
                    Container(
                      height: 72,
                      width: 72,
                      decoration: const BoxDecoration(
                        color: AppTheme.successContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 40,
                        color: AppTheme.success,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space24),

                    Text(
                      'Thank You For Your Order',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space8),
                    Text(
                      'Your order ${order.displayId} has been placed and is currently pending fulfillment.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space32),

                    // Order Details Box
                    Container(
                      padding: const EdgeInsets.all(AppTheme.space20),
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
                                'Payment Method',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                ),
                              ),
                              const Text(
                                'Cash on Delivery (COD)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.space12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Amount',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                ),
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
                          const SizedBox(height: AppTheme.space12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Deliver To',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                ),
                              ),
                              Text(
                                order.deliveryName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.space32),

                    // Actions
                    CustomButton(
                      text: 'Track Order Status',
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => OrderDetailScreen(order: order),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppTheme.space12),
                    CustomButton(
                      text: 'Continue Shopping',
                      variant: ButtonVariant.secondary,
                      onPressed: () {
                        AppNavigationShell.globalTabNotifier.value = 0;
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
