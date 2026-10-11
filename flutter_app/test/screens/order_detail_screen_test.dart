import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ecommerceapp/models/order.dart';
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

  group('OrderDetailScreen Widget', () {
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
}
