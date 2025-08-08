// lib/providers/user_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../services/settings_service.dart';

/// Immutable user view-model stored in Riverpod.
class UserState {
  /// Username also serves as our simple uid.
  final String? username;

  /// Whether the user is authenticated in the app session.
  final bool isLoggedIn;

  /// Whether the user completed the intro/onboarding flow.
  final bool completedIntro;

  /// Cached list of known/registered usernames (for convenience in UI).
  final List<String> knownUsers;

  const UserState({
    this.username,
    this.isLoggedIn = false,
    this.completedIntro = false,
    this.knownUsers = const [],
  });

  /// Simple uid alias (same as username for this demo).
  String? get uid => username;

  UserState copyWith({
    String? username,
    bool? isLoggedIn,
    bool? completedIntro,
    List<String>? knownUsers,
  }) {
    return UserState(
      username: username ?? this.username,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      completedIntro: completedIntro ?? this.completedIntro,
      knownUsers: knownUsers ?? this.knownUsers,
    );
  }
}

/// Manages login state, onboarding flag, and the known-users cache.
class UserNotifier extends StateNotifier<UserState> {
  final AuthService _auth = AuthService();
  final SettingsService _settings = SettingsService();

  UserNotifier() : super(const UserState()) {
    _loadKnownUsers();
  }

  /// Internal: refresh the known users list from AuthService.
  Future<void> _loadKnownUsers() async {
    final users = await _auth.getAllUsers();
    state = state.copyWith(knownUsers: users);
  }

  /// Public helper to refresh known users (e.g., after clearing secure storage).
  Future<void> reloadKnownUsers() => _loadKnownUsers();

  /// Mark the current process as logged-in for [username].
  /// Assumes credentials have already been validated by AuthService.
  Future<void> login(String username) async {
    // Get the up-to-date registered users.
    final users = await _auth.getAllUsers();

    // Load this user's "intro completed" flag from SharedPreferences.
    final doneKey = 'introCompleted_$username';
    final completed = await _settings.readBool(doneKey);

    state = state.copyWith(
      username: username,
      isLoggedIn: true,
      completedIntro: completed,
      knownUsers: users,
    );
  }

  /// Mark intro as completed and persist the flag.
  Future<void> completeIntro() async {
    final u = state.username;
    if (u == null) return;
    final doneKey = 'introCompleted_$u';
    await _settings.saveBool(doneKey, true);
    state = state.copyWith(completedIntro: true);
  }

  /// Logout current user; keep the knownUsers cache intact.
  void logout() {
    state = UserState(knownUsers: state.knownUsers);
  }
}

/// Global provider for user state.
final userProvider = StateNotifierProvider<UserNotifier, UserState>(
  (ref) => UserNotifier(),
);
