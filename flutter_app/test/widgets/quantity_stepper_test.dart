import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerceapp/widgets/common/quantity_stepper.dart';

void main() {
  group('QuantityStepper Widget', () {
    testWidgets('renders current value and buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuantityStepper(
              value: 3,
              max: 5,
              min: 1,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);
      expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });

    testWidgets('increments when add button tapped', (tester) async {
      int? updatedVal;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuantityStepper(
              value: 2,
              max: 5,
              min: 1,
              onChanged: (val) => updatedVal = val,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add_rounded));
      expect(updatedVal, equals(3));
    });

    testWidgets('decrements when remove button tapped', (tester) async {
      int? updatedVal;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuantityStepper(
              value: 2,
              max: 5,
              min: 1,
              onChanged: (val) => updatedVal = val,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.remove_rounded));
      expect(updatedVal, equals(1));
    });

    testWidgets('disables decrement at min value', (tester) async {
      int? updatedVal;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuantityStepper(
              value: 1,
              max: 5,
              min: 1,
              onChanged: (val) => updatedVal = val,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.remove_rounded));
      expect(updatedVal, isNull);
    });

    testWidgets('disables increment at max value', (tester) async {
      int? updatedVal;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuantityStepper(
              value: 5,
              max: 5,
              min: 1,
              onChanged: (val) => updatedVal = val,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add_rounded));
      expect(updatedVal, isNull);
    });
  });
}
