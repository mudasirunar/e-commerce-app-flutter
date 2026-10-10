import '../utils/date_formatter.dart';
import '../utils/money_formatter.dart';

/// Represents a product item stored in `products/{productId}`.
///
/// Price is strictly stored and calculated as integer paisa (priceMinor).
/// 100 paisa = 1 PKR.
class Product {
  final String productId;
  final String name;
  final String normalizedName;
  final String description;
  final String categoryId;
  final String imageUrl;
  final int priceMinor;
  final int stockQuantity;
  final bool isActive;
  final bool isFeatured;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Product({
    required this.productId,
    required this.name,
    this.normalizedName = '',
    this.description = '',
    required this.categoryId,
    required this.imageUrl,
    required this.priceMinor,
    required this.stockQuantity,
    this.isActive = true,
    this.isFeatured = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Major unit representation in PKR (e.g. 4500.00)
  double get pricePkr => MoneyFormatter.minorToPkr(priceMinor);

  /// Standard formatted price string: e.g. "PKR 4,500.00"
  String get formattedPrice => MoneyFormatter.format(priceMinor);

  /// Short formatted price string: e.g. "Rs 4,500.00"
  String get formattedPriceShort => MoneyFormatter.formatShort(priceMinor);

  bool get isInStock => stockQuantity > 0;
  bool get isOutOfStock => stockQuantity <= 0;
  bool get isLowStock => stockQuantity > 0 && stockQuantity <= 5;

  factory Product.fromMap(Map<String, dynamic> data, String productId) {
    final rawName = (data['name'] as String?)?.trim() ?? '';
    final normalized = (data['normalizedName'] as String?)?.trim() ?? rawName.toLowerCase();

    return Product(
      productId: productId,
      name: rawName,
      normalizedName: normalized,
      description: (data['description'] as String?)?.trim() ?? '',
      categoryId: (data['categoryId'] as String?)?.trim() ?? '',
      imageUrl: (data['imageUrl'] as String?)?.trim() ?? '',
      priceMinor: (data['priceMinor'] as num?)?.toInt() ?? 0,
      stockQuantity: (data['stockQuantity'] as num?)?.toInt() ?? 0,
      isActive: (data['isActive'] as bool?) ?? true,
      isFeatured: (data['isFeatured'] as bool?) ?? false,
      createdAt: DateFormatter.parse(data['createdAt']),
      updatedAt: DateFormatter.parse(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name.trim(),
      'normalizedName': normalizedName.isNotEmpty ? normalizedName : name.trim().toLowerCase(),
      'description': description.trim(),
      'categoryId': categoryId.trim(),
      'imageUrl': imageUrl.trim(),
      'priceMinor': priceMinor,
      'stockQuantity': stockQuantity,
      'isActive': isActive,
      'isFeatured': isFeatured,
      if (createdAt != null) 'createdAt': DateFormatter.toSerializable(createdAt),
      if (updatedAt != null) 'updatedAt': DateFormatter.toSerializable(updatedAt),
    };
  }

  Product copyWith({
    String? name,
    String? normalizedName,
    String? description,
    String? categoryId,
    String? imageUrl,
    int? priceMinor,
    int? stockQuantity,
    bool? isActive,
    bool? isFeatured,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      productId: productId,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      imageUrl: imageUrl ?? this.imageUrl,
      priceMinor: priceMinor ?? this.priceMinor,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          productId == other.productId;

  @override
  int get hashCode => productId.hashCode;
}
