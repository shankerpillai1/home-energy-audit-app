import 'dart:io';
import 'package:path/path.dart' as p;

import '../models/leakage_task.dart';
import '../services/file_storage_service.dart';
import 'task_repository.dart';

/// File-backed repository using the hybrid layout:
/// users/<uid>/<module>/
///   index.json
///   tasks/<taskId>.json
///   media/<taskId>/...
class FileBackedTaskRepository implements TaskRepository {
  final FileStorageService fs;
  final String uid;
  final String module;

  FileBackedTaskRepository(this.fs, {required this.uid, required this.module});

  Future<Directory> _moduleDir() => fs.moduleDir(uid, module);

  Future<Directory> _tasksDir() async {
    final base = await _moduleDir();
    final d = Directory(p.join(base.path, 'tasks'));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  @override
  Future<List<LeakageTask>> fetchAll() async {
    final dir = await _tasksDir();
    final tasks = <LeakageTask>[];

    // Scan tasks/*.json even if index.json is missing
    await for (final ent in dir.list(followLinks: false)) {
      if (ent is File && ent.path.toLowerCase().endsWith('.json')) {
        try {
          final map = await fs.readJsonObject(ent);
          if (map.isNotEmpty) {
            tasks.add(LeakageTask.fromJson(map));
          }
        } catch (_) {
          // ignore malformed file
        }
      }
    }

    // Sort by createdAt desc
    tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Maintain index.json for easy inspection
    final index = await fs.moduleIndexFile(uid, module);
    await fs.writeJsonArray(
      index,
      tasks.map((e) => e.toJson()).toList(),
      mirrorRelative: 'users/$uid/$module/index.json',
    );

    return tasks;
  }

  @override
  Future<LeakageTask?> fetchById(String id) async {
    final f = await fs.taskFile(uid, module, id);
    if (!await f.exists()) return null;
    final map = await fs.readJsonObject(f);
    if (map.isEmpty) return null;
    return LeakageTask.fromJson(map);
  }

  @override
  Future<void> upsert(LeakageTask task) async {
    final f = await fs.taskFile(uid, module, task.id);
    await fs.writeJsonObject(
      f,
      task.toJson(),
      mirrorRelative: 'users/$uid/$module/tasks/${task.id}.json',
    );
    // Rebuild index.json for consistency
    await fetchAll();
  }

  @override
  Future<void> delete(String id) async {
    final f = await fs.taskFile(uid, module, id);
    if (await f.exists()) {
      try {
        await f.delete();
      } catch (_) {}
    }
    // Best-effort delete of media/<taskId>/
    await fs.deleteTaskMedia(uid, module, id);

    // Rebuild index
    await fetchAll();
  }
}
