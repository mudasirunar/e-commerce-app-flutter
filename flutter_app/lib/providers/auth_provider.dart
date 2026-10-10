import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../services/auth/auth_service.dart';
import '../services/firestore/firestore_service.dart';

/// Provider managing authentication state, session restoration, and user profile sync.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestoreService;

  User? _user;
  UserProfile? _profile;
  bool _isAdminClaim = false;
  bool _isLoading = true;
  String? _errorMessage;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<UserProfile?>? _profileSubscription;

  AuthProvider(this._authService, this._firestoreService) {
    _init();
  }

  User? get user => _user;
  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _isAdminClaim || (_profile?.isAdmin ?? false);

  String get displayName =>
      _profile?.name.isNotEmpty == true ? _profile!.name : (_user?.displayName ?? 'Customer');
  String get email => _user?.email ?? '';
  String get uid => _user?.uid ?? '';

  void _init() {
    _authSubscription = _authService.authStateChanges.listen((User? user) async {
      _user = user;
      _profileSubscription?.cancel();

      if (user != null) {
        // Check admin custom claims
        _isAdminClaim = await _authService.checkIsAdmin();

        // Listen to Firestore profile
        _profileSubscription = _firestoreService.watchUserProfile(user.uid).listen(
          (UserProfile? profile) {
            _profile = profile;
            _isLoading = false;
            notifyListeners();
          },
          onError: (err) {
            _isLoading = false;
            notifyListeners();
          },
        );

        // If profile doesn't exist yet, create default
        final existingProfile = await _firestoreService.getUserProfile(user.uid);
        if (existingProfile == null) {
          final newProfile = UserProfile(
            uid: user.uid,
            name: user.displayName ?? '',
            email: user.email ?? '',
            role: _isAdminClaim ? 'admin' : 'customer',
            createdAt: DateTime.now(),
          );
          await _firestoreService.saveUserProfile(newProfile);
        }
      } else {
        _profile = null;
        _isAdminClaim = false;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  /// Signs up with email and password, initializing the Firestore user profile.
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final credential = await _authService.signUpWithEmailPassword(
        email: email,
        password: password,
        displayName: name,
      );

      final user = credential.user;
      if (user != null) {
        final profile = UserProfile(
          uid: user.uid,
          name: name.trim(),
          email: email.trim(),
          createdAt: DateTime.now(),
        );
        await _firestoreService.saveUserProfile(profile);
      }

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _parseAuthError(e);
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred during signup.';
      _setLoading(false);
      return false;
    }
  }

  /// Signs in with email and password.
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      );
      _isAdminClaim = await _authService.checkIsAdmin(forceRefresh: true);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _parseAuthError(e);
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Failed to sign in. Please check your network connection.';
      _setLoading(false);
      return false;
    }
  }

  /// Signs out of the application.
  Future<void> signOut() async {
    _setLoading(true);
    await _authService.signOut();
    _user = null;
    _profile = null;
    _isAdminClaim = false;
    _setLoading(false);
  }

  /// Updates allowed profile delivery information.
  Future<bool> updateDeliveryProfile({
    required String defaultAddress,
    required String phone,
  }) async {
    if (_user == null) return false;
    try {
      await _firestoreService.updateDeliveryProfile(
        uid: _user!.uid,
        defaultAddress: defaultAddress,
        phone: phone,
      );
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update delivery address.';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  static String _parseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account with this email address already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few moments and try again.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }
}
