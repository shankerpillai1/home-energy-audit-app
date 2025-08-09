import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../services/settings_service.dart';

class UserState {
  final String? username;
  final bool isLoggedIn;
  final bool completedIntro;
  final List<String> knownUsers;

  // Expose uid; for now we just use username as uid.
  String? get uid => username;

  const UserState({
    this.username,
    this.isLoggedIn = false,
    this.completedIntro = false,
    this.knownUsers = const [],
  });

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

class UserNotifier extends StateNotifier<UserState> {
  final AuthService _auth = AuthService();
  final SettingsService _settings = SettingsService();

  UserNotifier() : super(const UserState()) {
    _loadKnownUsers();
  }

  /// Load registered users from local registry.
  Future<void> _loadKnownUsers() async {
    final users = await _auth.getAllUsers();
    state = state.copyWith(knownUsers: users);
  }

  /// Log in (assumes AuthService has validated credentials).
  Future<void> login(String username) async {
    final users = await _auth.getAllUsers();
    final completed = await _settings.readBool('introCompleted_$username');
    state = state.copyWith(
      username: username,
      isLoggedIn: true,
      completedIntro: completed,
      knownUsers: users,
    );
  }

  /// Mark intro as completed (and persist flag).
  Future<void> completeIntro() async {
    final name = state.username;
    if (name == null || name.isEmpty) return;
    await _settings.saveBool('introCompleted_$name', true);
    state = state.copyWith(completedIntro: true);
  }

  /// Mark intro as NOT completed (used after data clearing).
  Future<void> markIntroIncompleteForCurrent() async {
    final name = state.username;
    if (name == null || name.isEmpty) return;
    await _settings.saveBool('introCompleted_$name', false);
    state = state.copyWith(completedIntro: false);
  }

  /// Logout but keep known users list.
  void logout() {
    state = UserState(knownUsers: state.knownUsers);
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>(
  (ref) => UserNotifier(),
);
