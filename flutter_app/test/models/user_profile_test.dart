import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerceapp/models/user_profile.dart';
import 'package:ecommerceapp/models/category.dart';
import 'package:ecommerceapp/models/checkout_attempt.dart';

void main() {
  group('UserProfile Model', () {
    test('parses from map and identifies admin role', () {
      final customer = UserProfile.fromMap({
        'name': 'Ali Khan',
        'email': 'ali@example.com',
        'phone': '03001234567',
        'defaultAddress': 'Street 1, Karachi',
        'role': 'customer',
      }, 'uid_1');

      expect(customer.uid, 'uid_1');
      expect(customer.name, 'Ali Khan');
      expect(customer.isAdmin, isFalse);

      final admin = UserProfile.fromMap({
        'name': 'Admin User',
        'email': 'admin@example.com',
        'role': 'admin',
      }, 'uid_admin');

      expect(admin.isAdmin, isTrue);
    });

    test('serializes update map without overwriting server-owned role', () {
      const user = UserProfile(
        uid: 'uid_1',
        name: 'Ali Khan Updated',
        email: 'ali@example.com',
        phone: '03007654321',
        defaultAddress: 'New Street 2, Lahore',
        role: 'customer',
      );

      final updateMap = user.toMap(forUpdate: true);
      expect(updateMap['name'], 'Ali Khan Updated');
      expect(updateMap['phone'], '03007654321');
      expect(updateMap.containsKey('role'), isFalse);
      expect(updateMap.containsKey('uid'), isFalse);
    });
  });

  group('Category Model', () {
    test('parses from map and serializes accurately', () {
      final category = Category.fromMap({
        'name': 'Electronics',
        'sortOrder': 1,
        'isActive': true,
      }, 'cat_elec');

      expect(category.categoryId, 'cat_elec');
      expect(category.name, 'Electronics');
      expect(category.sortOrder, 1);
      expect(category.isActive, isTrue);

      final map = category.toMap();
      expect(map['name'], 'Electronics');
      expect(map['sortOrder'], 1);
      expect(map['isActive'], isTrue);
    });
  });

  group('CheckoutAttempt Model', () {
    test('parses attempt and checks completion flag', () {
      final attempt = CheckoutAttempt.fromMap({
        'orderId': 'ord_123',
        'requestFingerprint': 'fp_xyz',
        'status': 'completed',
      }, 'att_001');

      expect(attempt.attemptId, 'att_001');
      expect(attempt.orderId, 'ord_123');
      expect(attempt.isCompleted, isTrue);

      final pendingAttempt = CheckoutAttempt.fromMap({
        'status': 'pending',
      }, 'att_002');
      expect(pendingAttempt.isCompleted, isFalse);
    });
  });
}
