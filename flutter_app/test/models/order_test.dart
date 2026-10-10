import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerceapp/models/order.dart';

void main() {
  group('OrderModel & Snapshots', () {
    test('parses order with items and status history', () {
      final map = {
        'userId': 'user_123',
        'attemptId': 'att_abc',
        'items': [
          {
            'productId': 'prod_01',
            'nameSnapshot': 'Cotton Crewneck T-Shirt',
            'unitPriceMinorSnapshot': 350000,
            'quantity': 2,
          },
          {
            'productId': 'prod_02',
            'nameSnapshot': 'Ceramic Coffee Mug',
            'unitPriceMinorSnapshot': 150000,
            'quantity': 1,
          }
        ],
        'subtotalMinor': 850000,
        'deliveryFeeMinor': 25000,
        'totalMinor': 875000,
        'deliveryName': 'Tariq Aziz',
        'deliveryPhone': '03001234567',
        'deliveryAddress': '123 Main Street, Lahore',
        'status': 'Pending',
        'statusHistory': [
          {
            'status': 'Pending',
            'changedBy': 'system',
          }
        ]
      };

      final order = OrderModel.fromMap(map, 'ord_999');

      expect(order.orderId, 'ord_999');
      expect(order.userId, 'user_123');
      expect(order.items.length, 2);
      expect(order.totalItemCount, 3); // 2 + 1
      expect(order.subtotalMinor, 850000);
      expect(order.deliveryFeeMinor, 25000);
      expect(order.totalMinor, 875000);
      expect(order.formattedTotal, 'PKR 8,750.00');
      expect(order.formattedDeliveryFee, 'PKR 250.00');
      expect(order.status, OrderStatus.pending);
      expect(order.canCustomerCancel, isTrue);
      expect(order.isTerminal, isFalse);
    });

    test('enforces cancellation rights and terminal flags per status', () {
      const pendingOrder = OrderModel(
        orderId: 'o1',
        userId: 'u1',
        items: [],
        subtotalMinor: 0,
        deliveryFeeMinor: 0,
        totalMinor: 0,
        deliveryName: '',
        deliveryPhone: '',
        deliveryAddress: '',
        status: OrderStatus.pending,
      );
      expect(pendingOrder.canCustomerCancel, isTrue);
      expect(pendingOrder.isTerminal, isFalse);

      final confirmedOrder = pendingOrder.copyWith(status: OrderStatus.confirmed);
      expect(confirmedOrder.canCustomerCancel, isFalse);
      expect(confirmedOrder.isTerminal, isFalse);

      final shippedOrder = pendingOrder.copyWith(status: OrderStatus.shipped);
      expect(shippedOrder.canCustomerCancel, isFalse);
      expect(shippedOrder.isTerminal, isFalse);

      final deliveredOrder = pendingOrder.copyWith(status: OrderStatus.delivered);
      expect(deliveredOrder.canCustomerCancel, isFalse);
      expect(deliveredOrder.isTerminal, isTrue);

      final cancelledOrder = pendingOrder.copyWith(status: OrderStatus.cancelled);
      expect(cancelledOrder.canCustomerCancel, isFalse);
      expect(cancelledOrder.isTerminal, isTrue);
    });

    test('item snapshot computes subtotal accurately', () {
      const item = OrderItemSnapshot(
        productId: 'p1',
        nameSnapshot: 'Item 1',
        unitPriceMinorSnapshot: 250000,
        quantity: 3,
      );
      expect(item.subtotalMinor, 750000);
      expect(item.formattedUnitPrice, 'PKR 2,500.00');
      expect(item.formattedSubtotal, 'PKR 7,500.00');
    });
  });
}
