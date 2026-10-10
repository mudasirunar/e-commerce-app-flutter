/// Encapsulates delivery contact and address details required for checkout.
class DeliveryInfo {
  final String fullName;
  final String phone;
  final String address;
  final String city;
  final String notes;

  const DeliveryInfo({
    required this.fullName,
    required this.phone,
    required this.address,
    this.city = 'Karachi',
    this.notes = '',
  });

  /// Validates format: non-empty name, address of at least 10 chars, valid phone.
  bool get isValid =>
      fullName.trim().length >= 2 &&
      address.trim().length >= 8 &&
      _isValidPhone(phone.trim());

  static bool _isValidPhone(String phone) {
    // Accepts Pakistani mobile phone numbers: +923XXXXXXXXX, 03XXXXXXXXX, 923XXXXXXXXX
    final cleaned = phone.replaceAll(RegExp(r'[\s\-]'), '');
    final regex = RegExp(r'^(\+92|92|0)?3[0-9]{9}$');
    return regex.hasMatch(cleaned);
  }

  factory DeliveryInfo.fromMap(Map<String, dynamic> data) {
    return DeliveryInfo(
      fullName: (data['deliveryName'] as String?)?.trim() ?? (data['fullName'] as String?)?.trim() ?? '',
      phone: (data['deliveryPhone'] as String?)?.trim() ?? (data['phone'] as String?)?.trim() ?? '',
      address: (data['deliveryAddress'] as String?)?.trim() ?? (data['address'] as String?)?.trim() ?? '',
      city: (data['city'] as String?)?.trim() ?? 'Karachi',
      notes: (data['notes'] as String?)?.trim() ?? '',
    );
  }

  /// Maps to backend checkout payload format.
  Map<String, dynamic> toCheckoutPayload() {
    return {
      'deliveryName': fullName.trim(),
      'deliveryPhone': phone.trim(),
      'deliveryAddress': address.trim(),
      if (notes.trim().isNotEmpty) 'notes': notes.trim(),
    };
  }

  Map<String, dynamic> toMap() => toCheckoutPayload();

  DeliveryInfo copyWith({
    String? fullName,
    String? phone,
    String? address,
    String? city,
    String? notes,
  }) {
    return DeliveryInfo(
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryInfo &&
          runtimeType == other.runtimeType &&
          fullName == other.fullName &&
          phone == other.phone &&
          address == other.address;

  @override
  int get hashCode => fullName.hashCode ^ phone.hashCode ^ address.hashCode;
}
