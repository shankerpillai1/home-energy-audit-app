import '../models/leakage_task.dart';

abstract class TaskRepository {
  Future<List<LeakageTask>> fetchAll();
  Future<LeakageTask?> fetchById(String id);
  Future<void> upsert(LeakageTask task);
  Future<void> delete(String id);
}
