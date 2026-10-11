import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerceapp/models/delivery_info.dart';
import 'package:ecommerceapp/models/user_address.dart';

void main() {
  group('UserAddress Model', () {
    test('serializes to map and parses from map accurately', () {
      const address = UserAddress(
        id: 'addr_1',
        label: 'Work',
        fullName: 'Ali Khan',
        phone: '03001234567',
        address: 'Office 402, Business Tower',
        city: 'Karachi',
        isDefault: true,
      );

      final map = address.toMap();
      expect(map['id'], 'addr_1');
      expect(map['label'], 'Work');
      expect(map['fullName'], 'Ali Khan');
      expect(map['phone'], '03001234567');
      expect(map['isDefault'], isTrue);

      final parsed = UserAddress.fromMap(map);
      expect(parsed.id, address.id);
      expect(parsed.label, address.label);
      expect(parsed.fullName, address.fullName);
      expect(parsed.phone, address.phone);
      expect(parsed.address, address.address);
      expect(parsed.city, address.city);
      expect(parsed.isDefault, isTrue);
      expect(parsed.e164Phone, '+923001234567');
      expect(parsed.formattedPhone, '0300 1234567');
    });

    test('converts to DeliveryInfo with normalized e164 phone', () {
      const address = UserAddress(
        id: 'addr_2',
        label: 'Home',
        fullName: 'Ali Raza',
        phone: '03129876543',
        address: 'House 14, Street 5, Block A',
        city: 'Lahore',
        isDefault: false,
      );

      final deliveryInfo = address.toDeliveryInfo();
      expect(deliveryInfo.fullName, 'Ali Raza');
      expect(deliveryInfo.phone, '+923129876543');
      expect(deliveryInfo.address, 'House 14, Street 5, Block A');
      expect(deliveryInfo.city, 'Lahore');
      expect(deliveryInfo.isValid, isTrue);
    });

    test('creates UserAddress from existing DeliveryInfo', () {
      const info = DeliveryInfo(
        fullName: 'Sara Khan',
        phone: '+923331112233',
        address: 'Flat 3B, Clifton Block 2',
        city: 'Karachi',
      );

      final addr = UserAddress.fromDeliveryInfo(info, id: 'custom_id', label: 'Apartment');
      expect(addr.id, 'custom_id');
      expect(addr.label, 'Apartment');
      expect(addr.fullName, 'Sara Khan');
      expect(addr.isDefault, isTrue);
    });

    test('copyWith updates properties correctly', () {
      const addr = UserAddress(
        id: '1',
        fullName: 'Test',
        phone: '03001234567',
        address: 'Address 1',
        isDefault: false,
      );

      final updated = addr.copyWith(isDefault: true, label: 'Office');
      expect(updated.id, '1');
      expect(updated.isDefault, isTrue);
      expect(updated.label, 'Office');
      expect(updated.fullName, 'Test');
    });
  });
}
