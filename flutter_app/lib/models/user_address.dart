import 'delivery_info.dart';
import '../utils/phone_formatter.dart';

/// Represents a customer's saved physical address with label and default status.
class UserAddress {
  final String id;
  final String label; // e.g. 'Home', 'Work', 'Other'
  final String fullName;
  final String phone;
  final String address;
  final String city;
  final bool isDefault;

  const UserAddress({
    required this.id,
    this.label = 'Home',
    required this.fullName,
    required this.phone,
    required this.address,
    this.city = 'Karachi',
    this.isDefault = false,
  });

  /// Formatted phone for UI display (e.g., `0300 1234567`).
  String get formattedPhone => PhoneFormatter.formatDisplay(phone);

  /// Normalized E.164 phone for Firestore (e.g., `+923001234567`).
  String get e164Phone => PhoneFormatter.normalizeToE164(phone);

  /// Converts this address into a [DeliveryInfo] model for checkout.
  DeliveryInfo toDeliveryInfo() {
    return DeliveryInfo(
      fullName: fullName.trim(),
      phone: e164Phone,
      address: address.trim(),
      city: city.trim().isNotEmpty ? city.trim() : 'Karachi',
    );
  }

  /// Maps to JSON for local persistence.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'fullName': fullName,
      'phone': phone,
      'address': address,
      'city': city,
      'isDefault': isDefault,
    };
  }

  /// Deserializes from JSON map.
  factory UserAddress.fromMap(Map<String, dynamic> map) {
    return UserAddress(
      id: (map['id'] as String?)?.trim() ?? '',
      label: (map['label'] as String?)?.trim() ?? 'Home',
      fullName: (map['fullName'] as String?)?.trim() ?? '',
      phone: (map['phone'] as String?)?.trim() ?? '',
      address: (map['address'] as String?)?.trim() ?? '',
      city: (map['city'] as String?)?.trim() ?? 'Karachi',
      isDefault: map['isDefault'] == true,
    );
  }

  /// Factory from existing [DeliveryInfo].
  factory UserAddress.fromDeliveryInfo(
    DeliveryInfo info, {
    String? id,
    String label = 'Home',
    bool isDefault = true,
  }) {
    return UserAddress(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      label: label,
      fullName: info.fullName,
      phone: info.phone,
      address: info.address,
      city: info.city,
      isDefault: isDefault,
    );
  }

  UserAddress copyWith({
    String? id,
    String? label,
    String? fullName,
    String? phone,
    String? address,
    String? city,
    bool? isDefault,
  }) {
    return UserAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAddress &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          label == other.label &&
          fullName == other.fullName &&
          phone == other.phone &&
          address == other.address &&
          city == other.city &&
          isDefault == other.isDefault;

  @override
  int get hashCode =>
      id.hashCode ^
      label.hashCode ^
      fullName.hashCode ^
      phone.hashCode ^
      address.hashCode ^
      city.hashCode ^
      isDefault.hashCode;
}
