import '../utils/date_formatter.dart';
import '../utils/money_formatter.dart';
import 'product.dart';

/// Represents an item in the customer's persistent cart stored at `users/{uid}/cart/{productId}`.
///
/// NOTE: Cart documents in Firestore do not store prices (preventing client price tampering).
/// The client joins the referenced [Product] at runtime to calculate display totals,
/// while the backend recalculates authoritative totals at checkout.
class CartItem {
  final String productId;
  final int quantity;
  final DateTime? updatedAt;
  final Product? product;

  const CartItem({
    required this.productId,
    required this.quantity,
    this.updatedAt,
    this.product,
  });

  /// Minor units subtotal for this cart item (or 0 if product is not loaded).
  int get subtotalMinor => (product != null) ? product!.priceMinor * quantity : 0;

  /// Display string for item subtotal: e.g. "PKR 9,000.00"
  String get formattedSubtotal => MoneyFormatter.format(subtotalMinor);

  /// Checks if cart quantity exceeds currently available product stock.
  bool get exceedsStock => product != null && quantity > product!.stockQuantity;

  /// Checks if product has become completely out of stock or inactive.
  bool get isUnavailable => product == null || !product!.isActive || product!.stockQuantity <= 0;

  factory CartItem.fromMap(Map<String, dynamic> data, String productId, {Product? product}) {
    return CartItem(
      productId: productId,
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      updatedAt: DateFormatter.parse(data['updatedAt']),
      product: product,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'quantity': quantity,
      if (updatedAt != null) 'updatedAt': DateFormatter.toSerializable(updatedAt),
    };
  }

  CartItem copyWith({
    int? quantity,
    DateTime? updatedAt,
    Product? product,
  }) {
    return CartItem(
      productId: productId,
      quantity: quantity ?? this.quantity,
      updatedAt: updatedAt ?? this.updatedAt,
      product: product ?? this.product,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          productId == other.productId &&
          quantity == other.quantity;

  @override
  int get hashCode => productId.hashCode ^ quantity.hashCode;
}
