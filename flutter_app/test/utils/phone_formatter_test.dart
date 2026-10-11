import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerceapp/utils/phone_formatter.dart';

void main() {
  group('PhoneFormatter', () {
    test('normalizes Pakistani local numbers starting with 03 to E.164', () {
      expect(PhoneFormatter.normalizeToE164('03001234567'), '+923001234567');
      expect(PhoneFormatter.normalizeToE164('0312 9876543'), '+923129876543');
      expect(PhoneFormatter.normalizeToE164('0333-5551234'), '+923335551234');
    });

    test('normalizes numbers starting with 92 or 00', () {
      expect(PhoneFormatter.normalizeToE164('923001234567'), '+923001234567');
      expect(PhoneFormatter.normalizeToE164('00923001234567'), '+923001234567');
    });

    test('preserves already normalized E.164 numbers', () {
      expect(PhoneFormatter.normalizeToE164('+923001234567'), '+923001234567');
    });

    test('returns empty string for empty input', () {
      expect(PhoneFormatter.normalizeToE164(''), '');
      expect(PhoneFormatter.normalizeToE164('   '), '');
    });

    test('formats display string nicely', () {
      expect(PhoneFormatter.formatDisplay('+923001234567'), '0300 1234567');
      expect(PhoneFormatter.formatDisplay('03001234567'), '0300 1234567');
    });

    test('validates Pakistani mobile format accurately', () {
      expect(PhoneFormatter.isValidPakistaniMobile('03001234567'), isTrue);
      expect(PhoneFormatter.isValidPakistaniMobile('+923001234567'), isTrue);
      expect(PhoneFormatter.isValidPakistaniMobile('923001234567'), isTrue);
      expect(PhoneFormatter.isValidPakistaniMobile('0300-1234567'), isTrue);
      expect(PhoneFormatter.isValidPakistaniMobile('0213123456'), isFalse); // Landline
      expect(PhoneFormatter.isValidPakistaniMobile('12345'), isFalse);
      expect(PhoneFormatter.isValidPakistaniMobile(''), isFalse);
    });
  });
}
