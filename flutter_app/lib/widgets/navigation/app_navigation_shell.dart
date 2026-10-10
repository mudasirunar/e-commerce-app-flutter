import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cartProvider = context.watch<CartProvider>();
    final authProvider = context.watch<AuthProvider>();

    final cartUnits = cartProvider.totalUnits;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: widget.destinations,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        indicatorColor: isDark ? AppTheme.darkAccentContainer : AppTheme.lightAccentContainer,
        elevation: 2,
        height: 64,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Catalog',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: cartUnits > 0,
              label: Text('$cartUnits'),
              backgroundColor: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
              textColor: isDark ? Colors.black : Colors.white,
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: cartUnits > 0,
              label: Text('$cartUnits'),
              backgroundColor: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
              textColor: isDark ? Colors.black : Colors.white,
              child: const Icon(Icons.shopping_bag_rounded),
            ),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: authProvider.isAdmin,
              smallSize: 8,
              backgroundColor: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
              child: const Icon(Icons.person_outline_rounded),
            ),
            selectedIcon: Badge(
              isLabelVisible: authProvider.isAdmin,
              smallSize: 8,
              backgroundColor: isDark ? AppTheme.darkAccent : AppTheme.lightAccent,
              child: const Icon(Icons.person_rounded),
            ),
            label: authProvider.isAdmin ? 'Profile (Admin)' : 'Profile',
          ),
        ],
      ),
    );
  }
}
