// lib/services/file_storage_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// File storage service used by repositories and UI.
/// Layout (per user/module):
///   <appDocDir>/users/<uid>/<module>/
///     - index.json
///     - tasks/<taskId>.json
///     - media/<taskId>/<files>
/// And user profile:
///   <appDocDir>/users/<uid>/profile.json
///
/// When [enableWorkspaceMirror] is true (dev), writes are mirrored to
/// "<cwd>/users/..." for easy inspection in the project workspace.
class FileStorageService {
  final bool enableWorkspaceMirror;

  FileStorageService({this.enableWorkspaceMirror = false});

  // --- Base locations --------------------------------------------------------

  Future<Directory> _appDocDir() async => getApplicationDocumentsDirectory();

  /// <app>/users
  Future<Directory> usersRootDir() async {
    final dir = Directory(p.join((await _appDocDir()).path, 'users'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// <app>/users/<uid>
  Future<Directory> userDir(String uid) async {
    final dir = Directory(p.join((await usersRootDir()).path, uid));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  // --- Module helpers (match existing call sites) ----------------------------

  /// <app>/users/<uid>/<module>
  Future<Directory> moduleDir(String uid, String module) async {
    final dir = Directory(p.join((await userDir(uid)).path, module));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Alias used elsewhere.
  Future<Directory> moduleRootDir(String uid, String module) =>
      moduleDir(uid, module);

  /// <app>/users/<uid>/<module>/index.json
  Future<File> moduleIndexFile(String uid, String module) async {
    final f = File(p.join((await moduleDir(uid, module)).path, 'index.json'));
    if (!await f.exists()) await f.create(recursive: true);
    return f;
  }

  /// <app>/users/<uid>/<module>/tasks
  Future<Directory> moduleTasksDir(String uid, String module) async {
    final d = Directory(p.join((await moduleDir(uid, module)).path, 'tasks'));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  /// <app>/users/<uid>/<module>/tasks/<taskId>.json
  Future<File> taskFile(String uid, String module, String taskId) async {
    final f = File(p.join((await moduleTasksDir(uid, module)).path, '$taskId.json'));
    if (!await f.exists()) await f.create(recursive: true);
    return f;
  }

  /// <app>/users/<uid>/<module>/media
  Future<Directory> moduleMediaDir(String uid, String module) async {
    final d = Directory(p.join((await moduleDir(uid, module)).path, 'media'));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  /// <app>/users/<uid>/<module>/media/<taskId>
  Future<Directory> mediaTaskDir(String uid, String module, String taskId) async {
    final d = Directory(p.join((await moduleMediaDir(uid, module)).path, taskId));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  /// Generic file inside module with a relative path (e.g. "templates/foo.jpg").
  Future<File> moduleFile(String uid, String module, String relativePath) async {
    final base = await moduleDir(uid, module);
    final f = File(p.join(base.path, relativePath));
    if (!await f.parent.exists()) await f.parent.create(recursive: true);
    if (!await f.exists()) await f.create(recursive: true);
    return f;
  }

  /// Resolve a relative/absolute path to absolute path (NON-null).
  Future<String> resolveModuleAbsolute(
    String uid,
    String module,
    String relOrAbs,
  ) async {
    if (p.isAbsolute(relOrAbs)) return relOrAbs;
    final root = await moduleDir(uid, module);
    return p.join(root.path, relOrAbs);
  }

  /// <app>/users/<uid>/profile.json
  Future<File> profileFile(String uid) async {
    final f = File(p.join((await userDir(uid)).path, 'profile.json'));
    if (!await f.exists()) await f.create(recursive: true);
    return f;
  }

  // --- JSON helpers (match repository usage) --------------------------------

  Future<Map<String, dynamic>> readJsonObject(File file) async {
    try {
      final txt = await file.readAsString();
      if (txt.trim().isEmpty) return <String, dynamic>{};
      final j = jsonDecode(txt);
      if (j is Map<String, dynamic>) return j;
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Future<void> writeJsonObject(
    File file,
    Map<String, dynamic> obj, {
    String? mirrorRelative, // e.g., users/<uid>/<module>/tasks/<id>.json
  }) async {
    final pretty = const JsonEncoder.withIndent('  ').convert(obj);
    await file.writeAsString(pretty);
    await _mirrorIfNeeded(file, mirrorRelative: mirrorRelative);
  }

  Future<void> writeJsonArray(
    File file,
    List<dynamic> arr, {
    String? mirrorRelative, // e.g., users/<uid>/<module>/index.json
  }) async {
    final pretty = const JsonEncoder.withIndent('  ').convert(arr);
    await file.writeAsString(pretty);
    await _mirrorIfNeeded(file, mirrorRelative: mirrorRelative);
  }

  // --- Media helpers (match task_page usage) --------------------------------

  /// Copy [sourcePath] to media/<taskId>/<preferredFileName> and return
  /// the module-relative path "media/<taskId>/<fileName>".
  Future<String> saveMediaFromFilePath({
    required String uid,
    required String module,
    required String taskId,
    required String sourcePath,
    required String preferredFileName,
  }) async {
    final src = File(sourcePath);
    if (!await src.exists()) {
      throw Exception('Source not found: $sourcePath');
    }
    final destDir = await mediaTaskDir(uid, module, taskId);
    final dest = File(p.join(destDir.path, preferredFileName));
    await src.copy(dest.path);

    // Mirror to workspace
    final rel = p.join('users', uid, module, 'media', taskId, preferredFileName);
    await _mirrorIfNeeded(dest, mirrorRelative: rel);

    return p.join('media', taskId, preferredFileName);
  }

  /// Best-effort delete of media/<taskId> directory.
  Future<void> deleteTaskMedia(String uid, String module, String taskId) async {
    final d = await mediaTaskDir(uid, module, taskId);
    if (await d.exists()) {
      try {
        await d.delete(recursive: true);
      } catch (_) {}
    }
  }

  // --- Workspace mirror (dev helper) ----------------------------------------

  Directory? _workspaceUsersRootCache;

  Future<Directory?> _workspaceUsersRoot() async {
    if (!enableWorkspaceMirror) return null;
    try {
      if (_workspaceUsersRootCache != null) return _workspaceUsersRootCache;
      final cwd = Directory.current.path;
      final d = Directory(p.join(cwd, 'users'));
      if (!await d.exists()) await d.create(recursive: true);
      _workspaceUsersRootCache = d;
      return d;
    } catch (_) {
      return null;
    }
  }

  Future<void> _mirrorIfNeeded(File file, {String? mirrorRelative}) async {
    if (!enableWorkspaceMirror || mirrorRelative == null) return;
    final ws = await _workspaceUsersRoot();
    if (ws == null) return;
    try {
      final mirrorPath = p.join(ws.path, mirrorRelative);
      final mirrorFile = File(mirrorPath);
      if (!await mirrorFile.parent.exists()) {
        await mirrorFile.parent.create(recursive: true);
      }
      await file.copy(mirrorFile.path);
    } catch (e) {
      if (kDebugMode) debugPrint('Mirror failed: $e');
    }
  }
}
