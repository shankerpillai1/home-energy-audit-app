import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskState {
  final bool isLoggedIn;
  // ... other user info
  TaskState({this.isLoggedIn = false});
}

final taskProvider = StateNotifierProvider<TaskNotifier, TaskState>(
  (ref) => TaskNotifier(),
);

class TaskNotifier extends StateNotifier<TaskState> {
  TaskNotifier(): super(TaskState());

  void login() { state = TaskState(isLoggedIn: true); }
  void logout() { state = TaskState(isLoggedIn: false); }
}
