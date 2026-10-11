import 'package:flutter/foundation.dart';
import '../models/user_address.dart';
import '../models/user_profile.dart';
import '../services/firestore/firestore_service.dart';
import '../services/local/local_storage_service.dart';
import '../utils/phone_formatter.dart';

/// Provider managing customer delivery addresses, single-address default guarantee,
/// local persistence, and Firestore profile synchronization.
class AddressProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final LocalStorageService _localStorageService;

  String? _userId;
  UserProfile? _userProfile;
  List<UserAddress> _addresses = [];
  bool _isLoading = false;
  String? _errorMessage;

  AddressProvider(this._firestoreService, this._localStorageService);

  static const int maxAddresses = 5;

  List<UserAddress> get addresses => List.unmodifiable(_addresses);
  int get addressesCount => _addresses.length;
  bool get canAddAddress => _addresses.length < maxAddresses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Returns the designated default address, or the first address if available.
  UserAddress? get defaultAddress {
    if (_addresses.isEmpty) return null;
    for (final addr in _addresses) {
      if (addr.isDefault) return addr;
    }
    return _addresses.first;
  }

  /// Synchronizes address book when auth state or user profile changes.
  void updateAuth(String? userId, UserProfile? profile) {
    final userChanged = _userId != userId;
    _userId = userId;
    _userProfile = profile;

    if (userId == null || userId.isEmpty) {
      _addresses = [];
      notifyListeners();
      return;
    }

    if (userChanged || _addresses.isEmpty) {
      _loadAddresses();
    }
  }

  void _loadAddresses() {
    if (_userId == null) return;
    final savedData = _localStorageService.getSavedAddresses(_userId!);
    final loaded = savedData.map((m) => UserAddress.fromMap(m)).toList();

    // If local storage has no addresses but Firestore profile has default address, import it
    if (loaded.isEmpty &&
        _userProfile != null &&
        _userProfile!.defaultAddress.trim().isNotEmpty) {
      final initial = UserAddress(
        id: 'default_${DateTime.now().millisecondsSinceEpoch}',
        label: 'Home',
        fullName: _userProfile!.name,
        phone: _userProfile!.phone,
        address: _userProfile!.defaultAddress,
        city: 'Karachi',
        isDefault: true,
      );
      loaded.add(initial);
      _persistAddresses(loaded);
    }

    // Single-address rule: If only one address exists, ensure it is default
    if (loaded.length == 1 && !loaded.first.isDefault) {
      loaded[0] = loaded.first.copyWith(isDefault: true);
      _persistAddresses(loaded);
      _syncDefaultToFirestore(loaded.first);
    }

    // Enforce max 5 limit
    if (loaded.length > maxAddresses) {
      loaded.removeRange(maxAddresses, loaded.length);
      _persistAddresses(loaded);
    }

    _addresses = loaded;
    notifyListeners();

    // Sync with remote Firestore subcollection
    _syncRemoteAddresses(_userId!);
  }

  Future<void> _syncRemoteAddresses(String uid) async {
    try {
      final remoteList = await _firestoreService.getUserAddresses(uid);
      if (remoteList.isNotEmpty) {
        final trimmed = remoteList.take(maxAddresses).toList();
        // Ensure single-default rule
        if (trimmed.where((a) => a.isDefault).length != 1) {
          final first = trimmed.first.copyWith(isDefault: true);
          final rest = trimmed.skip(1).map((a) => a.copyWith(isDefault: false)).toList();
          trimmed.clear();
          trimmed.add(first);
          trimmed.addAll(rest);
        }
        _addresses = trimmed;
        await _persistAddresses(trimmed);
        notifyListeners();
      } else if (_addresses.isNotEmpty) {
        // Sync existing local addresses to Firestore
        for (final addr in _addresses) {
          await _firestoreService.saveUserAddress(uid, addr);
        }
      }
    } catch (e) {
      debugPrint('Firestore remote addresses sync notice: $e');
    }
  }

  static int _idCounter = 0;

  /// Adds a new address to the user's address book.
  /// Automatically sets as default if it is the only address or if marked as default.
  Future<bool> addAddress({
    required String label,
    required String fullName,
    required String phone,
    required String address,
    String city = 'Karachi',
    bool isDefault = false,
  }) async {
    _errorMessage = null;
    final normalizedPhone = PhoneFormatter.normalizeToE164(phone);

    if (_addresses.length >= maxAddresses) {
      _errorMessage = 'Maximum of $maxAddresses saved addresses reached.';
      notifyListeners();
      return false;
    }

    if (fullName.trim().length < 2) {
      _errorMessage = 'Please enter recipient name (at least 2 characters).';
      notifyListeners();
      return false;
    }

    if (address.trim().length < 5) {
      _errorMessage = 'Please enter a valid detailed address.';
      notifyListeners();
      return false;
    }

    if (!PhoneFormatter.isValidPakistaniMobile(phone)) {
      _errorMessage = 'Please enter a valid mobile number (e.g. 03001234567).';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final newId = 'addr_${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';
      // If address book is currently empty, this must be the default address
      final shouldBeDefault = _addresses.isEmpty || isDefault;

      final updatedList = <UserAddress>[];
      for (final a in _addresses) {
        updatedList.add(shouldBeDefault ? a.copyWith(isDefault: false) : a);
      }

      final newAddress = UserAddress(
        id: newId,
        label: label.trim().isNotEmpty ? label.trim() : 'Home',
        fullName: fullName.trim(),
        phone: normalizedPhone,
        address: address.trim(),
        city: city.trim().isNotEmpty ? city.trim() : 'Karachi',
        isDefault: shouldBeDefault,
      );
      updatedList.add(newAddress);

      await _persistAddresses(updatedList);
      _addresses = updatedList;

      if (_userId != null) {
        try {
          if (shouldBeDefault) {
            for (final a in updatedList) {
              if (a.id != newAddress.id) {
                await _firestoreService.saveUserAddress(_userId!, a);
              }
            }
          }
          await _firestoreService.saveUserAddress(_userId!, newAddress);
        } catch (e) {
          debugPrint('Remote address write note: $e');
        }
      }

      if (shouldBeDefault) {
        await _syncDefaultToFirestore(newAddress);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save address.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Updates an existing address.
  Future<bool> updateAddress({
    required String id,
    required String label,
    required String fullName,
    required String phone,
    required String address,
    String city = 'Karachi',
    bool isDefault = false,
  }) async {
    _errorMessage = null;
    final normalizedPhone = PhoneFormatter.normalizeToE164(phone);

    if (fullName.trim().length < 2) {
      _errorMessage = 'Please enter recipient name.';
      notifyListeners();
      return false;
    }

    if (address.trim().length < 5) {
      _errorMessage = 'Please enter a valid detailed address.';
      notifyListeners();
      return false;
    }

    if (!PhoneFormatter.isValidPakistaniMobile(phone)) {
      _errorMessage = 'Please enter a valid mobile number.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final shouldBeDefault = _addresses.length == 1 ? true : isDefault;
      final updatedList = <UserAddress>[];
      UserAddress? updatedTarget;

      for (final a in _addresses) {
        if (a.id == id) {
          final updated = a.copyWith(
            label: label.trim(),
            fullName: fullName.trim(),
            phone: normalizedPhone,
            address: address.trim(),
            city: city.trim(),
            isDefault: shouldBeDefault,
          );
          updatedTarget = updated;
          updatedList.add(updated);
        } else {
          updatedList.add(shouldBeDefault ? a.copyWith(isDefault: false) : a);
        }
      }

      await _persistAddresses(updatedList);
      _addresses = updatedList;

      if (_userId != null) {
        try {
          if (shouldBeDefault) {
            for (final a in updatedList) {
              if (a.id != id) {
                await _firestoreService.saveUserAddress(_userId!, a);
              }
            }
          }
          if (updatedTarget != null) {
            await _firestoreService.saveUserAddress(_userId!, updatedTarget);
          }
        } catch (e) {
          debugPrint('Remote address update note: $e');
        }
      }

      if (shouldBeDefault && updatedTarget != null) {
        await _syncDefaultToFirestore(updatedTarget);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update address.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sets an address as the default shipping destination and syncs to Firestore.
  Future<bool> setDefault(String id) async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      final updatedList = <UserAddress>[];
      UserAddress? selectedDefault;

      for (final a in _addresses) {
        if (a.id == id) {
          final updated = a.copyWith(isDefault: true);
          selectedDefault = updated;
          updatedList.add(updated);
        } else {
          updatedList.add(a.copyWith(isDefault: false));
        }
      }

      if (selectedDefault == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _persistAddresses(updatedList);
      _addresses = updatedList;

      if (_userId != null) {
        try {
          for (final a in updatedList) {
            await _firestoreService.saveUserAddress(_userId!, a);
          }
        } catch (e) {
          debugPrint('Remote address setDefault note: $e');
        }
      }

      await _syncDefaultToFirestore(selectedDefault);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to set default address.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Deletes an address. If the deleted address was default, promotes the next
  /// remaining address as default automatically and syncs to Firestore.
  Future<bool> deleteAddress(String id) async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      final wasDefault = _addresses.any((a) => a.id == id && a.isDefault);
      final updatedList = _addresses.where((a) => a.id != id).toList();

      if (wasDefault && updatedList.isNotEmpty) {
        // Promote first address to default
        updatedList[0] = updatedList.first.copyWith(isDefault: true);
        await _syncDefaultToFirestore(updatedList.first);
      } else if (updatedList.isEmpty && _userId != null) {
        // Cleared all addresses
        try {
          await _firestoreService.updateDeliveryProfile(
            uid: _userId!,
            defaultAddress: '',
            phone: '',
          );
        } catch (_) {}
      }

      await _persistAddresses(updatedList);
      _addresses = updatedList;

      if (_userId != null) {
        try {
          await _firestoreService.deleteUserAddress(_userId!, id);
          if (wasDefault && updatedList.isNotEmpty) {
            await _firestoreService.saveUserAddress(_userId!, updatedList.first);
          }
        } catch (e) {
          debugPrint('Remote address delete note: $e');
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete address.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _persistAddresses(List<UserAddress> list) async {
    if (_userId == null) return;
    final mapped = list.map((a) => a.toMap()).toList();
    await _localStorageService.saveAddresses(_userId!, mapped);
  }

  Future<void> _syncDefaultToFirestore(UserAddress address) async {
    if (_userId == null) return;
    try {
      await _firestoreService.updateDeliveryProfile(
        uid: _userId!,
        defaultAddress: address.address,
        phone: address.e164Phone,
      );
    } catch (e) {
      debugPrint('Firestore delivery address sync error: $e');
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
}
