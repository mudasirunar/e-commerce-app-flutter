import 'package:ecommerceapp/widgets/navigation/custom_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CustomBottomBar Widget', () {
    testWidgets('renders all tabs and highlights selected tab', (tester) async {
      int selected = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: StatefulBuilder(
              builder: (context, setState) {
                return CustomBottomBar(
                  currentIndex: selected,
                  onTabSelected: (idx) {
                    setState(() => selected = idx);
                  },
                  items: const [
                    CustomBottomBarItem(
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home_rounded,
                      label: 'Home',
                    ),
                    CustomBottomBarItem(
                      icon: Icons.grid_view_outlined,
                      selectedIcon: Icons.grid_view_rounded,
                      label: 'Catalog',
                    ),
                    CustomBottomBarItem(
                      icon: Icons.shopping_bag_outlined,
                      selectedIcon: Icons.shopping_bag_rounded,
                      label: 'Cart',
                      badgeCount: 3,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Verify labels and badge
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Catalog'), findsOneWidget);
      expect(find.text('Cart'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      // Tap catalog tab
      await tester.tap(find.text('Catalog'));
      await tester.pumpAndSettle();

      expect(selected, equals(1));
    });
  });
}
