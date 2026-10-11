import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecommerceapp/providers/address_provider.dart';
import 'package:ecommerceapp/screens/profile/addresses_screen.dart';
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

Widget buildTestableAddressesScreen({
  required AddressProvider addressProvider,
}) {
  return ChangeNotifierProvider<AddressProvider>.value(
    value: addressProvider,
    child: const MaterialApp(
      home: AddressesScreen(),
    ),
  );
}

void main() {
  late LocalStorageService localStorage;
  late FakeFirestoreService fakeFirestore;
  late AddressProvider addressProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    localStorage = LocalStorageService(prefs);
    fakeFirestore = FakeFirestoreService();
    addressProvider = AddressProvider(fakeFirestore, localStorage);
  });

  group('AddressesScreen Widget', () {
    testWidgets('renders EmptyView when address list is empty', (tester) async {
      addressProvider.updateAuth('user_123', null);

      await tester.pumpWidget(buildTestableAddressesScreen(addressProvider: addressProvider));
      await tester.pumpAndSettle();

      expect(find.text('No Addresses Saved'), findsOneWidget);
      expect(find.text('Add New Address'), findsOneWidget);
    });

    testWidgets('renders address cards, default badge, and items', (tester) async {
      addressProvider.updateAuth('user_123', null);
      await addressProvider.addAddress(
        label: 'Home',
        fullName: 'Mudasir Unar',
        phone: '03001234567',
        address: 'House 12, Street 3',
        city: 'Karachi',
        isDefault: true,
      );
      await addressProvider.addAddress(
        label: 'Office',
        fullName: 'Mudasir Work',
        phone: '03009999999',
        address: 'Tower 4, Tech Zone',
        city: 'Islamabad',
        isDefault: false,
      );

      await tester.pumpWidget(buildTestableAddressesScreen(addressProvider: addressProvider));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Office'), findsOneWidget);
      expect(find.text('Mudasir Unar'), findsOneWidget);
      expect(find.text('Mudasir Work'), findsOneWidget);
      expect(find.text('DEFAULT'), findsOneWidget);
      expect(find.text('Set as Default'), findsOneWidget);
    });

    testWidgets('tapping Set as Default switches the default address', (tester) async {
      addressProvider.updateAuth('user_123', null);
      await addressProvider.addAddress(
        label: 'Home',
        fullName: 'Mudasir Home',
        phone: '03001111111',
        address: 'Address 1',
        isDefault: true,
      );
      await addressProvider.addAddress(
        label: 'Work',
        fullName: 'Mudasir Work',
        phone: '03002222222',
        address: 'Address 2',
        isDefault: false,
      );

      await tester.pumpWidget(buildTestableAddressesScreen(addressProvider: addressProvider));
      await tester.pumpAndSettle();

      final setAsDefaultBtn = find.text('Set as Default');
      expect(setAsDefaultBtn, findsOneWidget);

      await tester.tap(setAsDefaultBtn);
      await tester.pumpAndSettle();

      expect(addressProvider.defaultAddress!.label, 'Work');
      expect(find.text('Default delivery address updated.'), findsOneWidget);
    });

    testWidgets('opening Add Delivery Address sheet renders address type tabs without checkmark tick', (tester) async {
      addressProvider.updateAuth('user_123', null);

      await tester.pumpWidget(buildTestableAddressesScreen(addressProvider: addressProvider));
      await tester.pumpAndSettle();

      // Tap Add New Address button
      final addBtn = find.text('Add New Address');
      expect(addBtn, findsOneWidget);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      // Bottom sheet is now open
      expect(find.text('Add Delivery Address'), findsOneWidget);
      expect(find.text('Address Type'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);

      // Verify all ChoiceChips have showCheckmark: false (no tick icon)
      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).toList();
      expect(chips.length, 3);
      for (final chip in chips) {
        expect(chip.showCheckmark, false);
      }

      // Tap 'Work' tab
      await tester.tap(find.text('Work'));
      await tester.pumpAndSettle();

      final updatedWorkChip = tester.widget<ChoiceChip>(
        find.ancestor(of: find.text('Work'), matching: find.byType(ChoiceChip)),
      );
      expect(updatedWorkChip.selected, true);
      expect(updatedWorkChip.showCheckmark, false);
    });
  });
}
