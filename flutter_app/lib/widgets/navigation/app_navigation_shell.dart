import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/catalog/catalog_screen.dart';
import '../../screens/cart/cart_screen.dart';
import '../../screens/orders/orders_screen.dart';
import '../common/welcome_banner.dart';
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
  final List<Widget>? destinations;
  final int initialIndex;
  final WelcomeBannerData? welcomeBanner;

  static final ValueNotifier<WelcomeBannerData?> globalBannerNotifier = ValueNotifier(null);
  static final ValueNotifier<int?> globalTabNotifier = ValueNotifier(null);

  static void showBanner(WelcomeBannerData data) {
    globalBannerNotifier.value = data;
  }

  static void navigateToHomeFresh({WelcomeBannerData? banner}) {
    if (banner != null) {
      globalBannerNotifier.value = banner;
    }
    globalTabNotifier.value = 0;
  }

  static void switchToTab(int index) {
    globalTabNotifier.value = index;
  }

  static List<Widget> get defaultDestinations => const [
    HomeScreen(),
    CatalogScreen(),
    CartScreen(),
    OrdersScreen(),
  ];

  const AppNavigationShell({
    super.key,
    this.destinations,
    this.initialIndex = 0,
    this.welcomeBanner,
  });

  @override
  State<AppNavigationShell> createState() => _AppNavigationShellState();
}

class _AppNavigationShellState extends State<AppNavigationShell> {
  late int _currentIndex;
  final ValueNotifier<TabReselectEvent?> _reselectNotifier = ValueNotifier(null);
  WelcomeBannerData? _bannerData;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _bannerData = widget.welcomeBanner ?? AppNavigationShell.globalBannerNotifier.value;
    AppNavigationShell.globalBannerNotifier.addListener(_onGlobalBanner);
    AppNavigationShell.globalTabNotifier.addListener(_onGlobalTab);
  }

  @override
  void dispose() {
    AppNavigationShell.globalBannerNotifier.removeListener(_onGlobalBanner);
    AppNavigationShell.globalTabNotifier.removeListener(_onGlobalTab);
    _reselectNotifier.dispose();
    super.dispose();
  }

  void _onGlobalBanner() {
    if (mounted && AppNavigationShell.globalBannerNotifier.value != null) {
      setState(() {
        _bannerData = AppNavigationShell.globalBannerNotifier.value;
      });
    }
  }

  void _onGlobalTab() {
    if (mounted && AppNavigationShell.globalTabNotifier.value != null) {
      final tab = AppNavigationShell.globalTabNotifier.value!;
      AppNavigationShell.globalTabNotifier.value = null;
      setState(() {
        _currentIndex = tab;
      });
      _reselectNotifier.value = TabReselectEvent(tab);
    }
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
    final cartProvider = Provider.of<CartProvider?>(context);
    final destinations = widget.destinations ?? AppNavigationShell.defaultDestinations;
    final cartUnits = cartProvider?.totalUnits ?? 0;

    return TabReselectScope(
      reselectNotifier: _reselectNotifier,
      child: ShellNavigationScope(
        hasBottomBar: true,
        child: Scaffold(
          extendBody: true,
          body: Stack(
            children: [
              IndexedStack(
                index: _currentIndex,
                children: destinations,
              ),
              if (_bannerData != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: WelcomeBanner(
                    data: _bannerData!,
                    onDismissed: () {
                      if (mounted) {
                        setState(() => _bannerData = null);
                      }
                    },
                  ),
                ),
            ],
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
            ],
          ),
        ),
      ),
    );
  }
}
