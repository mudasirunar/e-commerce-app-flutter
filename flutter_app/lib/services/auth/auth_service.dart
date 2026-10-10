import 'package:firebase_auth/firebase_auth.dart';

/// Service managing client-side Firebase Authentication operations.
class AuthService {
  final FirebaseAuth? _auth;

  AuthService([this._auth]);

  FirebaseAuth get _client => _auth ?? FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _client.authStateChanges();

  User? get currentUser => _client.currentUser;

  bool get isAuthenticated => _client.currentUser != null;

  /// Signs up with email and password, setting the initial display name.
  Future<UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await _client.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    if (displayName != null && displayName.trim().isNotEmpty) {
      await credential.user?.updateDisplayName(displayName.trim());
    }

    return credential;
  }

  /// Signs in with email and password.
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return await _client.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Signs out the current user session.
  Future<void> signOut() async {
    await _client.signOut();
  }

  /// Fetches fresh Firebase ID Token for authenticated API calls.
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    final user = _client.currentUser;
    if (user == null) return null;
    return await user.getIdToken(forceRefresh);
  }

  /// Inspects decoded token custom claims to check if the caller has admin privileges.
  Future<bool> checkIsAdmin({bool forceRefresh = false}) async {
    final user = _client.currentUser;
    if (user == null) return false;

    final idTokenResult = await user.getIdTokenResult(forceRefresh);
    final claims = idTokenResult.claims;
    if (claims == null) return false;

    return claims['admin'] == true || claims['role'] == 'admin';
  }

  /// Reloads user to check email verification or claim updates.
  Future<void> reloadUser() async {
    final user = _client.currentUser;
    if (user != null) {
      await user.reload();
    }
  }
}
