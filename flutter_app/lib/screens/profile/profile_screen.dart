import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../providers/address_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_confirmation_dialog.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/navigation/app_navigation_shell.dart';
import '../../widgets/common/welcome_banner.dart';
import '../admin/admin_dashboard_screen.dart';
import '../auth/login_screen.dart';
import '../orders/order_detail_screen.dart';
import 'addresses_screen.dart';
import '../../utils/date_formatter.dart';

/// Redesigned Profile Screen adhering to Warm Earth & Terracotta aesthetics.
/// Features:
/// - Hero Account Header with editable Display Name (Firestore synchronized)
/// - Hidden Live Deliveries Hub (only surfaces when active orders exist)
/// - Asymmetrical Bento Grid with Shopping Bag, Delivery Address Book, Order History, and Theme Switcher
/// - Role-gated Admin Portal tile and clean confirmation sign-out.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _scrollController = ScrollController();
  final PageController _activeOrdersPageController = PageController(viewportFraction: 0.92);
  int _activeOrdersCurrentPage = 0;
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
    _scrollController.dispose();
    _activeOrdersPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final addressProvider = context.watch<AddressProvider>();
    final hasBottomBar = ShellNavigationScope.hasBottomBarOf(context);
    final bottomClearance = hasBottomBar ? 100.0 : 36.0;

    // Filter active orders: NOT delivered AND NOT cancelled
    final activeOrders = orderProvider.orders.where((o) {
      return o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled;
    }).toList();

    final completedOrdersCount = orderProvider.orders
        .where((o) => o.status == OrderStatus.delivered)
        .length;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkScaffold : AppTheme.lightScaffold,
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.3),
        ),
      ),
      body: ScrollToTopListener(
        tabIndex: 4,
        scrollController: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space20,
            vertical: AppTheme.space16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. User Account Card
              if (auth.isAuthenticated)
                _buildUserCard(context, auth, isDark)
              else
                _buildGuestCard(context, isDark),

              const SizedBox(height: AppTheme.space20),

              // 2. Active Orders Section (Only renders when active orders exist)
              if (auth.isAuthenticated && activeOrders.isNotEmpty) ...[
                _buildActiveOrdersSection(context, activeOrders, isDark),
                const SizedBox(height: AppTheme.space24),
              ],

              // 3. Section Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
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
                      'Account Overview',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.space12),

              // 4. Overview Grid
              _buildOverviewGrid(
                context,
                isDark: isDark,
                isAuthenticated: auth.isAuthenticated,
                cartItemCount: cart.totalUnits,
                cartFormattedTotal: cart.formattedTotal,
                isCartEmpty: cart.isEmpty,
                addressesCount: addressProvider.addressesCount,
                defaultAddress: addressProvider.defaultAddress,
                totalOrdersCount: orderProvider.orders.length,
                completedOrdersCount: completedOrdersCount,
                isAdmin: auth.isAdmin,
              ),

              const SizedBox(height: AppTheme.space20),

              // 5. Admin Portal Card (Role-Gated)
              if (auth.isAdmin) ...[
                _buildAdminTile(context, isDark),
                const SizedBox(height: AppTheme.space20),
              ],

              // 6. Sign Out Button
              if (auth.isAuthenticated) ...[
                _buildSignOutButton(context, auth, isDark),
                const SizedBox(height: AppTheme.space20),
              ],

              // 7. App Version Footer
              Center(
                child: Column(
                  children: [
                    Text(
                      'E-Commerce App',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        color: isDark
                            ? AppTheme.darkAccent.withValues(alpha: 0.6)
                            : AppTheme.lightAccent.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'v1.0.0',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppTheme.darkTextSecondary.withValues(alpha: 0.6)
                            : AppTheme.lightTextSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: bottomClearance),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== USER ACCOUNT CARD ====================

  Widget _buildUserCard(BuildContext context, AuthProvider auth, bool isDark) {
    final displayName = auth.displayName.isNotEmpty ? auth.displayName : 'Customer';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    final surfaceColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final accentColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;

    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFFC2410C).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Luxury Avatar with Terracotta Ring
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFFFB923C), const Color(0xFFC2410C)]
                    : [const Color(0xFFEA580C), const Color(0xFF9A3412)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space16),

          // User details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display Name with edit button
                InkWell(
                  onTap: () => _showEditNameDialog(context, displayName),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.darkAccentContainer
                                : AppTheme.lightAccentContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.edit_rounded,
                            size: 13,
                            color: isDark
                                ? AppTheme.darkOnAccentContainer
                                : AppTheme.lightOnAccentContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 3),

                // Email
                Text(
                  auth.email,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Role badge pill (Admin only; verified member chip removed)
                if (auth.isAdmin) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF431407) : const Color(0xFFFFEDD5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark ? const Color(0xFFFB923C) : const Color(0xFFEA580C),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.admin_panel_settings_rounded,
                              size: 12,
                              color: isDark ? const Color(0xFFFDBA74) : const Color(0xFF9A3412),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Store Administrator',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFFFDBA74) : const Color(0xFF9A3412),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder, width: 1.2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkAccentContainer : AppTheme.lightAccentContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline_rounded,
              size: 36,
              color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Welcome to E-Commerce App',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sign in to synchronize your artisanal bag, track live shipments, and manage saved delivery destinations.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 18),
          CustomButton(
            text: 'Sign In / Register',
            icon: Icons.login_rounded,
            onPressed: () {
              context.read<AuthProvider>().clearError();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==================== EDIT NAME DIALOG ====================

  void _showEditNameDialog(BuildContext context, String currentName) {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: currentName);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        final theme = Theme.of(dialogCtx);
        final isDark = theme.brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (ctx, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: isDark ? const Color(0xFF27272A) : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.darkAccentContainer
                                  : AppTheme.lightAccentContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.badge_outlined,
                              color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Edit Display Name',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              letterSpacing: -0.2,
                              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      CustomTextField(
                        controller: controller,
                        label: 'Full Name',
                        hint: 'Enter your name',
                        validator: (val) {
                          if (val == null || val.trim().length < 2) {
                            return 'Name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(dialogCtx).pop(),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: ElevatedButton(
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        if (!formKey.currentState!.validate()) return;
                                        setState(() => isSaving = true);
                                        final auth = context.read<AuthProvider>();
                                        final ok = await auth.updateDisplayName(controller.text.trim());
                                        if (!dialogCtx.mounted) return;
                                        setState(() => isSaving = false);
                                        if (ok) {
                                          Navigator.of(dialogCtx).pop();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Name updated successfully.'),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        } else {
                                          final err = auth.errorMessage ?? 'Failed to update name.';
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(err),
                                              backgroundColor: Colors.redAccent,
                                              duration: const Duration(seconds: 2),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: isSaving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Save',
                                        style: TextStyle(fontWeight: FontWeight.w700),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==================== ACTIVE ORDERS SECTION ====================

  Widget _buildActiveOrdersSection(
    BuildContext context,
    List<OrderModel> activeOrders,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'Active Deliveries',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFD97706).withValues(alpha: 0.4),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        '${activeOrders.length} in progress',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  AppNavigationShell.globalTabNotifier.value = 3; // Orders tab
                },
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Active Orders Carousel or Single Card
        if (activeOrders.length == 1)
          _ActiveOrderCard(order: activeOrders.first, isDark: isDark)
        else ...[
          SizedBox(
            height: 236,
            child: PageView.builder(
              controller: _activeOrdersPageController,
              itemCount: activeOrders.length,
              onPageChanged: (page) {
                if (mounted) setState(() => _activeOrdersCurrentPage = page);
              },
              itemBuilder: (ctx, index) {
                final order = activeOrders[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _ActiveOrderCard(order: order, isDark: isDark),
                );
              },
            ),
          ),

          // Carousel Page Dots
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(activeOrders.length, (idx) {
              final isCurrent = idx == _activeOrdersCurrentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isCurrent ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? (isDark ? AppTheme.darkAccent : AppTheme.lightAccent)
                      : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  static Color _getOrderStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.confirmed:
        return const Color(0xFFC2410C); // Terracotta
      case OrderStatus.processing:
        return const Color(0xFFD97706); // Amber
      case OrderStatus.shipped:
        return const Color(0xFF15803D); // Forest Green
      case OrderStatus.pending:
      default:
        return const Color(0xFFEA580C); // Warm Orange
    }
  }

  // ==================== OVERVIEW GRID ====================

  Widget _buildOverviewGrid(
    BuildContext context, {
    required bool isDark,
    required bool isAuthenticated,
    required int cartItemCount,
    required String cartFormattedTotal,
    required bool isCartEmpty,
    required int addressesCount,
    required dynamic defaultAddress,
    required int totalOrdersCount,
    required int completedOrdersCount,
    required bool isAdmin,
  }) {
    final themeProvider = context.watch<ThemeProvider>();

    final cardBg = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Column(
      children: [
        // Bento Item 1: Full-Width Prominent Shopping Bag Tile
        InkWell(
          onTap: () {
            if (isAuthenticated) {
              AppNavigationShell.globalTabNotifier.value = 2; // Cart tab
            } else {
              _promptSignIn(context);
            }
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.space16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFFC2410C).withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Prominent terracotta bag icon badge
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkAccentContainer : AppTheme.lightAccentContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      size: 24,
                      color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.space16),

                // Bag details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shopping Bag',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isCartEmpty ? 'Empty' : '$cartItemCount items',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isCartEmpty ? 'Tap to explore catalog' : cartFormattedTotal,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                        ),
                      ),
                    ],
                  ),
                ),

                // Forward pill button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3F3F46).withValues(alpha: 0.4) : const Color(0xFFF4EFEA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Go to Bag',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppTheme.space12),

        // Bento Row 2: Addresses & Order History Tiles
        Row(
          children: [
            // Left Tile: Saved Addresses
            Expanded(
              child: _buildGridTile(
                context,
                isDark: isDark,
                icon: Icons.location_on_outlined,
                iconColor: const Color(0xFFD97706),
                iconContainerColor: isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7),
                title: 'Addresses',
                mainStat: '$addressesCount Saved',
                subtitle: defaultAddress != null ? '${defaultAddress.label} (Default)' : 'Add address',
                onTap: () {
                  if (isAuthenticated) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddressesScreen()),
                    );
                  } else {
                    _promptSignIn(context);
                  }
                },
              ),
            ),
            const SizedBox(width: AppTheme.space12),

            // Right Tile: Order History
            Expanded(
              child: _buildGridTile(
                context,
                isDark: isDark,
                icon: Icons.receipt_long_outlined,
                iconColor: const Color(0xFF15803D),
                iconContainerColor: isDark ? const Color(0xFF052E16) : const Color(0xFFDCFCE7),
                title: 'Orders',
                mainStat: '$totalOrdersCount Total',
                subtitle: '$completedOrdersCount completed',
                onTap: () {
                  if (isAuthenticated) {
                    AppNavigationShell.globalTabNotifier.value = 3; // Orders tab
                  } else {
                    _promptSignIn(context);
                  }
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: AppTheme.space12),

        // Bento Row 3: Appearance & Theme Mode Full-Row Luxury Switcher
        Container(
          padding: const EdgeInsets.all(AppTheme.space16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFFC2410C).withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkAccentContainer : AppTheme.lightAccentContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.palette_outlined,
                        size: 20,
                        color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Theme',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          themeProvider.themeMode == ThemeMode.system
                              ? 'Auto (System Preference)'
                              : themeProvider.themeMode == ThemeMode.light
                                  ? 'Light Mode'
                                  : 'Dark Mode',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Full Row Theme Segmented Selector
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF18181B) : const Color(0xFFF4EFEA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor, width: 0.8),
                ),
                child: Row(
                  children: [
                    // System Option
                    Expanded(
                      child: _buildThemeSegmentOption(
                        label: 'System',
                        activeColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                        isSelected: themeProvider.themeMode == ThemeMode.system,
                        isDark: isDark,
                        onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                        animatedIcon: Icon(
                          Icons.brightness_auto_rounded,
                          size: 16,
                          color: themeProvider.themeMode == ThemeMode.system
                              ? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB))
                              : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Light Option
                    Expanded(
                      child: _buildThemeSegmentOption(
                        label: 'Light',
                        activeColor: const Color(0xFFF59E0B),
                        isSelected: themeProvider.themeMode == ThemeMode.light,
                        isDark: isDark,
                        onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                        animatedIcon: Icon(
                          Icons.wb_sunny_rounded,
                          size: 16,
                          color: themeProvider.themeMode == ThemeMode.light
                              ? const Color(0xFFF59E0B)
                              : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Dark Option
                    Expanded(
                      child: _buildThemeSegmentOption(
                        label: 'Dark',
                        activeColor: const Color(0xFFA78BFA),
                        isSelected: themeProvider.themeMode == ThemeMode.dark,
                        isDark: isDark,
                        onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                        animatedIcon: Icon(
                          Icons.nightlight_round,
                          size: 16,
                          color: themeProvider.themeMode == ThemeMode.dark
                              ? const Color(0xFFA78BFA)
                              : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGridTile(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required Color iconContainerColor,
    required String title,
    required String mainStat,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFFC2410C).withValues(alpha: 0.03),
              blurRadius: 10,
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconContainerColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: isDark ? AppTheme.darkTextSecondary.withValues(alpha: 0.6) : AppTheme.lightTextSecondary.withValues(alpha: 0.6),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              mainStat,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSegmentOption({
    required String label,
    required Color activeColor,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
    required Widget animatedIcon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF27272A) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(
                  color: isDark
                      ? activeColor.withValues(alpha: 0.4)
                      : activeColor.withValues(alpha: 0.3),
                  width: 1.2,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: isDark ? 0.22 : 0.14),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            animatedIcon,
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.white : AppTheme.lightTextPrimary)
                      : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== STORE ADMIN PORTAL TILE ====================

  Widget _buildAdminTile(BuildContext context, bool isDark) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF27272A), const Color(0xFF1E1E24)]
                : [const Color(0xFFFFFFFF), const Color(0xFFFBF8F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFFFB923C).withValues(alpha: 0.4) : const Color(0xFFEA580C).withValues(alpha: 0.3),
            width: 1.4,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkAccentContainer : AppTheme.lightAccentContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.admin_panel_settings_rounded,
                color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                size: 22,
              ),
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Operations Portal',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Manage inventory, categories, and store orders.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context, AuthProvider auth, bool isDark) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text(
          'Sign Out',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFB91C1C),
          side: BorderSide(
            color: const Color(0xFFB91C1C).withValues(alpha: 0.3),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () => _handleSignOut(context, auth),
      ),
    );
  }

  void _promptSignIn(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Please sign in to access this feature.'),
        duration: const Duration(milliseconds: 2500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: SnackBarAction(
          label: 'Sign In',
          textColor: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
          onPressed: () {
            messenger.clearSnackBars();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
        ),
      ),
    );

    _snackBarTimer?.cancel();
    _snackBarTimer = Timer(const Duration(milliseconds: 2500), () {
      messenger.clearSnackBars();
    });
  }

  Future<void> _handleSignOut(BuildContext context, AuthProvider auth) async {
    final confirmed = await AppConfirmationDialog.show(
      context: context,
      title: 'Sign Out?',
      message: 'Are you sure you want to sign out from your account?',
      icon: Icons.logout_rounded,
      confirmLabel: 'Sign Out',
      cancelLabel: 'Cancel',
      isDestructive: true,
    );

    if (confirmed == true) {
      final userName = auth.userProfile?.displayName ?? '';
      auth.clearError();
      await auth.signOut();

      if (!context.mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      AppNavigationShell.navigateToHomeFresh(
        banner: WelcomeBannerData.signOut(name: userName),
      );
    }
  }
}

class _ActiveOrderCard extends StatefulWidget {
  final OrderModel order;
  final bool isDark;

  const _ActiveOrderCard({
    required this.order,
    required this.isDark,
  });

  @override
  State<_ActiveOrderCard> createState() => _ActiveOrderCardState();
}

class _ActiveOrderCardState extends State<_ActiveOrderCard> {
  int _selectedItemIndex = 0;

  @override
  void didUpdateWidget(covariant _ActiveOrderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.orderId != widget.order.orderId) {
      _selectedItemIndex = 0;
    }
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

  Widget _buildProductThumbnail(
    String? imageUrl, {
    required double size,
    required bool isDark,
    double iconSize = 20,
    double borderRadius = 8,
  }) {
    Widget content;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        content = Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallback(isDark, iconSize),
        );
      } else if (imageUrl.startsWith('assets/')) {
        content = Image.asset(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallback(isDark, iconSize),
        );
      } else {
        content = Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallback(isDark, iconSize),
        );
      }
    } else {
      content = _buildFallback(isDark, iconSize);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: size,
        height: size,
        color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        child: content,
      ),
    );
  }

  Widget _buildFallback(bool isDark, double iconSize) {
    return Center(
      child: Icon(
        Icons.inventory_2_outlined,
        size: iconSize,
        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isDark = widget.isDark;
    final statusColor = _ProfileScreenState._getOrderStatusColor(order.status);
    final shortId = order.displayId;

    final items = order.items;
    final hasItems = items.isNotEmpty;
    final safeIndex = hasItems ? _selectedItemIndex.clamp(0, items.length - 1) : 0;
    final selectedItem = hasItems ? items[safeIndex] : null;

    return Container(
      height: 232,
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFFC2410C).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Row 1: Order ID, Date & Total items + Status Pill
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.local_shipping_outlined, size: 16, color: statusColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      shortId,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        letterSpacing: 0.4,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${DateFormatter.formatDate(order.createdAt)} • ${order.totalItemCount} ${order.totalItemCount == 1 ? 'item' : 'items'}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  order.status.value.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),

          // Row 2: Selected Item Preview Box
          if (selectedItem != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF18181B) : const Color(0xFFFAF7F5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  _buildProductThumbnail(
                    _resolveItemImage(context, selectedItem),
                    size: 48,
                    isDark: isDark,
                    iconSize: 20,
                    borderRadius: 8,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selectedItem.nameSnapshot,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.darkAccentContainer : AppTheme.lightAccentContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Qty: ${selectedItem.quantity}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppTheme.darkOnAccentContainer : AppTheme.lightOnAccentContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                selectedItem.formattedSubtotal,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              height: 56,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF18181B) : const Color(0xFFFAF7F5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 20,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Order Package',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Row 3: Multi-item selector OR Single-item Delivery detail (always exactly 34px)
          if (items.length > 1)
            Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF18181B).withValues(alpha: 0.6) : const Color(0xFFFAF7F5).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder.withValues(alpha: 0.6) : AppTheme.lightBorder.withValues(alpha: 0.6),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Items (${safeIndex + 1}/${items.length}):',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: items.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 6),
                      itemBuilder: (context, idx) {
                        final isChosen = idx == safeIndex;
                        final itm = items[idx];
                        return InkWell(
                          onTap: () {
                            setState(() => _selectedItemIndex = idx);
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isChosen
                                    ? (isDark ? AppTheme.darkAccent : AppTheme.lightAccent)
                                    : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                                width: isChosen ? 1.8 : 0.8,
                              ),
                            ),
                            child: _buildProductThumbnail(
                              _resolveItemImage(context, itm),
                              size: 26,
                              isDark: isDark,
                              iconSize: 12,
                              borderRadius: 5,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF18181B).withValues(alpha: 0.6) : const Color(0xFFFAF7F5).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder.withValues(alpha: 0.6) : AppTheme.lightBorder.withValues(alpha: 0.6),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.deliveryAddress.trim().isNotEmpty
                          ? 'Ship to: ${order.deliveryAddress.trim()}'
                          : 'Standard Express Delivery',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isDark ? AppTheme.darkAccent : AppTheme.lightAccent).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '1 Item Package',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Row 4: Bottom Price & Action Button
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Order Total',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                    Text(
                      order.formattedTotal,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: -0.2,
                        color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(order: order),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Track Order',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
