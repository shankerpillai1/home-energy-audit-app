import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';

class UserState {
  /*final String? username;
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
  }*/

  final String? email;
  final String? uid;
  final bool isLoggedIn;
  final bool completedIntro;

  const UserState({
    this.email,
    this.uid,
    this.isLoggedIn = false,
    this.completedIntro = false,
  });

  UserState copyWith({
    String? email,
    String? uid,
    bool? isLoggedIn,
    bool? completedIntro,
  }) {
    return UserState(
      email: email ?? this.email,
      uid: uid ?? this.uid,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      completedIntro: completedIntro ?? this.completedIntro,
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  /*final AuthService _auth = AuthService();
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
    );*/

  final AuthService _auth = AuthService();
  final SettingsService _settings = SettingsService();

  UserNotifier() : super(const UserState()) {
    _loadInitialUser();
  }

  /// Check if there’s an active Supabase session on app start
  Future<void> _loadInitialUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      final completed = await _settings.readBool('introCompleted_${user.id}');
      state = UserState(
        email: user.email,
        uid: user.id,
        isLoggedIn: true,
        completedIntro: completed,
      );
    }
  }

  /// Register a new user with Supabase Auth
  Future<void> register(String email, String password) async {
    final response = await _auth.register(email, password);
    final user = response.user;
    if (user != null) {
      state = UserState(
        email: user.email,
        uid: user.id,
        isLoggedIn: true,
      );
    }
  }

  /// Log in with Supabase Auth
  Future<void> login(String email, String password) async {
    final response = await _auth.login(email, password);
    final user = response.user;
    if (user != null) {
      final completed = await _settings.readBool('introCompleted_${user.id}');
      state = UserState(
        email: user.email,
        uid: user.id,
        isLoggedIn: true,
        completedIntro: completed,
      );
    }
  }

  /// Mark intro as completed (stored locally per-user)
  Future<void> completeIntro() async {
    final id = state.uid;
    if (id == null || id.isEmpty) return;
    await _settings.saveBool('introCompleted_$id', true);
    state = state.copyWith(completedIntro: true);
  }

  /// Mark intro as incomplete (optional reset)
  Future<void> markIntroIncomplete() async {
    final id = state.uid;
    if (id == null || id.isEmpty) return;
    await _settings.saveBool('introCompleted_$id', false);
    state = state.copyWith(completedIntro: false);
  }

  /// Log out from Supabase and reset user state
  Future<void> logout() async {
    await _auth.logout();
    state = const UserState();
  }
}

  /// Mark intro as completed (and persist flag).
  /*Future<void> completeIntro() async {
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
}*/

final userProvider = StateNotifierProvider<UserNotifier, UserState>(
  (ref) => UserNotifier(),
);
