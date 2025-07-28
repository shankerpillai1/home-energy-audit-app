import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final LocalStorageService _storage = LocalStorageService();

  UserNotifier(): super(UserState()) {
    _loadKnownUsers();
  }

  /// Load previously used usernames from storage
  Future<void> _loadKnownUsers() async {
    final list = await _storage.readJson('users');
    if (list is List) {
      state = state.copyWith(knownUsers: List<String>.from(list));
    }
  }

  /// Handle login: set username, update knownUsers, load intro flag
  Future<void> login(String username) async {
    // add to known users if new
    final users = List<String>.from(state.knownUsers);
    if (!users.contains(username)) {
      users.add(username);
      await _storage.saveJson('users', users);
    }
    // load whether this user has completed intro
    final doneKey = 'introCompleted_$username';
    final completed = await _storage.readBool(doneKey);

    state = state.copyWith(
      username: username,
      isLoggedIn: true,
      completedIntro: completed,
      knownUsers: users,
    );
  }

  /// Mark intro completed and persist
  Future<void> completeIntro() async {
    if (state.username == null) return;
    final doneKey = 'introCompleted_${state.username}';
    await _storage.saveBool(doneKey, true);
    state = state.copyWith(completedIntro: true);
  }

  /// Logout current user
  void logout() {
    state = UserState(knownUsers: state.knownUsers);
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>(
  (ref) => UserNotifier(),
);
