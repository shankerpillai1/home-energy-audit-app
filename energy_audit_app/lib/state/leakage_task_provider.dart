import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/leakage_task.dart';
import '../services/local_storage_service.dart';

/// StateNotifier that manages the list of LeakageTask objects.
class LeakageTaskListNotifier extends StateNotifier<List<LeakageTask>> {
  final LocalStorageService _storage;

  LeakageTaskListNotifier(this._storage) : super([]) {
    _loadTasks();
  }

  /// Load tasks from local storage
  Future<void> _loadTasks() async {
    final tasks = await _storage.getLeakageTasks();
    state = tasks;
  }

  /// Add a new task (or update if id exists)
  Future<void> upsertTask(LeakageTask task) async {
    final index = state.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      state = [
        for (var i = 0; i < state.length; i++)
          if (i == index) task else state[i],
      ];
    } else {
      state = [...state, task];
    }
    await _storage.saveLeakageTasks(state);
  }

  /// Remove a task by its id
  Future<void> deleteTask(String id) async {
    state = state.where((t) => t.id != id).toList();
    await _storage.saveLeakageTasks(state);
  }

  /// Helper to get a task by id (or null)
  LeakageTask? getById(String id) {
    try {
      return state.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Provider for the list of tasks
final leakageTaskListProvider = StateNotifierProvider<
    LeakageTaskListNotifier, List<LeakageTask>>((ref) {
  final storage = LocalStorageService();
  return LeakageTaskListNotifier(storage);
});
