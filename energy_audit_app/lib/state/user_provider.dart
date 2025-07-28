import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';

class UserState {
  final String? username;
  final bool isLoggedIn;
  final bool completedIntro;
  final List<String> knownUsers;

  UserState({
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
  final LocalStorageService _storage = LocalStorageService();

  UserNotifier() : super(UserState()) {
    _loadKnownUsers();
  }

  /// Load registered users from secure storage.
  Future<void> _loadKnownUsers() async {
    final users = await _auth.getAllUsers();
    state = state.copyWith(knownUsers: users);
  }

  /// Set login state (assumes authentication already done externally).
  Future<void> login(String username) async {
    // Load the up‑to‑date user list
    final users = await _auth.getAllUsers();

    // Load whether this user has completed the intro
    final doneKey = 'introCompleted_$username';
    final completed = await _storage.readBool(doneKey);

    state = state.copyWith(
      username: username,
      isLoggedIn: true,
      completedIntro: completed,
      knownUsers: users,
    );
  }

  /// Mark intro completed and persist.
  Future<void> completeIntro() async {
    if (state.username == null) return;
    final doneKey = 'introCompleted_${state.username}';
    await _storage.saveBool(doneKey, true);
    state = state.copyWith(completedIntro: true);
  }

  /// Logout current user (clears username & flags but preserves knownUsers).
  void logout() {
    state = UserState(knownUsers: state.knownUsers);
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>(
  (ref) => UserNotifier(),
);
