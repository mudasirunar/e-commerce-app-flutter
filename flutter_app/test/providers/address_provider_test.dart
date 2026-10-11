import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecommerceapp/models/user_profile.dart';
import 'package:ecommerceapp/providers/address_provider.dart';
import 'package:ecommerceapp/services/firestore/firestore_service.dart';
import 'package:ecommerceapp/services/local/local_storage_service.dart';

class FakeFirestoreService extends FirestoreService {
  String? updatedDefaultAddress;
  String? updatedPhone;

  @override
  Future<void> updateDeliveryProfile({
    required String uid,
    required String defaultAddress,
    required String phone,
  }) async {
    updatedDefaultAddress = defaultAddress;
    updatedPhone = phone;
  }
}

void main() {
  late FakeFirestoreService fakeFirestore;
  late LocalStorageService localStorage;
  late AddressProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    localStorage = LocalStorageService(prefs);
    fakeFirestore = FakeFirestoreService();
    provider = AddressProvider(fakeFirestore, localStorage);
  });

  group('AddressProvider', () {
    test('starts empty and loads addresses on auth update', () async {
      expect(provider.addresses, isEmpty);
      expect(provider.defaultAddress, isNull);

      provider.updateAuth('user_123', null);
      expect(provider.addresses, isEmpty);
    });

    test('imports Firestore profile defaultAddress if local storage is empty', () async {
      final profile = UserProfile(
        uid: 'user_123',
        name: 'Mudasir',
        email: 'test@example.com',
        phone: '+923001234567',
        defaultAddress: 'Sector 5, Karachi',
      );

      provider.updateAuth('user_123', profile);
      expect(provider.addresses.length, 1);
      expect(provider.defaultAddress, isNotNull);
      expect(provider.defaultAddress!.isDefault, isTrue);
      expect(provider.defaultAddress!.address, 'Sector 5, Karachi');
    });

    test('first added address is automatically marked as default and synced to Firestore', () async {
      provider.updateAuth('user_123', null);

      final success = await provider.addAddress(
        label: 'Home',
        fullName: 'Mudasir Unar',
        phone: '03001234567',
        address: 'House 12, Street 3',
        city: 'Karachi',
        isDefault: false, // Even if false, single-address rule forces default
      );

      expect(success, isTrue);
      expect(provider.addresses.length, 1);
      expect(provider.defaultAddress!.isDefault, isTrue);
      expect(fakeFirestore.updatedDefaultAddress, 'House 12, Street 3');
      expect(fakeFirestore.updatedPhone, '+923001234567');
    });

    test('adding second address does not override default unless specified', () async {
      provider.updateAuth('user_123', null);

      await provider.addAddress(
        label: 'Home',
        fullName: 'First',
        phone: '03001111111',
        address: 'Address 1',
      );

      await provider.addAddress(
        label: 'Office',
        fullName: 'Second',
        phone: '03002222222',
        address: 'Address 2',
        isDefault: false,
      );

      expect(provider.addresses.length, 2);
      expect(provider.defaultAddress!.label, 'Home');
      expect(provider.defaultAddress!.address, 'Address 1');
    });

    test('setDefault updates default address and syncs to Firestore', () async {
      provider.updateAuth('user_123', null);

      await provider.addAddress(
        label: 'Home',
        fullName: 'First',
        phone: '03001111111',
        address: 'Address 1',
      );

      await provider.addAddress(
        label: 'Office',
        fullName: 'Second',
        phone: '03002222222',
        address: 'Address 2',
      );

      final officeId = provider.addresses.firstWhere((a) => a.label == 'Office').id;
      final ok = await provider.setDefault(officeId);

      expect(ok, isTrue);
      expect(provider.defaultAddress!.label, 'Office');
      expect(fakeFirestore.updatedDefaultAddress, 'Address 2');
      expect(fakeFirestore.updatedPhone, '+923002222222');
    });

    test('deleting default address promotes remaining address to default', () async {
      provider.updateAuth('user_123', null);

      await provider.addAddress(
        label: 'Home',
        fullName: 'First',
        phone: '03001111111',
        address: 'Address 1',
      );

      await provider.addAddress(
        label: 'Office',
        fullName: 'Second',
        phone: '03002222222',
        address: 'Address 2',
      );

      final homeId = provider.addresses.firstWhere((a) => a.label == 'Home').id;
      final ok = await provider.deleteAddress(homeId);

      expect(ok, isTrue);
      expect(provider.addresses.length, 1);
      expect(provider.defaultAddress!.label, 'Office');
      expect(provider.defaultAddress!.isDefault, isTrue);
      expect(fakeFirestore.updatedDefaultAddress, 'Address 2');
    });
  });
}
