import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ecommerceapp/providers/auth_provider.dart';
import 'package:ecommerceapp/providers/cart_provider.dart';
import 'package:ecommerceapp/widgets/navigation/app_navigation_shell.dart';

class _FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  bool isAuthenticated = false;
  @override
  bool isAdmin = false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCartProvider extends ChangeNotifier implements CartProvider {
  @override
  int totalUnits = 0;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Tab Scroll-to-Top Behavior', () {
    testWidgets('Re-tapping current active tab scrolls screen back to top', (tester) async {
      final scrollController = ScrollController();

      final fakeAuth = _FakeAuthProvider();
      final fakeCart = _FakeCartProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: fakeAuth),
            ChangeNotifierProvider<CartProvider>.value(value: fakeCart),
          ],
          child: MaterialApp(
            home: AppNavigationShell(
              destinations: [
                ScrollToTopListener(
                  tabIndex: 0,
                  scrollController: scrollController,
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: 100,
                    itemBuilder: (ctx, idx) => SizedBox(height: 50, child: Text('Item $idx')),
                  ),
                ),
                const SizedBox(),
                const SizedBox(),
                const SizedBox(),
                const SizedBox(),
              ],
            ),
          ),
        ),
      );

      // Scroll down by 500 pixels
      scrollController.jumpTo(500);
      await tester.pumpAndSettle();
      expect(scrollController.offset, equals(500));

      // Re-tap the Home tab (index 0) while already on it
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      // Verify that offset was animated back to 0
      expect(scrollController.offset, equals(0));
    });
  });
}
