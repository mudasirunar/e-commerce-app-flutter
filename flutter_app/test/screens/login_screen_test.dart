import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ecommerceapp/models/user_profile.dart';
import 'package:ecommerceapp/providers/auth_provider.dart';
import 'package:ecommerceapp/screens/auth/login_screen.dart';
import 'package:ecommerceapp/widgets/common/custom_button.dart';

class TestAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  bool isLoading = false;

  @override
  String? errorMessage;

  @override
  bool isAuthenticated = false;

  @override
  bool isAdmin = false;

  @override
  String get email => 'test@example.com';

  @override
  String get uid => 'user_123';

  @override
  String get displayName => 'Test User';

  @override
  UserProfile? get profile => null;

  @override
  UserProfile? get userProfile => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  String? submittedEmail;
  String? submittedPassword;
  bool signInResult = true;

  @override
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    submittedEmail = email;
    submittedPassword = password;
    return signInResult;
  }
}

void main() {
  group('LoginScreen Widget', () {
    testWidgets('renders login fields and submits valid form', (tester) async {
      final fakeAuth = TestAuthProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: fakeAuth,
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign In'), findsWidgets);
      expect(find.byType(TextFormField), findsNWidgets(2));

      // Enter valid email and password
      await tester.enterText(find.byType(TextFormField).first, 'customer@boutique.pk');
      await tester.enterText(find.byType(TextFormField).last, 'secret123');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(CustomButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(fakeAuth.submittedEmail, equals('customer@boutique.pk'));
      expect(fakeAuth.submittedPassword, equals('secret123'));
    });

    testWidgets('displays error message from provider when login fails', (tester) async {
      final fakeAuth = TestAuthProvider()..errorMessage = 'Invalid email or password.';

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: fakeAuth,
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      expect(find.text('Invalid email or password.'), findsOneWidget);
    });
  });
}
