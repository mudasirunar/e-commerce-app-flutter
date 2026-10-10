import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerceapp/widgets/common/custom_button.dart';

void main() {
  group('CustomButton Widget', () {
    testWidgets('renders button text and triggers onPressed callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Add to Cart',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Add to Cart'), findsOneWidget);
      await tester.tap(find.byType(CustomButton));
      expect(tapped, isTrue);
    });

    testWidgets('shows loading spinner and disables tap when isLoading is true', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Submit',
              isLoading: true,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit'), findsNothing);

      await tester.tap(find.byType(CustomButton));
      expect(tapped, isFalse);
    });
  });
}
