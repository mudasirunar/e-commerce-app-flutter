import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerceapp/widgets/common/custom_text_field.dart';

void main() {
  group('CustomTextField Error & Typing Reset Behavior', () {
    testWidgets(
      'error appears only on button press, persists on focus, clears on typing/deletion for that field only, and re-triggers on button press',
      (WidgetTester tester) async {
        final formKey = GlobalKey<FormState>();
        final emailController = TextEditingController();
        final passwordController = TextEditingController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Form(
                key: formKey,
                child: Column(
                  children: [
                    CustomTextField(
                      controller: emailController,
                      label: 'Email',
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!val.contains('@')) {
                          return 'Invalid email format';
                        }
                        return null;
                      },
                    ),
                    CustomTextField(
                      controller: passwordController,
                      label: 'Password',
                      validator: (val) {
                        if (val == null || val.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    ElevatedButton(
                      onPressed: () {
                        formKey.currentState!.validate();
                      },
                      child: const Text('Submit'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // 1. Initial state: clean fields, no errors displayed
        expect(find.text('Email is required'), findsNothing);
        expect(find.text('Password must be at least 6 characters'), findsNothing);

        // 2. Tap Submit button: errors appear for both fields
        await tester.tap(find.text('Submit'));
        await tester.pumpAndSettle();

        expect(find.text('Email is required'), findsOneWidget);
        expect(find.text('Password must be at least 6 characters'), findsOneWidget);

        // 3. User taps/focuses the Email text field: error MUST NOT disappear on focus
        await tester.tap(find.widgetWithText(CustomTextField, 'Email'));
        await tester.pumpAndSettle();

        expect(find.text('Email is required'), findsOneWidget);
        expect(find.text('Password must be at least 6 characters'), findsOneWidget);

        // 4. User starts typing in Email field: error on Email disappears immediately
        await tester.enterText(find.widgetWithText(CustomTextField, 'Email'), 'a');
        await tester.pumpAndSettle();

        expect(find.text('Email is required'), findsNothing);
        expect(find.text('Invalid email format'), findsNothing);
        // Password field was NOT edited: its error MUST remain visible
        expect(find.text('Password must be at least 6 characters'), findsOneWidget);

        // 5. User removes/deletes the text in Email field (backspace): error stays gone while editing
        await tester.enterText(find.widgetWithText(CustomTextField, 'Email'), '');
        await tester.pumpAndSettle();

        expect(find.text('Email is required'), findsNothing);
        expect(find.text('Password must be at least 6 characters'), findsOneWidget);

        // 6. User re-taps Submit button: error on Email re-triggers because it is still empty
        await tester.tap(find.text('Submit'));
        await tester.pumpAndSettle();

        expect(find.text('Email is required'), findsOneWidget);
        expect(find.text('Password must be at least 6 characters'), findsOneWidget);

        // 7. User types in Password field: error on Password disappears immediately
        await tester.enterText(find.widgetWithText(CustomTextField, 'Password'), '123');
        await tester.pumpAndSettle();

        expect(find.text('Password must be at least 6 characters'), findsNothing);
        // Email field still has its error from the previous submit
        expect(find.text('Email is required'), findsOneWidget);
      },
    );

    testWidgets(
      'external errorText disappears immediately when user edits the text field',
      (WidgetTester tester) async {
        final controller = TextEditingController();
        String? externalError = 'Invalid verification code';

        late StateSetter setStateCallback;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                setStateCallback = setState;
                return Scaffold(
                  body: CustomTextField(
                    controller: controller,
                    label: 'Code',
                    errorText: externalError,
                  ),
                );
              },
            ),
          ),
        );

        // Initially displays external error
        expect(find.text('Invalid verification code'), findsOneWidget);

        // Focus does NOT remove external error
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();
        expect(find.text('Invalid verification code'), findsOneWidget);

        // Typing removes external error immediately
        await tester.enterText(find.byType(TextField), '123456');
        await tester.pumpAndSettle();
        expect(find.text('Invalid verification code'), findsNothing);

        // Re-triggering external error from parent brings it back
        setStateCallback(() {
          externalError = 'Expired code';
        });
        await tester.pumpAndSettle();
        expect(find.text('Expired code'), findsOneWidget);
      },
    );
  });
}
