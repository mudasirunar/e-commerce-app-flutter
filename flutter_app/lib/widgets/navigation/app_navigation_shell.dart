import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import 'custom_bottom_bar.dart';

/// Scope informing descendant screens whether they are rendered inside the bottom navigation shell.
class ShellNavigationScope extends InheritedWidget {
  final bool hasBottomBar;

  const ShellNavigationScope({
    super.key,
    required this.hasBottomBar,
    required super.child,
  });

  static bool hasBottomBarOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ShellNavigationScope>()?.hasBottomBar ?? false;
  }

  @override
  bool updateShouldNotify(ShellNavigationScope oldWidget) => hasBottomBar != oldWidget.hasBottomBar;
}

/// Main navigation shell providing responsive bottom navigation, cart badges,
/// and role-gated admin access.
class AppNavigationShell extends StatefulWidget {
  final List<Widget> destinations;
  final int initialIndex;

  const AppNavigationShell({
    super.key,
    required this.destinations,
    this.initialIndex = 0,
  });

  @override
  State<AppNavigationShell> createState() => _AppNavigationShellState();
}

class _AppNavigationShellState extends State<AppNavigationShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final authProvider = context.watch<AuthProvider>();

    final cartUnits = cartProvider.totalUnits;

    return ShellNavigationScope(
      hasBottomBar: true,
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _currentIndex,
          children: widget.destinations,
        ),
        bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentIndex,
        onTabSelected: _onTabSelected,
        items: [
          const CustomBottomBarItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            label: 'Home',
          ),
          const CustomBottomBarItem(
            icon: Icons.grid_view_outlined,
            selectedIcon: Icons.grid_view_rounded,
            label: 'Catalog',
          ),
          CustomBottomBarItem(
            icon: Icons.shopping_bag_outlined,
            selectedIcon: Icons.shopping_bag_rounded,
            label: 'Cart',
            badgeCount: cartUnits,
          ),
          const CustomBottomBarItem(
            icon: Icons.receipt_long_outlined,
            selectedIcon: Icons.receipt_long_rounded,
            label: 'Orders',
          ),
          CustomBottomBarItem(
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
            label: authProvider.isAdmin ? 'Admin' : 'Profile',
            showBadgeDot: authProvider.isAdmin,
          ),
        ],
      ),
    ),
  );
}
}
