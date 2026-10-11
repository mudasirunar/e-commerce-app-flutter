import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerceapp/widgets/common/welcome_banner.dart';

void main() {
  group('WelcomeBanner Widget', () {
    testWidgets('renders customer new signup banner with waving hand', (tester) async {
      const bannerData = WelcomeBannerData(
        isNewSignup: true,
        name: 'Mudasir',
        isAdmin: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WelcomeBanner(data: bannerData),
          ),
        ),
      );

      expect(find.text('👋'), findsOneWidget);
      expect(find.text('Welcome, Mudasir!'), findsOneWidget);
      expect(find.text('Your account is ready. Enjoy your shopping!'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('extracts and shows only first name when full name is passed', (tester) async {
      const bannerData = WelcomeBannerData(
        isNewSignup: false,
        name: 'Mudasir Unar',
        isAdmin: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WelcomeBanner(data: bannerData),
          ),
        ),
      );

      expect(find.text('Welcome back, Mudasir!'), findsOneWidget);
      expect(find.textContaining('Unar'), findsNothing);
    });

    testWidgets('renders customer returning sign in banner', (tester) async {
      const bannerData = WelcomeBannerData(
        isNewSignup: false,
        name: 'Sara',
        isAdmin: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WelcomeBanner(data: bannerData),
          ),
        ),
      );

      expect(find.text('👋'), findsOneWidget);
      expect(find.text('Welcome back, Sara!'), findsOneWidget);
      expect(find.text('Great to have you back with us.'), findsOneWidget);
    });

    testWidgets('renders admin returning sign in banner', (tester) async {
      const bannerData = WelcomeBannerData(
        isNewSignup: false,
        name: 'Mudasir',
        isAdmin: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WelcomeBanner(data: bannerData),
          ),
        ),
      );

      expect(find.text('👋'), findsOneWidget);
      expect(find.text('Welcome back, Admin Mudasir!'), findsOneWidget);
      expect(find.text('Admin management controls are ready.'), findsOneWidget);
    });

    testWidgets('renders admin new signup banner', (tester) async {
      const bannerData = WelcomeBannerData(
        isNewSignup: true,
        name: 'Root',
        isAdmin: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WelcomeBanner(data: bannerData),
          ),
        ),
      );

      expect(find.text('Welcome, Admin Root!'), findsOneWidget);
      expect(find.text('Your administrative privileges are active.'), findsOneWidget);
    });

    testWidgets('clicking close button dismisses banner', (tester) async {
      bool dismissed = false;
      const bannerData = WelcomeBannerData(
        isNewSignup: false,
        name: 'Mudasir',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WelcomeBanner(
              data: bannerData,
              onDismissed: () => dismissed = true,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byIcon(Icons.close_rounded), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });

    testWidgets('auto-dismisses smoothly after 3 seconds', (tester) async {
      bool dismissed = false;
      const bannerData = WelcomeBannerData(
        isNewSignup: false,
        name: 'Mudasir',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WelcomeBanner(
              data: bannerData,
              onDismissed: () => dismissed = true,
            ),
          ),
        ),
      );

      // Advance through animation
      await tester.pump(const Duration(milliseconds: 500));
      expect(dismissed, isFalse);

      // Advance beyond 3 seconds timer
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });
  });
}
