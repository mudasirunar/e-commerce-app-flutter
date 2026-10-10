import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerceapp/widgets/common/state_views.dart';

void main() {
  group('LoadingView Widget', () {
    testWidgets('renders spinner and optional message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingView(message: 'Fetching catalog...'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Fetching catalog...'), findsOneWidget);
    });
  });

  group('EmptyView Widget', () {
    testWidgets('renders icon, title, subtitle and action button', (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyView(
              icon: Icons.shopping_bag_outlined,
              title: 'Your cart is empty',
              subtitle: 'Discover our curated collection.',
              actionText: 'Explore Catalog',
              onAction: () => actionTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(find.text('Discover our curated collection.'), findsOneWidget);
      expect(find.text('Explore Catalog'), findsOneWidget);

      await tester.tap(find.text('Explore Catalog'));
      expect(actionTriggered, isTrue);
    });
  });

  group('ErrorView Widget', () {
    testWidgets('renders error icon, message and retry button', (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorView(
              message: 'Failed to load live data.',
              retryText: 'Retry Now',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.text('Failed to load live data.'), findsOneWidget);
      expect(find.text('Retry Now'), findsOneWidget);

      await tester.tap(find.text('Retry Now'));
      expect(retried, isTrue);
    });
  });

  group('SuccessView Widget', () {
    testWidgets('renders check icon, title, subtitle and action', (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SuccessView(
              title: 'Order Confirmed',
              subtitle: 'Your order has been recorded.',
              actionText: 'Track Order',
              onAction: () => actionTriggered = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.text('Order Confirmed'), findsOneWidget);
      expect(find.text('Your order has been recorded.'), findsOneWidget);
      expect(find.text('Track Order'), findsOneWidget);

      await tester.tap(find.text('Track Order'));
      expect(actionTriggered, isTrue);
    });
  });
}
