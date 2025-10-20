import 'package:firebase_auth/firebase_auth.dart';
import 'settings_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Registers a new user with email and password
  Future<UserCredential> register(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      print('User registered: ${credential.user?.email}');
      return credential;
    } on FirebaseAuthException catch (e) {
      print('Registration error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Logs in an existing user with email and password
  Future<UserCredential> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      print('User logged in: ${credential.user?.email}');
      return credential;
    } on FirebaseAuthException catch (e) {
      print('Login error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Sends a password reset email
  Future<void> forgotPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      print('Password reset email sent to $email');
    } on FirebaseAuthException catch (e) {
      print('Forgot password error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Since Firebase doesn’t have "username" by default, you can
  /// store a displayName when registering and retrieve it here.
  /// This simulates "forgot username" by sending their email reminder.
  Future<String?> forgotUsername(String email) async {
    try {
      // Check if a user exists with this email
      // FirebaseAuth doesn't provide direct lookup without admin privileges,
      // so this is only possible if you store display names in Firestore
      // For now, just return the same email to remind the user
      return email.trim();
    } catch (e) {
      print('Forgot username error: $e');
      return null;
    }
  }

  /// Logs out the current user
  Future<void> logout() async {
    await _auth.signOut();
    await SettingsService().clearAll();
    print('User signed out.');
  }

  /// Returns the currently signed-in user
  User? get currentUser => _auth.currentUser;

  /// Optional helper: get all users (Firebase doesn’t allow listing users on client side)
  /// You can instead return the current user’s email only
  Future<List<String>> getAllUsers() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    return [user.email ?? ''];
  }
}