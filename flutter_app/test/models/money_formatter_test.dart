import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerceapp/utils/money_formatter.dart';

void main() {
  group('MoneyFormatter', () {
    test('converts major PKR to integer minor units (paisa)', () {
      expect(MoneyFormatter.pkrToMinor(4500), 450000);
      expect(MoneyFormatter.pkrToMinor(4500.50), 450050);
      expect(MoneyFormatter.pkrToMinor(0), 0);
      expect(MoneyFormatter.pkrToMinor(0.99), 99);
      expect(MoneyFormatter.pkrToMinor(12.34), 1234);
    });

    test('rejects negative values unless allowNegative is set', () {
      expect(() => MoneyFormatter.pkrToMinor(-10), throwsArgumentError);
      expect(MoneyFormatter.pkrToMinor(-10, allowNegative: true), -1000);
    });

    test('converts minor units back to major PKR double', () {
      expect(MoneyFormatter.minorToPkr(450000), 4500.0);
      expect(MoneyFormatter.minorToPkr(450050), 4500.50);
      expect(MoneyFormatter.minorToPkr(99), 0.99);
      expect(MoneyFormatter.minorToPkr(0), 0.0);
    });

    test('formats integer paisa into readable PKR string', () {
      expect(MoneyFormatter.format(450000), 'PKR 4,500.00');
      expect(MoneyFormatter.format(450050), 'PKR 4,500.50');
      expect(MoneyFormatter.format(12500000), 'PKR 125,000.00');
      expect(MoneyFormatter.format(0), 'PKR 0.00');
      expect(MoneyFormatter.format(450000, showPaisa: false), 'PKR 4,500');
      expect(MoneyFormatter.format(450000, prefix: false), '4,500.00');
    });

    test('formats short representations', () {
      expect(MoneyFormatter.formatShort(450000), '4,500.00');
    });

    test('parses input strings into exact integer minor units', () {
      expect(MoneyFormatter.parseToMinor('4500'), 450000);
      expect(MoneyFormatter.parseToMinor('4,500'), 450000);
      expect(MoneyFormatter.parseToMinor('PKR 4,500.50'), 450050);
      expect(MoneyFormatter.parseToMinor('Rs 125,000'), 12500000);
      expect(MoneyFormatter.parseToMinor(''), isNull);
      expect(MoneyFormatter.parseToMinor('abc'), isNull);
      expect(MoneyFormatter.parseToMinor('-100'), isNull);
    });
  });
}
