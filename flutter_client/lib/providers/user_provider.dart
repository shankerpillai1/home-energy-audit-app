import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import 'package:http/http.dart' as http;

/// Minimal auth state: only token + UID + flags (no personal info).
class UserState {
  final String? idToken;
  final String? uid;          // derived from idToken `sub`
  final bool isLoggedIn;
  final bool completedIntro;

  const UserState({
    this.idToken,
    this.uid,
    this.isLoggedIn = false,
    this.completedIntro = false,
  });

  UserState copyWith({
    String? idToken,
    String? uid,
    bool? isLoggedIn,
    bool? completedIntro,
  }) {
    return UserState(
      idToken: idToken ?? this.idToken,
      uid: uid ?? this.uid,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      completedIntro: completedIntro ?? this.completedIntro,
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  final AuthService _auth = AuthService();
  final SettingsService _settings = SettingsService();

  UserNotifier() : super(const UserState()) {
    _loadInitialUser();
  }

  /// Try to silently restore session on app start.
  Future<void> _loadInitialUser() async {
    final token = await _auth.trySilentSignIn();
    if (token == null) return;

    final uid = await _fetchEmailFromGoogle(token);
    if (uid == null) return;
    await _loginToBackend(token, uid);
    final completed = await _settings.readBool('introCompleted_$uid');

    state = UserState(
      idToken: token,
      uid: uid,
      isLoggedIn: true,
      completedIntro: completed,
    );
  }

  /// Called after Google sign-in from the login page (we pass only the token).
  Future<void> setUser(String idToken) async {
    final uid = await _fetchEmailFromGoogle(idToken);
    if (uid == null) return;
    await _loginToBackend(idToken, uid);
    final completed = await _settings.readBool('introCompleted_$uid');

    state = UserState(
      idToken: idToken,
      uid: uid,
      isLoggedIn: true,
      completedIntro: completed,
    );
  }

  /// Mark intro complete for this UID.
  Future<void> completeIntro() async {
    final uid = state.uid;
    if (uid == null || uid.isEmpty) return;
    await _settings.saveBool('introCompleted_$uid', true);
    state = state.copyWith(completedIntro: true);
  }

  Future<void> _loginToBackend(String idToken, String uid) async {
    try {
      final uri = Uri.parse('http://10.0.2.2:8000/login');  // Emulator → FastAPI
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id_token': idToken,
          'uid': uid,
        }),
      );

      print('Backend /login => ${response.statusCode}: ${response.body}');
    } catch (e) {
      print('Error calling backend /login: $e');
    }
  }

  /// Optional reset.
  Future<void> markIntroIncomplete() async {
    final uid = state.uid;
    if (uid == null || uid.isEmpty) return;
    await _settings.saveBool('introCompleted_$uid', false);
    state = state.copyWith(completedIntro: false);
  }

  /// Sign out via AuthService and clear state.
  Future<void> logout() async {
    await _auth.signOut();
    state = const UserState();
  }

  /// --- Helpers ---

  /// Extracts a stable UID from a Google ID token (JWT) without storing PII.
  /// Uses the `sub` claim (subject). This does not verify the token;
  String? _extractUidFromIdToken(String? idToken) {
    if (idToken == null) return null;
    try {
      final parts = idToken.split('.');
      if (parts.length != 3) return null;
      final payload = _base64UrlDecode(parts[1]);
      final map = json.decode(utf8.decode(payload)) as Map<String, dynamic>;
      final email = map['email'];
      return (email is String && email.isNotEmpty) ? email : null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _fetchEmailFromGoogle(String idToken) async {
    try {
      final uri = Uri.parse('https://oauth2.googleapis.com/tokeninfo?id_token=$idToken');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final email = data['email'];
        return (email is String && email.isNotEmpty) ? email : null;
      } else {
        print('Google tokeninfo error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error verifying token with Google: $e');
      return null;
    }
  }

  List<int> _base64UrlDecode(String input) {
    // Normalize Base64URL padding
    var normalized = input.replaceAll('-', '+').replaceAll('_', '/');
    while (normalized.length % 4 != 0) {
      normalized += '=';
    }
    return base64.decode(normalized);
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>(
  (ref) => UserNotifier(),
);