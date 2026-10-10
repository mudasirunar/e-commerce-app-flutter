import '../utils/date_formatter.dart';

/// Represents a customer or administrator profile stored in `users/{uid}`.
///
/// Role assignment is strictly verified server-side via custom claims;
/// the role stored in this profile serves as a client display mirror.
class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String defaultAddress;
  final String role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.defaultAddress = '',
    this.role = 'customer',
    this.createdAt,
    this.updatedAt,
  });

  bool get isAdmin => role == 'admin';

  factory UserProfile.fromMap(Map<String, dynamic> data, String uid) {
    return UserProfile(
      uid: uid,
      name: (data['name'] as String?)?.trim() ?? '',
      email: (data['email'] as String?)?.trim() ?? '',
      phone: (data['phone'] as String?)?.trim() ?? '',
      defaultAddress: (data['defaultAddress'] as String?)?.trim() ?? '',
      role: (data['role'] as String?)?.trim() ?? 'customer',
      createdAt: DateFormatter.parse(data['createdAt']),
      updatedAt: DateFormatter.parse(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap({bool forUpdate = false}) {
    final map = <String, dynamic>{
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'defaultAddress': defaultAddress.trim(),
    };

    if (!forUpdate) {
      map['uid'] = uid;
      map['role'] = role;
      if (createdAt != null) {
        map['createdAt'] = DateFormatter.toSerializable(createdAt);
      }
    }

    if (updatedAt != null) {
      map['updatedAt'] = DateFormatter.toSerializable(updatedAt);
    }

    return map;
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? defaultAddress,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      defaultAddress: defaultAddress ?? this.defaultAddress,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email &&
          role == other.role;

  @override
  int get hashCode => uid.hashCode ^ email.hashCode ^ role.hashCode;
}
