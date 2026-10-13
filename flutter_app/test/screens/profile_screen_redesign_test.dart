import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ecommerceapp/models/order.dart';
import 'package:ecommerceapp/models/user_address.dart';
import 'package:ecommerceapp/models/user_profile.dart';
import 'package:ecommerceapp/providers/address_provider.dart';
import 'package:ecommerceapp/providers/auth_provider.dart';
import 'package:ecommerceapp/providers/cart_provider.dart';
import 'package:ecommerceapp/providers/order_provider.dart';
import 'package:ecommerceapp/providers/theme_provider.dart';
import 'package:ecommerceapp/screens/profile/profile_screen.dart';

class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  bool isAuthenticated = true;
  @override
  bool isAdmin = false;
  @override
  String displayName = 'Ali Khan';
  @override
  String email = 'alex@example.com';
  @override
  String uid = 'uid_123';
  @override
  UserProfile? profile;

  String? updatedName;

  @override
  Future<bool> updateDisplayName(String newName) async {
    updatedName = newName;
    displayName = newName;
    notifyListeners();
    return true;
  }

  @override
  void clearError() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCartProvider extends ChangeNotifier implements CartProvider {
  @override
  int totalUnits = 3;
  @override
  String formattedTotal = 'PKR 4,500.00';
  @override
  bool isEmpty = false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockOrderProvider extends ChangeNotifier implements OrderProvider {
  @override
  List<OrderModel> orders = [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAddressProvider extends ChangeNotifier implements AddressProvider {
  @override
  int addressesCount = 1;
  @override
  UserAddress? defaultAddress = const UserAddress(
    id: 'addr_1',
    label: 'Home',
    fullName: 'Ali Khan',
    phone: '03001234567',
    address: 'Clifton Block 2',
    isDefault: true,
  );
  @override
  List<UserAddress> addresses = [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockThemeProvider extends ChangeNotifier implements ThemeProvider {
  @override
  ThemeMode themeMode = ThemeMode.system;

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget buildProfileScreenWidget({
  required MockAuthProvider auth,
  required MockCartProvider cart,
  required MockOrderProvider orderProvider,
  required MockAddressProvider addressProvider,
  required MockThemeProvider themeProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider<CartProvider>.value(value: cart),
      ChangeNotifierProvider<OrderProvider>.value(value: orderProvider),
      ChangeNotifierProvider<AddressProvider>.value(value: addressProvider),
      ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
    ],
    child: const MaterialApp(
      home: ProfileScreen(),
    ),
  );
}

void main() {
  late MockAuthProvider mockAuth;
  late MockCartProvider mockCart;
  late MockOrderProvider mockOrder;
  late MockAddressProvider mockAddress;
  late MockThemeProvider mockTheme;

  setUp(() {
    mockAuth = MockAuthProvider();
    mockCart = MockCartProvider();
    mockOrder = MockOrderProvider();
    mockAddress = MockAddressProvider();
    mockTheme = MockThemeProvider();
  });

  group('ProfileScreen Redesign', () {
    testWidgets('renders user header with name and bento cards', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildProfileScreenWidget(
        auth: mockAuth,
        cart: mockCart,
        orderProvider: mockOrder,
        addressProvider: mockAddress,
        themeProvider: mockTheme,
      ));
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Ali Khan'), findsOneWidget);
      expect(find.text('alex@example.com'), findsOneWidget);

      // Bento cards
      expect(find.text('Shopping Bag'), findsOneWidget);
      expect(find.text('3 items'), findsOneWidget);
      expect(find.text('Addresses'), findsOneWidget);
      expect(find.text('1 Saved'), findsOneWidget);
      expect(find.text('Home (Default)'), findsOneWidget);
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);

      // Active orders carousel is HIDDEN when no active orders
      expect(find.text('Active Deliveries'), findsNothing);
    });

    testWidgets('active orders carousel displays only when active orders exist', (tester) async {
      final activeOrder = OrderModel(
        orderId: 'ord_12345678',
        userId: 'uid_123',
        deliveryName: 'Ali Khan',
        deliveryPhone: '+923001234567',
        deliveryAddress: 'Clifton',
        status: OrderStatus.processing,
        subtotalMinor: 450000,
        deliveryFeeMinor: 0,
        totalMinor: 450000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        items: const [
          OrderItemSnapshot(
            productId: 'prod_1',
            nameSnapshot: 'Premium Leather Shoes',
            unitPriceMinorSnapshot: 450000,
            quantity: 1,
          ),
        ],
      );

      mockOrder.orders = [activeOrder];

      await tester.pumpWidget(buildProfileScreenWidget(
        auth: mockAuth,
        cart: mockCart,
        orderProvider: mockOrder,
        addressProvider: mockAddress,
        themeProvider: mockTheme,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Active Deliveries'), findsOneWidget);
      expect(find.text('1 in progress'), findsOneWidget);
      expect(find.text('#ORD_1234'), findsOneWidget);
      expect(find.text('PROCESSING'), findsOneWidget);
      expect(find.text('Track Order'), findsOneWidget);
    });

    testWidgets('multiple active orders render in PageView carousel and swipe smoothly on mobile viewport', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final order1 = OrderModel(
        orderId: 'ord_11111111',
        userId: 'uid_123',
        deliveryName: 'Ali Khan',
        deliveryPhone: '+923001234567',
        deliveryAddress: 'Clifton',
        status: OrderStatus.processing,
        subtotalMinor: 450000,
        deliveryFeeMinor: 0,
        totalMinor: 450000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        items: const [
          OrderItemSnapshot(
            productId: 'prod_1',
            nameSnapshot: 'Premium Leather Shoes',
            unitPriceMinorSnapshot: 450000,
            quantity: 1,
          ),
        ],
      );

      final order2 = OrderModel(
        orderId: 'ord_22222222',
        userId: 'uid_123',
        deliveryName: 'Ali Khan',
        deliveryPhone: '+923001234567',
        deliveryAddress: 'DHA',
        status: OrderStatus.shipped,
        subtotalMinor: 300000,
        deliveryFeeMinor: 20000,
        totalMinor: 320000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        items: const [
          OrderItemSnapshot(
            productId: 'prod_2',
            nameSnapshot: 'Silk Scarf',
            unitPriceMinorSnapshot: 300000,
            quantity: 1,
          ),
        ],
      );

      mockOrder.orders = [order1, order2];

      await tester.pumpWidget(buildProfileScreenWidget(
        auth: mockAuth,
        cart: mockCart,
        orderProvider: mockOrder,
        addressProvider: mockAddress,
        themeProvider: mockTheme,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Active Deliveries'), findsOneWidget);
      expect(find.text('2 in progress'), findsOneWidget);
      expect(find.text('#ORD_1111'), findsOneWidget);
      expect(find.byType(PageView), findsOneWidget);

      // Swipe to second order
      await tester.drag(find.byType(PageView), const Offset(-300, 0));
      await tester.pumpAndSettle();

      expect(find.text('#ORD_2222'), findsOneWidget);
      expect(find.text('SHIPPED'), findsOneWidget);
    });

    testWidgets('delivered and cancelled orders do NOT show in active carousel', (tester) async {
      final deliveredOrder = OrderModel(
        orderId: 'ord_delivered',
        userId: 'uid_123',
        deliveryName: 'Ali Khan',
        deliveryPhone: '+923001234567',
        deliveryAddress: 'Clifton',
        status: OrderStatus.delivered,
        subtotalMinor: 300000,
        deliveryFeeMinor: 0,
        totalMinor: 300000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        items: const [],
      );

      final cancelledOrder = OrderModel(
        orderId: 'ord_cancelled',
        userId: 'uid_123',
        deliveryName: 'Mudasir',
        deliveryPhone: '+923001234567',
        deliveryAddress: 'Clifton',
        status: OrderStatus.cancelled,
        subtotalMinor: 200000,
        deliveryFeeMinor: 0,
        totalMinor: 200000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        items: const [],
      );

      mockOrder.orders = [deliveredOrder, cancelledOrder];

      await tester.pumpWidget(buildProfileScreenWidget(
        auth: mockAuth,
        cart: mockCart,
        orderProvider: mockOrder,
        addressProvider: mockAddress,
        themeProvider: mockTheme,
      ));
      await tester.pumpAndSettle();

      // Active deliveries section must remain hidden
      expect(find.text('Active Deliveries'), findsNothing);
    });

    testWidgets('tapping display name opens edit name dialog and updates name', (tester) async {
      await tester.pumpWidget(buildProfileScreenWidget(
        auth: mockAuth,
        cart: mockCart,
        orderProvider: mockOrder,
        addressProvider: mockAddress,
        themeProvider: mockTheme,
      ));
      await tester.pumpAndSettle();

      // Tap on display name to open dialog
      await tester.tap(find.text('Ali Khan'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Display Name'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Enter new name
      await tester.enterText(find.byType(TextField), 'Ali Khan');
      await tester.pumpAndSettle();

      // Tap Save button
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(mockAuth.updatedName, 'Ali Khan');
      expect(find.text('Name updated successfully.'), findsOneWidget);
    });

    testWidgets('full-row theme selector renders System, Light, and Dark options and changes theme on tap', (tester) async {
      await tester.pumpWidget(buildProfileScreenWidget(
        auth: mockAuth,
        cart: mockCart,
        orderProvider: mockOrder,
        addressProvider: mockAddress,
        themeProvider: mockTheme,
      ));
      await tester.pumpAndSettle();

      // Theme card elements
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);

      // Tap Light mode
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      expect(mockTheme.themeMode, ThemeMode.light);

      // Tap Dark mode
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(mockTheme.themeMode, ThemeMode.dark);

      // Tap System mode
      await tester.tap(find.text('System'));
      await tester.pumpAndSettle();
      expect(mockTheme.themeMode, ThemeMode.system);
    });

    testWidgets('renders executive Admin Portal card above Account Overview when user is admin', (tester) async {
      mockAuth.isAdmin = true;

      await tester.pumpWidget(buildProfileScreenWidget(
        auth: mockAuth,
        cart: mockCart,
        orderProvider: mockOrder,
        addressProvider: mockAddress,
        themeProvider: mockTheme,
      ));
      await tester.pumpAndSettle();

      // Admin portal card elements
      expect(find.text('Admin Portal'), findsOneWidget);
      expect(find.text('CONTROL'), findsOneWidget);
      expect(find.text('Store Operations & Management'), findsOneWidget);
      expect(find.text('Inventory'), findsOneWidget);
      expect(find.text('Orders'), findsNWidgets(2)); // Capability pill + Bento orders tile
      expect(find.text('Pipeline'), findsOneWidget);

      // Verify it appears above Account Overview in the vertical layout
      final adminPortalTop = tester.getTopLeft(find.text('Admin Portal')).dy;
      final accountOverviewTop = tester.getTopLeft(find.text('Account Overview')).dy;
      expect(adminPortalTop, lessThan(accountOverviewTop));
    });
  });
}
