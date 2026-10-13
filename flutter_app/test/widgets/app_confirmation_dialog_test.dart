import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerceapp/widgets/common/app_confirmation_dialog.dart';

void main() {
  group('AppConfirmationDialog - Synchronous mode (default for existing callers)', () {
    testWidgets('pops true immediately when confirm is pressed without onAsyncConfirm', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await AppConfirmationDialog.show(
                    context: context,
                    title: 'Sign Out?',
                    message: 'Are you sure you want to sign out?',
                    confirmLabel: 'Sign Out',
                    cancelLabel: 'Cancel',
                    isDestructive: true,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Sign Out?'), findsOneWidget);
      expect(find.text('Are you sure you want to sign out?'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap confirm
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      // Dialog is dismissed and result is true
      expect(find.text('Sign Out?'), findsNothing);
      expect(result, isTrue);
    });

    testWidgets('pops false immediately when cancel is pressed', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await AppConfirmationDialog.show(
                    context: context,
                    title: 'Clear Cart?',
                    message: 'Remove all items?',
                    confirmLabel: 'Clear',
                    cancelLabel: 'Keep',
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('Keep'));
      await tester.pumpAndSettle();

      expect(find.text('Clear Cart?'), findsNothing);
      expect(result, isFalse);
    });
  });

  group('AppConfirmationDialog - Asynchronous mode (with onAsyncConfirm)', () {
    testWidgets('shows loading spinner, disables buttons, and pops result upon completion', (tester) async {
      bool? result;
      final completer = Completer<bool?>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await AppConfirmationDialog.show(
                    context: context,
                    title: 'Update Status?',
                    message: 'Move order to Confirmed?',
                    confirmLabel: 'Confirm',
                    cancelLabel: 'Cancel',
                    onAsyncConfirm: () => completer.future,
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Update Status?'), findsOneWidget);

      // Tap Confirm to trigger async handler
      await tester.tap(find.text('Confirm'));
      await tester.pump(); // Start async action

      // CircularProgressIndicator should be visible now
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Cancel button should be disabled (onPressed is null)
      final cancelButton = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(cancelButton.onPressed, isNull);

      // Complete async handler
      completer.complete(true);
      await tester.pumpAndSettle();

      // Dialog dismissed and result is true
      expect(find.text('Update Status?'), findsNothing);
      expect(result, isTrue);
    });

    testWidgets('recovers gracefully if onAsyncConfirm throws an error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppConfirmationDialog.show(
                    context: context,
                    title: 'Fail Dialog',
                    message: 'Simulate network failure',
                    confirmLabel: 'Confirm',
                    onAsyncConfirm: () async {
                      throw Exception('Network failed');
                    },
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Tap Confirm
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      // Should recover from submitting state, spinner gone, buttons interactive again
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Fail Dialog'), findsOneWidget);

      final cancelButton = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(cancelButton.onPressed, isNotNull);
    });
  });
}
