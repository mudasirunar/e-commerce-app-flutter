import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecommerceapp/models/delivery_info.dart';
import 'package:ecommerceapp/models/user_profile.dart';
import 'package:ecommerceapp/providers/address_provider.dart';
import 'package:ecommerceapp/providers/auth_provider.dart';
import 'package:ecommerceapp/providers/cart_provider.dart';
import 'package:ecommerceapp/providers/checkout_provider.dart';
import 'package:ecommerceapp/screens/checkout/checkout_screen.dart';
import 'package:ecommerceapp/services/firestore/firestore_service.dart';
import 'package:ecommerceapp/services/local/local_storage_service.dart';

class FakeFirestoreService extends FirestoreService {
  @override
  Future<void> updateDeliveryProfile({
    required String uid,
    required String defaultAddress,
    required String phone,
  }) async {}
}

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  UserProfile? _profile;

  @override
  UserProfile? get userProfile => _profile;

  void setTestProfile(UserProfile? p) {
    _profile = p;
    notifyListeners();
  }

  @override
  Future<bool> updateDeliveryProfile({
    String? defaultAddress,
    DeliveryInfo? defaultDeliveryInfo,
    String? phone,
  }) async {
    if (_profile != null && defaultDeliveryInfo != null) {
      _profile = _profile!.copyWith(
        phone: defaultDeliveryInfo.phone,
        defaultAddress: defaultDeliveryInfo.address,
      );
      notifyListeners();
    }
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCartProvider extends ChangeNotifier implements CartProvider {
  @override
  int get totalUnits => 2;

  @override
  String get formattedSubtotal => 'PKR 2,400';

  @override
  String get formattedDeliveryFee => 'Free';

  @override
  int get deliveryFeeMinor => 0;

  @override
  String get formattedTotal => 'PKR 2,400';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCheckoutProvider extends ChangeNotifier implements CheckoutProvider {
  @override
  bool get isSubmitting => false;

  @override
  String? get errorMessage => null;

  DeliveryInfo _info = const DeliveryInfo(fullName: '', phone: '', address: '', city: 'Karachi');
  @override
  DeliveryInfo get deliveryInfo => _info;

  @override
  void updateDeliveryInfo(DeliveryInfo info) {
    _info = info;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget buildTestableCheckoutScreen({
  required AddressProvider addressProvider,
  required FakeAuthProvider authProvider,
  required FakeCartProvider cartProvider,
  required FakeCheckoutProvider checkoutProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AddressProvider>.value(value: addressProvider),
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
      ChangeNotifierProvider<CheckoutProvider>.value(value: checkoutProvider),
    ],
    child: const MaterialApp(
      home: CheckoutScreen(),
    ),
  );
}

void main() {
  late LocalStorageService localStorage;
  late FakeFirestoreService fakeFirestore;
  late AddressProvider addressProvider;
  late FakeAuthProvider authProvider;
  late FakeCartProvider cartProvider;
  late FakeCheckoutProvider checkoutProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    localStorage = LocalStorageService(prefs);
    fakeFirestore = FakeFirestoreService();
    addressProvider = AddressProvider(fakeFirestore, localStorage);
    authProvider = FakeAuthProvider();
    cartProvider = FakeCartProvider();
    checkoutProvider = FakeCheckoutProvider();
  });

  group('CheckoutScreen Delivery & Address Selection', () {
    testWidgets('Case 1 (0 Addresses): displays empty form with visible Save as default checkbox', (tester) async {
      authProvider.setTestProfile(
        UserProfile(
          uid: 'user_123',
          name: 'Mudasir Customer',
          email: 'test@example.com',
          phone: '',
          defaultAddress: '',
        ),
      );
      addressProvider.updateAuth('user_123', null);

      await tester.pumpWidget(
        buildTestableCheckoutScreen(
          addressProvider: addressProvider,
          authProvider: authProvider,
          cartProvider: cartProvider,
          checkoutProvider: checkoutProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Recipient name prefilled from profile
      expect(find.text('Mudasir Customer'), findsOneWidget);

      // Save as default checkbox is visible when 0 addresses saved
      expect(find.text('Save as my default delivery address'), findsOneWidget);

      // No preview card or change address button since address book is empty
      expect(find.text('DEFAULT'), findsNothing);
      expect(find.text('Change'), findsNothing);
    });

    testWidgets('Case 2 (1 Address): auto-fills default address, shows preview card with DEFAULT badge, and HIDES save checkbox', (tester) async {
      authProvider.setTestProfile(
        UserProfile(
          uid: 'user_123',
          name: 'Mudasir Customer',
          email: 'test@example.com',
          phone: '+923001234567',
          defaultAddress: 'House 1, Street 2',
        ),
      );
      addressProvider.updateAuth('user_123', null);
      await addressProvider.addAddress(
        label: 'Home',
        fullName: 'Mudasir Customer',
        phone: '03001234567',
        address: 'House 1, Street 2, Clifton',
        city: 'Karachi',
        isDefault: true,
      );

      await tester.pumpWidget(
        buildTestableCheckoutScreen(
          addressProvider: addressProvider,
          authProvider: authProvider,
          cartProvider: cartProvider,
          checkoutProvider: checkoutProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Form is auto-filled
      expect(find.text('House 1, Street 2, Clifton'), findsWidgets);

      // Destination card renders Home with DEFAULT badge
      expect(find.text('DEFAULT'), findsOneWidget);

      // Checkbox is HIDDEN since this address is already their saved default
      expect(find.text('Save as my default delivery address'), findsNothing);
      expect(find.text('Save as default in my address book'), findsNothing);
    });

    testWidgets('Case 3 (Multiple Addresses): opens bottom sheet with all addresses and lets user switch without showing save checkbox', (tester) async {
      addressProvider.updateAuth('user_123', null);
      await addressProvider.addAddress(
        label: 'Home',
        fullName: 'Mudasir Home',
        phone: '03001111111',
        address: 'Clifton House 12',
        city: 'Karachi',
        isDefault: true,
      );
      await addressProvider.addAddress(
        label: 'Work',
        fullName: 'Mudasir Work',
        phone: '03002222222',
        address: 'I.I Chundrigar Tower 5',
        city: 'Karachi',
        isDefault: false,
      );

      await tester.pumpWidget(
        buildTestableCheckoutScreen(
          addressProvider: addressProvider,
          authProvider: authProvider,
          cartProvider: cartProvider,
          checkoutProvider: checkoutProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Starts with default 'Home'
      expect(find.text('Clifton House 12'), findsWidgets);
      expect(find.text('DEFAULT'), findsOneWidget);

      // Change button is visible
      final changeBtn = find.text('Change');
      expect(changeBtn, findsOneWidget);

      // Tap Change to open modal bottom sheet
      await tester.tap(changeBtn);
      await tester.pumpAndSettle();

      // Modal bottom sheet is open
      expect(find.text('Select Delivery Destination'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
      expect(find.text('I.I Chundrigar Tower 5, Karachi'), findsOneWidget);
      expect(find.text('Use Temporary One-Time Address'), findsOneWidget);

      // Tap 'Work' address to select it
      await tester.tap(find.text('Work'));
      await tester.pumpAndSettle();

      // Sheet closes and fields are updated to Work
      expect(find.text('Select Delivery Destination'), findsNothing);
      expect(find.text('I.I Chundrigar Tower 5'), findsWidgets);

      // Since Work is an existing saved address, Save as default checkbox remains HIDDEN
      expect(find.text('Save as my default delivery address'), findsNothing);
      expect(find.text('Save as default in my address book'), findsNothing);
    });

    testWidgets('Case 4 (Temporary One-Time Address): selecting temporary address displays banner and allows un-saved delivery', (tester) async {
      addressProvider.updateAuth('user_123', null);
      await addressProvider.addAddress(
        label: 'Home',
        fullName: 'Mudasir Home',
        phone: '03001111111',
        address: 'Clifton House 12',
        city: 'Karachi',
        isDefault: true,
      );

      await tester.pumpWidget(
        buildTestableCheckoutScreen(
          addressProvider: addressProvider,
          authProvider: authProvider,
          cartProvider: cartProvider,
          checkoutProvider: checkoutProvider,
        ),
      );
      await tester.pumpAndSettle();

      // Tap Address Book button to open sheet
      final addressBookBtn = find.text('Address Book');
      expect(addressBookBtn, findsOneWidget);
      await tester.tap(addressBookBtn);
      await tester.pumpAndSettle();

      // Tap Use Temporary One-Time Address
      await tester.tap(find.text('Use Temporary One-Time Address'));
      await tester.pumpAndSettle();

      // Sheet closes and temporary banner is displayed
      expect(
        find.text('Temporary one-time shipping address for this order.'),
        findsOneWidget,
      );

      // Checkbox is now visible (since address count < 5) if user wants to save as default
      expect(find.text('Save as default in my address book'), findsOneWidget);
    });
  });
}
