import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import 'custom_bottom_bar.dart';

/// Event dispatched when an active bottom tab is tapped again while standing on it.
class TabReselectEvent {
  final int tabIndex;
  final int timestamp;

  TabReselectEvent(this.tabIndex) : timestamp = DateTime.now().microsecondsSinceEpoch;
}

/// Scope providing notifications when a bottom navigation tab is re-tapped.
class TabReselectScope extends InheritedWidget {
  final ValueNotifier<TabReselectEvent?> reselectNotifier;

  const TabReselectScope({
    super.key,
    required this.reselectNotifier,
    required super.child,
  });

  static ValueNotifier<TabReselectEvent?>? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TabReselectScope>()?.reselectNotifier;
  }

  @override
  bool updateShouldNotify(TabReselectScope oldWidget) =>
      reselectNotifier != oldWidget.reselectNotifier;
}

/// Helper listener widget that automatically triggers scroll-to-top
/// or onScrollToTop callback when its associated tabIndex is re-tapped.
class ScrollToTopListener extends StatefulWidget {
  final int tabIndex;
  final ScrollController? scrollController;
  final VoidCallback? onScrollToTop;
  final Widget child;

  const ScrollToTopListener({
    super.key,
    required this.tabIndex,
    this.scrollController,
    this.onScrollToTop,
    required this.child,
  });

  @override
  State<ScrollToTopListener> createState() => _ScrollToTopListenerState();
}

class _ScrollToTopListenerState extends State<ScrollToTopListener> {
  ValueNotifier<TabReselectEvent?>? _notifier;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newNotifier = TabReselectScope.of(context);
    if (newNotifier != _notifier) {
      _notifier?.removeListener(_handleReselect);
      _notifier = newNotifier;
      _notifier?.addListener(_handleReselect);
    }
  }

  @override
  void dispose() {
    _notifier?.removeListener(_handleReselect);
    super.dispose();
  }

  void _handleReselect() {
    if (_notifier?.value?.tabIndex == widget.tabIndex) {
      if (widget.onScrollToTop != null) {
        widget.onScrollToTop!();
      } else if (widget.scrollController?.hasClients == true) {
        widget.scrollController!.animateTo(
          0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

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
/// scroll-to-top re-tap dispatching, and role-gated admin access.
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
  final ValueNotifier<TabReselectEvent?> _reselectNotifier = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    _reselectNotifier.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    } else {
      // Re-tapping current standing tab: notify listeners to scroll smoothly to top
      _reselectNotifier.value = TabReselectEvent(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final authProvider = context.watch<AuthProvider>();

    final cartUnits = cartProvider.totalUnits;

    return TabReselectScope(
      reselectNotifier: _reselectNotifier,
      child: ShellNavigationScope(
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
      ),
    );
  }
}
