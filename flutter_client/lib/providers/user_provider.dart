import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';

class UserState {
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
  final AuthService _auth = AuthService();
  final SettingsService _settings = SettingsService();

  UserNotifier() : super(const UserState()) {
    _loadInitialUser();
  }

  /// Loads user info if already signed in
  Future<void> _loadInitialUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      final completed = await _settings.readBool('introCompleted_${user.uid}');
      state = UserState(
        email: user.email,
        uid: user.uid,
        isLoggedIn: true,
        completedIntro: completed,
      );
    }
  }

  /// Set user manually after login or registration
  void setUser(user) async {
    if (user == null) {
      state = const UserState();
      return;
    }
    final completed = await _settings.readBool('introCompleted_${user.uid}');
    state = UserState(
      email: user.email,
      uid: user.uid,
      isLoggedIn: true,
      completedIntro: completed,
    );
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

  /// Log out from Firebase and reset user state
  Future<void> logout() async {
    await _auth.logout();
    state = const UserState();
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>(
  (ref) => UserNotifier(),
);
