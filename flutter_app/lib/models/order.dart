import '../utils/date_formatter.dart';
import '../utils/money_formatter.dart';

/// Permitted lifecycle states for customer and admin orders.
enum OrderStatus {
  pending('Pending'),
  confirmed('Confirmed'),
  processing('Processing'),
  shipped('Shipped'),
  delivered('Delivered'),
  cancelled('Cancelled');

  final String value;
  const OrderStatus(this.value);

  static OrderStatus fromString(String? raw) {
    if (raw == null) return OrderStatus.pending;
    return OrderStatus.values.firstWhere(
      (s) => s.value.toLowerCase() == raw.trim().toLowerCase(),
      orElse: () => OrderStatus.pending,
    );
  }
}

/// Immutable snapshot of an item at the time an order was placed.
class OrderItemSnapshot {
  final String productId;
  final String nameSnapshot;
  final int unitPriceMinorSnapshot;
  final int quantity;
  final String? imageUrlSnapshot;

  const OrderItemSnapshot({
    required this.productId,
    required this.nameSnapshot,
    required this.unitPriceMinorSnapshot,
    required this.quantity,
    this.imageUrlSnapshot,
  });

  /// Minor units subtotal for this item line.
  int get subtotalMinor => unitPriceMinorSnapshot * quantity;

  /// Display string for unit price: e.g. "PKR 4,500.00"
  String get formattedUnitPrice => MoneyFormatter.format(unitPriceMinorSnapshot);

  /// Display string for total price: e.g. "PKR 9,000.00"
  String get formattedSubtotal => MoneyFormatter.format(subtotalMinor);

  factory OrderItemSnapshot.fromMap(Map<String, dynamic> data) {
    return OrderItemSnapshot(
      productId: (data['productId'] as String?)?.trim() ?? '',
      nameSnapshot: (data['nameSnapshot'] as String?)?.trim() ?? '',
      unitPriceMinorSnapshot: (data['unitPriceMinorSnapshot'] as num?)?.toInt() ?? 0,
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      imageUrlSnapshot: (data['imageUrlSnapshot'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'nameSnapshot': nameSnapshot,
      'unitPriceMinorSnapshot': unitPriceMinorSnapshot,
      'quantity': quantity,
      if (imageUrlSnapshot != null) 'imageUrlSnapshot': imageUrlSnapshot,
    };
  }
}

/// Status audit history record for an order.
class OrderStatusHistory {
  final String status;
  final DateTime? changedAt;
  final String? note;
  final String? changedBy;

  const OrderStatusHistory({
    required this.status,
    this.changedAt,
    this.note,
    this.changedBy,
  });

  factory OrderStatusHistory.fromMap(Map<String, dynamic> data) {
    return OrderStatusHistory(
      status: (data['status'] as String?)?.trim() ?? '',
      changedAt: DateFormatter.parse(data['changedAt'] ?? data['timestamp']),
      note: (data['note'] as String?)?.trim(),
      changedBy: (data['changedBy'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      if (changedAt != null) 'changedAt': DateFormatter.toSerializable(changedAt),
      if (note != null) 'note': note,
      if (changedBy != null) 'changedBy': changedBy,
    };
  }
}

/// Represents an authoritative customer order stored in `orders/{orderId}`.
class OrderModel {
  final String orderId;
  final String userId;
  final String attemptId;
  final String? requestFingerprint;
  final List<OrderItemSnapshot> items;
  final int subtotalMinor;
  final int deliveryFeeMinor;
  final int totalMinor;
  final String deliveryName;
  final String deliveryPhone;
  final String deliveryAddress;
  final OrderStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<OrderStatusHistory> statusHistory;

  const OrderModel({
    required this.orderId,
    required this.userId,
    this.attemptId = '',
    this.requestFingerprint,
    required this.items,
    required this.subtotalMinor,
    required this.deliveryFeeMinor,
    required this.totalMinor,
    required this.deliveryName,
    required this.deliveryPhone,
    required this.deliveryAddress,
    this.status = OrderStatus.pending,
    this.createdAt,
    this.updatedAt,
    this.statusHistory = const [],
  });

  /// Whether a regular customer is authorized to cancel this order (Pending only).
  bool get canCustomerCancel => status == OrderStatus.pending;

  /// Whether the order is in a terminal non-modifiable state.
  bool get isTerminal => status == OrderStatus.delivered || status == OrderStatus.cancelled;

  /// Formatted money display strings
  String get formattedSubtotal => MoneyFormatter.format(subtotalMinor);
  String get formattedDeliveryFee => deliveryFeeMinor == 0 ? 'Free' : MoneyFormatter.format(deliveryFeeMinor);
  String get formattedTotal => MoneyFormatter.format(totalMinor);

  /// Total count of physical units in this order.
  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);

  factory OrderModel.fromMap(Map<String, dynamic> data, String orderId) {
    final rawItems = data['items'] as List<dynamic>? ?? [];
    final itemsList = rawItems
        .whereType<Map<String, dynamic>>()
        .map((itemMap) => OrderItemSnapshot.fromMap(itemMap))
        .toList();

    final rawHistory = data['statusHistory'] as List<dynamic>? ?? [];
    final historyList = rawHistory
        .whereType<Map<String, dynamic>>()
        .map((histMap) => OrderStatusHistory.fromMap(histMap))
        .toList();

    return OrderModel(
      orderId: orderId,
      userId: (data['userId'] as String?)?.trim() ?? '',
      attemptId: (data['attemptId'] as String?)?.trim() ?? '',
      requestFingerprint: (data['requestFingerprint'] as String?)?.trim(),
      items: itemsList,
      subtotalMinor: (data['subtotalMinor'] as num?)?.toInt() ?? 0,
      deliveryFeeMinor: (data['deliveryFeeMinor'] as num?)?.toInt() ?? 0,
      totalMinor: (data['totalMinor'] as num?)?.toInt() ?? 0,
      deliveryName: (data['deliveryName'] as String?)?.trim() ?? '',
      deliveryPhone: (data['deliveryPhone'] as String?)?.trim() ?? '',
      deliveryAddress: (data['deliveryAddress'] as String?)?.trim() ?? '',
      status: OrderStatus.fromString(data['status'] as String?),
      createdAt: DateFormatter.parse(data['createdAt']),
      updatedAt: DateFormatter.parse(data['updatedAt']),
      statusHistory: historyList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'attemptId': attemptId,
      if (requestFingerprint != null) 'requestFingerprint': requestFingerprint,
      'items': items.map((i) => i.toMap()).toList(),
      'subtotalMinor': subtotalMinor,
      'deliveryFeeMinor': deliveryFeeMinor,
      'totalMinor': totalMinor,
      'deliveryName': deliveryName,
      'deliveryPhone': deliveryPhone,
      'deliveryAddress': deliveryAddress,
      'status': status.value,
      if (createdAt != null) 'createdAt': DateFormatter.toSerializable(createdAt),
      if (updatedAt != null) 'updatedAt': DateFormatter.toSerializable(updatedAt),
      'statusHistory': statusHistory.map((h) => h.toMap()).toList(),
    };
  }

  OrderModel copyWith({
    OrderStatus? status,
    DateTime? updatedAt,
    List<OrderStatusHistory>? statusHistory,
  }) {
    return OrderModel(
      orderId: orderId,
      userId: userId,
      attemptId: attemptId,
      requestFingerprint: requestFingerprint,
      items: items,
      subtotalMinor: subtotalMinor,
      deliveryFeeMinor: deliveryFeeMinor,
      totalMinor: totalMinor,
      deliveryName: deliveryName,
      deliveryPhone: deliveryPhone,
      deliveryAddress: deliveryAddress,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      statusHistory: statusHistory ?? this.statusHistory,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderModel &&
          runtimeType == other.runtimeType &&
          orderId == other.orderId &&
          status == other.status;

  @override
  int get hashCode => orderId.hashCode ^ status.hashCode;
}
