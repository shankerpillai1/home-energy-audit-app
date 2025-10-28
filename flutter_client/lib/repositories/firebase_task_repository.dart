import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/leakage_task.dart';
import 'task_repository.dart';

/// Firebase-backed repository:
/// Stores tasks per user under /users/<uid>/leakTasks/<taskId>
class FirebaseTaskRepository implements TaskRepository {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance.ref();

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not signed in');
    }
    return user.uid;
  }

  DatabaseReference get _tasksRef => _db.child('users/$_uid/leakTasks');

  /// Fetch all tasks for current user
  @override
  Future<List<LeakageTask>> fetchAll() async {
    final snapshot = await _tasksRef.get();
    if (!snapshot.exists) return [];

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final tasks = data.entries.map((entry) {
      final taskJson = Map<String, dynamic>.from(entry.value);
      return LeakageTask.fromJson(taskJson);
    }).toList();

    // Sort by createdAt descending
    tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return tasks;
  }

  /// Fetch a single task by ID
  @override
  Future<LeakageTask?> fetchById(String id) async {
    final snapshot = await _tasksRef.child(id).get();
    if (!snapshot.exists) return null;

    final map = Map<String, dynamic>.from(snapshot.value as Map);
    return LeakageTask.fromJson(map);
  }

  /// Create or update a task
  @override
  Future<void> upsert(LeakageTask task) async {
    await _tasksRef.child(task.id).set(task.toJson());
  }

  /// Delete a task and its data
  @override
  Future<void> delete(String id) async {
    await _tasksRef.child(id).remove();
  }
}