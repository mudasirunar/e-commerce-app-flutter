/// Represents a product category stored in `categories/{categoryId}`.
class Category {
  final String categoryId;
  final String name;
  final int sortOrder;
  final bool isActive;

  const Category({
    required this.categoryId,
    required this.name,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory Category.fromMap(Map<String, dynamic> data, String categoryId) {
    return Category(
      categoryId: categoryId,
      name: (data['name'] as String?)?.trim() ?? '',
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: (data['isActive'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'name': name.trim(),
      'sortOrder': sortOrder,
      'isActive': isActive,
    };
  }

  Category copyWith({
    String? name,
    int? sortOrder,
    bool? isActive,
  }) {
    return Category(
      categoryId: categoryId,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          categoryId == other.categoryId;

  @override
  int get hashCode => categoryId.hashCode;
}
