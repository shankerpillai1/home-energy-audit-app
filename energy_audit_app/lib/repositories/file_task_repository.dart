import 'package:path/path.dart' as p;

import '../models/leakage_task.dart';
import '../services/file_storage_service.dart';
import 'task_repository.dart';

/// Hybrid repository:
/// - index.json: lightweight list for fast overview
/// - tasks/<taskId>.json: full payload per task
/// - media/<taskId>/...: images
class FileTaskRepository implements TaskRepository {
  final FileStorageService _fs;
  final String uid;
  final String module; // e.g., 'leakage'

  FileTaskRepository(this._fs, {required this.uid, this.module = 'leakage'});

  // ---------- index helpers ----------

  Future<List<Map<String, dynamic>>> _readIndex() async {
    final f = await _fs.moduleIndexFile(uid, module);
    final arr = await _fs.readJsonArray(f);
    return arr.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> _writeIndex(List<Map<String, dynamic>> items) async {
    final f = await _fs.moduleIndexFile(uid, module);
    await _fs.writeJsonArray(
      f,
      items,
      mirrorRelative: p.join('users', uid, module, 'index.json'),
    );
  }

  Map<String, dynamic> _indexRowFromTask(LeakageTask t) {
    final completed = _isCompleted(t);
    return {
      'id': t.id,
      'title': t.title,
      'type': t.type,
      'status': completed ? 'completed' : 'in_progress',
      'createdAt': t.createdAt.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  bool _isCompleted(LeakageTask t) {
    final r = t.report;
    if (r == null) return false;
    final anySummary = r.energyLossCost != null ||
        r.energyLossValue != null ||
        r.leakSeverity != null ||
        r.savingsCost != null ||
        r.savingsPercent != null;
    return anySummary || r.points.isNotEmpty;
  }

  // ---------- TaskRepository ----------

  @override
  Future<List<LeakageTask>> fetchAll() async {
    // Read index to get IDs, then read each task file.
    final index = await _readIndex();
    final ids = index.map((e) => e['id'] as String).toList();

    final result = <LeakageTask>[];
    for (final id in ids) {
      final f = await _fs.taskFile(uid, module, id);
      final obj = await _fs.readJsonObject(f);
      if (obj.isNotEmpty) {
        result.add(LeakageTask.fromJson(obj));
      }
    }
    // Fallback: if index is empty, no tasks.
    return result;
  }

  @override
  Future<LeakageTask?> fetchById(String id) async {
    final f = await _fs.taskFile(uid, module, id);
    final obj = await _fs.readJsonObject(f);
    if (obj.isEmpty) return null;
    return LeakageTask.fromJson(obj);
  }

  @override
  Future<void> upsert(LeakageTask task) async {
    // Write the full task
    final f = await _fs.taskFile(uid, module, task.id);
    await _fs.writeJsonObject(
      f,
      task.toJson(),
      mirrorRelative: p.join('users', uid, module, 'tasks', '${task.id}.json'),
    );

    // Update index
    final index = await _readIndex();
    final i = index.indexWhere((e) => e['id'] == task.id);
    final row = _indexRowFromTask(task);
    if (i >= 0) {
      index[i] = row;
    } else {
      index.add(row);
    }
    await _writeIndex(index);
  }

  @override
  Future<void> delete(String id) async {
    // Delete task file
    final f = await _fs.taskFile(uid, module, id);
    if (await f.exists()) {
      try {
        await f.delete();
      } catch (_) {}
    }

    // Delete media dir (best-effort)
    await _fs.deleteTaskMedia(uid, module, id);

    // Update index
    final index = await _readIndex();
    index.removeWhere((e) => e['id'] == id);
    await _writeIndex(index);
  }
}
