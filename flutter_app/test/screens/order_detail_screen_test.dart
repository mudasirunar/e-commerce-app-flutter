import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ecommerceapp/models/order.dart';
import 'package:ecommerceapp/providers/admin_provider.dart';
import 'package:ecommerceapp/providers/auth_provider.dart';
import 'package:ecommerceapp/providers/order_provider.dart';
import 'package:ecommerceapp/screens/orders/order_detail_screen.dart';

class FakeOrderProvider extends ChangeNotifier implements OrderProvider {
  @override
  bool isLoading = false;

  @override
  String? errorMessage;

  @override
  OrderModel? getOrderById(String orderId) => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  final bool isAdmin;
  FakeAuthProvider({this.isAdmin = false});

  @override
  bool get isAuthenticated => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAdminProvider extends ChangeNotifier implements AdminProvider {
  String? updatedStatus;
  String? updatedOrderId;

  @override
  OrderModel? getOrderById(String orderId) => null;

  @override
  Future<bool> updateOrderStatus(String orderId, String newStatus, {String? note}) async {
    updatedOrderId = orderId;
    updatedStatus = newStatus;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  OrderModel makeOrder({required OrderStatus status}) {
    return OrderModel(
      orderId: 'ord_12345678_test',
      userId: 'usr_1',
      subtotalMinor: 4500000,
      deliveryFeeMinor: 0,
      totalMinor: 4500000,
      deliveryName: 'Ali Khan',
      deliveryPhone: '03001234567',
      deliveryAddress: 'House 1, Street 2, Karachi',
      status: status,
      items: const [
        OrderItemSnapshot(
          productId: 'p_chair',
          nameSnapshot: 'Walnut Armchair',
          unitPriceMinorSnapshot: 4500000,
          quantity: 1,
        ),
      ],
    );
  }

  group('OrderDetailScreen Widget - Customer View', () {
    testWidgets('renders order ID, items, delivery details, and cancel button for Pending order', (tester) async {
      final fakeProvider = FakeOrderProvider();
      final order = makeOrder(status: OrderStatus.pending);

      await tester.pumpWidget(
        ChangeNotifierProvider<OrderProvider>.value(
          value: fakeProvider,
          child: MaterialApp(
            home: OrderDetailScreen(order: order),
          ),
        ),
      );

      expect(find.text('Order #ORD_1234'), findsOneWidget);
      expect(find.text('Walnut Armchair'), findsOneWidget);
      expect(find.text('Ali Khan'), findsOneWidget);
      expect(find.text('03001234567'), findsOneWidget);
      expect(find.text('Cancel Order'), findsOneWidget);
    });

    testWidgets('hides cancel order button when status is delivered', (tester) async {
      final fakeProvider = FakeOrderProvider();
      final order = makeOrder(status: OrderStatus.delivered);

      await tester.pumpWidget(
        ChangeNotifierProvider<OrderProvider>.value(
          value: fakeProvider,
          child: MaterialApp(
            home: OrderDetailScreen(order: order),
          ),
        ),
      );

      expect(find.text('Cancel Order'), findsNothing);
    });
  });

  group('OrderDetailScreen Widget - Administrator View', () {
    testWidgets('renders Admin Order Controls with available transitions for Pending order', (tester) async {
      final fakeOrderProvider = FakeOrderProvider();
      final fakeAuthProvider = FakeAuthProvider(isAdmin: true);
      final fakeAdminProvider = FakeAdminProvider();
      final order = makeOrder(status: OrderStatus.pending);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<OrderProvider>.value(value: fakeOrderProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: fakeAuthProvider),
            ChangeNotifierProvider<AdminProvider>.value(value: fakeAdminProvider),
          ],
          child: MaterialApp(
            home: OrderDetailScreen(order: order),
          ),
        ),
      );

      // Verify admin controls header is visible
      expect(find.text('Admin Order Controls'), findsOneWidget);
      expect(find.text('Store Manager'), findsOneWidget);
      expect(find.text('Move order lifecycle to:'), findsOneWidget);

      // For Pending: Confirmed, Processing, Cancelled transitions
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('Processing'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);

      // Customer cancel button should be replaced by admin controls
      expect(find.widgetWithText(OutlinedButton, 'Cancelled'), findsOneWidget);
    });

    testWidgets('triggers status update dialog and calls AdminProvider on confirm', (tester) async {
      final fakeOrderProvider = FakeOrderProvider();
      final fakeAuthProvider = FakeAuthProvider(isAdmin: true);
      final fakeAdminProvider = FakeAdminProvider();
      final order = makeOrder(status: OrderStatus.pending);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<OrderProvider>.value(value: fakeOrderProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: fakeAuthProvider),
            ChangeNotifierProvider<AdminProvider>.value(value: fakeAdminProvider),
          ],
          child: MaterialApp(
            home: OrderDetailScreen(order: order),
          ),
        ),
      );

      // Ensure button is visible in SingleChildScrollView before tapping
      await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'Confirmed'));
      await tester.pumpAndSettle();

      // Tap 'Confirmed' status transition button
      await tester.tap(find.widgetWithText(OutlinedButton, 'Confirmed'));
      await tester.pumpAndSettle();

      // Confirmation dialog should be displayed
      expect(find.text('Update to Confirmed?'), findsOneWidget);

      // Confirm status update
      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm'));
      await tester.pumpAndSettle();

      // Verify AdminProvider was invoked with the target status
      expect(fakeAdminProvider.updatedOrderId, equals(order.orderId));
      expect(fakeAdminProvider.updatedStatus, equals('Confirmed'));
    });

    testWidgets('shows terminal notice for delivered order in admin view', (tester) async {
      final fakeOrderProvider = FakeOrderProvider();
      final fakeAuthProvider = FakeAuthProvider(isAdmin: true);
      final fakeAdminProvider = FakeAdminProvider();
      final order = makeOrder(status: OrderStatus.delivered);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<OrderProvider>.value(value: fakeOrderProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: fakeAuthProvider),
            ChangeNotifierProvider<AdminProvider>.value(value: fakeAdminProvider),
          ],
          child: MaterialApp(
            home: OrderDetailScreen(order: order),
          ),
        ),
      );

      expect(find.text('Admin Order Controls'), findsOneWidget);
      expect(find.text('This order is Delivered. No further status transitions are available.'), findsOneWidget);
      expect(find.text('Confirmed'), findsNothing);
    });
  });
}
