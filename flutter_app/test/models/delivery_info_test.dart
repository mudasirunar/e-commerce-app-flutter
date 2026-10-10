import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerceapp/models/delivery_info.dart';

void main() {
  group('DeliveryInfo Model', () {
    test('validates correctly with valid Pakistani phone and detailed address', () {
      const valid = DeliveryInfo(
        fullName: 'Muhammad Ali',
        phone: '+923001234567',
        address: 'House 123, Street 4, Sector F-6, Islamabad',
        city: 'Islamabad',
      );
      expect(valid.isValid, isTrue);

      const localPhone = DeliveryInfo(
        fullName: 'Sara Khan',
        phone: '03219876543',
        address: 'Apartment 4B, Clifton Block 5, Karachi',
        city: 'Karachi',
      );
      expect(localPhone.isValid, isTrue);
    });

    test('invalidates too-short name, short address, or bad phone', () {
      const shortName = DeliveryInfo(
        fullName: 'A',
        phone: '03001234567',
        address: 'House 123, Street 4, Sector F-6',
      );
      expect(shortName.isValid, isFalse);

      const shortAddress = DeliveryInfo(
        fullName: 'Muhammad Ali',
        phone: '03001234567',
        address: 'H 12',
      );
      expect(shortAddress.isValid, isFalse);

      const invalidPhone = DeliveryInfo(
        fullName: 'Muhammad Ali',
        phone: '12345',
        address: 'House 123, Street 4, Sector F-6',
      );
      expect(invalidPhone.isValid, isFalse);
    });

    test('serializes to backend checkout payload format', () {
      const info = DeliveryInfo(
        fullName: 'Muhammad Ali',
        phone: '03001234567',
        address: 'House 123, Street 4, Sector F-6',
        city: 'Islamabad',
        notes: 'Ring doorbell twice',
      );

      final payload = info.toCheckoutPayload();
      expect(payload['deliveryName'], 'Muhammad Ali');
      expect(payload['deliveryPhone'], '03001234567');
      expect(payload['deliveryAddress'], 'House 123, Street 4, Sector F-6');
      expect(payload['notes'], 'Ring doorbell twice');
    });
  });
}
