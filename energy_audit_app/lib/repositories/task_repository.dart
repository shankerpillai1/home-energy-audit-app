// lib/repositories/task_repository.dart
import '../models/leakage_task.dart';

/// Abstract repository API for leakage tasks.
abstract class TaskRepository {
  /// Return all tasks for the current user/module.
  Future<List<LeakageTask>> fetchAll();

  /// Return a single task by id (null if not found).
  Future<LeakageTask?> fetchById(String id);

  /// Create or update a task.
  Future<void> upsert(LeakageTask task);

  /// Delete task (and any related persisted data if applicable).
  Future<void> delete(String id);
}
