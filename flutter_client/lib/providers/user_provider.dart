import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';

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

    final uid = _extractUidFromIdToken(token);
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
    final uid = _extractUidFromIdToken(idToken);
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
  /// your backend should still verify signatures with Google keys.
  String? _extractUidFromIdToken(String? idToken) {
    if (idToken == null) return null;
    try {
      final parts = idToken.split('.');
      if (parts.length != 3) return null;
      final payload = _base64UrlDecode(parts[1]);
      final map = json.decode(utf8.decode(payload)) as Map<String, dynamic>;
      final sub = map['sub'];
      return (sub is String && sub.isNotEmpty) ? sub : null;
    } catch (_) {
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