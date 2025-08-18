import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/todo_item.dart';
import 'user_provider.dart';

/// Manages the state of the to-do list, including persistence.
class TodoListNotifier extends StateNotifier<List<TodoItem>> {
  final Ref _ref;
  final String _userId;
  static const _uuid = Uuid();

  TodoListNotifier(this._ref, this._userId) : super([]) {
    _loadTodos();
  }

  /// The key used to store the to-do list in SharedPreferences.
  /// It's user-specific to support multiple accounts.
  String get _storageKey => 'todo_list_$_userId';

  /// Loads the to-do list from local storage.
  Future<void> _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      state = jsonList.map((json) => TodoItem.fromJson(json)).toList();
    } else {
      // For demonstration, add richer initial items if the list is empty.
      // This helps showcase the sorting and due date logic.
      final now = DateTime.now();
      state = [
        TodoItem(id: _uuid.v4(), title: 'Seal Air Leaks', type: TodoItemType.project, priority: 1),
        TodoItem(id: _uuid.v4(), title: 'Annual AC maintenance', type: TodoItemType.reminder, dueDate: now.add(const Duration(days: 90))),
        TodoItem(id: _uuid.v4(), title: 'Clean refrigerator coils', type: TodoItemType.reminder, dueDate: now.subtract(const Duration(days: 1)), priority: 1), // Overdue
        TodoItem(id: _uuid.v4(), title: 'Check furnace filter', type: TodoItemType.reminder, dueDate: now.add(const Duration(days: 5))), // Due soon
      ];
      _saveTodos(); // Save the initial list
    }
  }

  /// Saves the current to-do list to local storage.
  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(state.map((item) => item.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }

  /// Adds a new to-do item or reminder to the list.
  /// Avoids adding duplicates by checking the title.
  void addItem({
    required String title,
    required TodoItemType type,
    DateTime? dueDate,
    int priority = 0,
  }) {
    // Check if an item with the same title already exists.
    if (state.any((item) => item.title == title)) {
      return; // Do not add a duplicate.
    }

    final newItem = TodoItem(
      id: _uuid.v4(),
      title: title,
      type: type,
      dueDate: dueDate,
      priority: priority,
    );
    state = [...state, newItem];
    _saveTodos();
  }

  /// Toggles the `isDone` status of a to-do item.
  /// For a periodic reminder, this should ideally reset its due date for the next cycle.
  /// For now, we will move it to the "Done" list as requested.
  void toggleDone(String id) {
    state = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(isDone: !item.isDone)
        else
          item,
    ];
    _saveTodos();
  }


  /// Removes a to-do item from the list by its ID.
  void removeItem(String id) {
    state = state.where((item) => item.id != id).toList();
    _saveTodos();
  }

  /// Removes a to-do item from the list by its title.
  /// Useful for interacting with systems like the Assistant that use titles.
  void removeItemByTitle(String title) {
    state = state.where((item) => item.title != title).toList();
    _saveTodos();
  }
}

/// The provider for the [TodoListNotifier].
///
/// It watches the [userProvider] to ensure that the to-do list is
/// specific to the currently logged-in user.
final todoListProvider = StateNotifierProvider<TodoListNotifier, List<TodoItem>>((ref) {
  // Get the current user's ID. Fallback to 'local' for guests.
  final userId = ref.watch(userProvider).uid ?? 'local';
  return TodoListNotifier(ref, userId);
});