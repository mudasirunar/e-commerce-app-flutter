import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ecommerceapp/models/category.dart';
import 'package:ecommerceapp/models/order.dart';
import 'package:ecommerceapp/models/product.dart';
import 'package:ecommerceapp/models/user_address.dart';
import 'package:ecommerceapp/models/user_profile.dart';
import 'package:ecommerceapp/providers/address_provider.dart';
import 'package:ecommerceapp/providers/auth_provider.dart';
import 'package:ecommerceapp/providers/cart_provider.dart';
import 'package:ecommerceapp/providers/catalog_provider.dart';
import 'package:ecommerceapp/providers/order_provider.dart';
import 'package:ecommerceapp/providers/theme_provider.dart';
import 'package:ecommerceapp/screens/home/home_screen.dart';
import 'package:ecommerceapp/screens/profile/profile_screen.dart';
import 'package:ecommerceapp/widgets/navigation/app_navigation_shell.dart';

class _FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  bool isAuthenticated = true;
  @override
  bool isAdmin = false;
  @override
  String displayName = 'Zainab Ahmed';
  @override
  String email = 'zainab@example.com';
  @override
  String uid = 'uid_zainab';
  @override
  UserProfile? profile;

  @override
  void clearError() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCatalogProvider extends ChangeNotifier implements CatalogProvider {
  @override
  bool get isLoading => false;
  @override
  String? get errorMessage => null;
  @override
  List<Category> get categories => const [
        Category(categoryId: 'cat_living', name: 'Living Room'),
      ];
  @override
  List<Product> get allProducts => const [];
  @override
  List<Product> get featuredProducts => const [];
  @override
  List<Product> get newProducts => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCartProvider extends ChangeNotifier implements CartProvider {
  @override
  int totalUnits = 2;
  @override
  String formattedTotal = 'PKR 3,000.00';
  @override
  bool isEmpty = false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeOrderProvider extends ChangeNotifier implements OrderProvider {
  @override
  List<OrderModel> get orders => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAddressProvider extends ChangeNotifier implements AddressProvider {
  @override
  int addressesCount = 1;
  @override
  UserAddress? defaultAddress = const UserAddress(
    id: 'addr_1',
    label: 'Home',
    fullName: 'Zainab',
    phone: '03001234567',
    address: 'Street 1',
    isDefault: true,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeThemeProvider extends ChangeNotifier implements ThemeProvider {
  @override
  ThemeMode themeMode = ThemeMode.system;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('HomeScreen Profile Avatar & Navigation Reposition', () {
    testWidgets('renders profile avatar with user initial in HomeScreen AppBar when authenticated', (tester) async {
      final fakeAuth = _FakeAuthProvider();
      final fakeCatalog = _FakeCatalogProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: fakeAuth),
            ChangeNotifierProvider<CatalogProvider>.value(value: fakeCatalog),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top AppBar title
      expect(find.text('E-Commerce App'), findsOneWidget);

      // Profile avatar button exists with 'Z' initial
      final avatarFinder = find.byKey(const ValueKey('home_profile_avatar'));
      expect(avatarFinder, findsOneWidget);
      expect(find.text('Z'), findsOneWidget);
    });

    testWidgets('renders guest silhouette icon in profile avatar when unauthenticated', (tester) async {
      final fakeAuth = _FakeAuthProvider()..isAuthenticated = false;
      final fakeCatalog = _FakeCatalogProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: fakeAuth),
            ChangeNotifierProvider<CatalogProvider>.value(value: fakeCatalog),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('home_profile_avatar')), findsOneWidget);
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    });

    testWidgets('tapping HomeScreen profile avatar navigates to ProfileScreen with back button', (tester) async {
      final fakeAuth = _FakeAuthProvider();
      final fakeCatalog = _FakeCatalogProvider();
      final fakeCart = _FakeCartProvider();
      final fakeOrder = _FakeOrderProvider();
      final fakeAddress = _FakeAddressProvider();
      final fakeTheme = _FakeThemeProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: fakeAuth),
            ChangeNotifierProvider<CatalogProvider>.value(value: fakeCatalog),
            ChangeNotifierProvider<CartProvider>.value(value: fakeCart),
            ChangeNotifierProvider<OrderProvider>.value(value: fakeOrder),
            ChangeNotifierProvider<AddressProvider>.value(value: fakeAddress),
            ChangeNotifierProvider<ThemeProvider>.value(value: fakeTheme),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap avatar
      await tester.tap(find.byKey(const ValueKey('home_profile_avatar')));
      await tester.pumpAndSettle();

      // Verify ProfileScreen is pushed
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('My Profile'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);

      // Tap back button
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Verify back on HomeScreen
      expect(find.byType(ProfileScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('AppNavigationShell renders exactly 4 bottom tabs without Profile tab', (tester) async {
      final fakeCart = _FakeCartProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CartProvider>.value(value: fakeCart),
          ],
          child: const MaterialApp(
            home: AppNavigationShell(
              destinations: [
                SizedBox(key: ValueKey('tab_0')),
                SizedBox(key: ValueKey('tab_1')),
                SizedBox(key: ValueKey('tab_2')),
                SizedBox(key: ValueKey('tab_3')),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify 4 tabs are present
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Catalog'), findsOneWidget);
      expect(find.text('Cart'), findsOneWidget);
      expect(find.text('Orders'), findsOneWidget);

      // Verify Profile tab is absent from bottom navigation
      expect(find.text('Profile'), findsNothing);
    });
  });
}
