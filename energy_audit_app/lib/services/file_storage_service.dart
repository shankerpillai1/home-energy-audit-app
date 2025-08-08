// lib/services/file_storage_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // kDebugMode
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Module-scoped file service with hybrid layout:
/// users/<uid>/<module>/index.json
/// users/<uid>/<module>/tasks/<taskId>.json
/// users/<uid>/<module>/media/<taskId>/...
class FileStorageService {
  final bool enableWorkspaceMirror;
  FileStorageService({this.enableWorkspaceMirror = true});

  Future<Directory> _docsDir() async => getApplicationDocumentsDirectory();

  Future<Directory> moduleDir(String uid, String module) async {
    final docs = await _docsDir();
    final dir = Directory(p.join(docs.path, 'users', uid, module));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> moduleFile(String uid, String module, String relativePath) async {
    final base = await moduleDir(uid, module);
    final full = p.join(base.path, relativePath);
    final parent = Directory(p.dirname(full));
    if (!await parent.exists()) await parent.create(recursive: true);
    return File(full);
  }

  Future<File> moduleIndexFile(String uid, String module) =>
      moduleFile(uid, module, 'index.json');

  Future<File> taskFile(String uid, String module, String taskId) =>
      moduleFile(uid, module, p.join('tasks', '$taskId.json'));

  Future<Directory> mediaDirForTask(String uid, String module, String taskId) async {
    final d = await moduleDir(uid, module);
    final m = Directory(p.join(d.path, 'media', taskId));
    if (!await m.exists()) await m.create(recursive: true);
    return m;
  }

  Future<String> resolveModuleAbsolute(
      String uid, String module, String pathOrRelative) async {
    if (p.isAbsolute(pathOrRelative)) return pathOrRelative;
    final base = await moduleDir(uid, module);
    return p.join(base.path, pathOrRelative);
  }

  Future<List<dynamic>> readJsonArray(File f) async {
    if (!await f.exists()) return [];
    final text = await f.readAsString();
    if (text.trim().isEmpty) return [];
    final decoded = json.decode(text);
    return decoded is List ? decoded : [];
  }

  Future<Map<String, dynamic>> readJsonObject(File f) async {
    if (!await f.exists()) return {};
    final text = await f.readAsString();
    if (text.trim().isEmpty) return {};
    final decoded = json.decode(text);
    return decoded is Map<String, dynamic> ? decoded : {};
  }

  Future<void> writeJsonArray(File f, List<dynamic> value, {String? mirrorRelative}) async {
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(json.encode(value));
    await tmp.rename(f.path);
    await _maybeMirror(json.encode(value), mirrorRelative);
  }

  Future<void> writeJsonObject(File f, Map<String, dynamic> value, {String? mirrorRelative}) async {
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(json.encode(value));
    await tmp.rename(f.path);
    await _maybeMirror(json.encode(value), mirrorRelative);
  }

  Future<String> saveMediaBytes({
    required String uid,
    required String module,
    required String taskId,
    required String fileName,
    required List<int> bytes,
  }) async {
    final dir = await mediaDirForTask(uid, module, taskId);
    final file = File(p.join(dir.path, fileName));
    await file.writeAsBytes(bytes, flush: true);
    return p.join('media', taskId, fileName); // relative
  }

  Future<String> saveMediaFromFilePath({
    required String uid,
    required String module,
    required String taskId,
    required String sourcePath,
    String? preferredFileName,
  }) async {
    final source = File(sourcePath);
    final bytes = await source.readAsBytes();
    final ext = p.extension(sourcePath).isNotEmpty ? p.extension(sourcePath) : '.jpg';
    final name = preferredFileName ?? _uniqueName(ext: ext);
    return saveMediaBytes(
      uid: uid, module: module, taskId: taskId, fileName: name, bytes: bytes,
    );
  }

  String _uniqueName({String ext = '.jpg'}) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'img_$ts$ext';
  }

  Future<void> deleteTaskMedia(String uid, String module, String taskId) async {
    final dir = await mediaDirForTask(uid, module, taskId);
    if (await dir.exists()) {
      try { await dir.delete(recursive: true); } catch (_) {}
    }
  }

  /// DEBUG: delete the entire local "users" tree (all users & modules).
  Future<void> deleteAllUsersTree() async {
    final docs = await _docsDir();
    final usersRoot = Directory(p.join(docs.path, 'users'));
    if (await usersRoot.exists()) {
      try { await usersRoot.delete(recursive: true); } catch (_) {}
    }
    if (enableWorkspaceMirror && kDebugMode &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final dbg = Directory(p.join(Directory.current.path, '.debug_data'));
      if (await dbg.exists()) {
        try { await dbg.delete(recursive: true); } catch (_) {}
      }
    }
  }

  Future<void> _maybeMirror(String content, String? relative) async {
    if (!enableWorkspaceMirror || relative == null) return;
    if (!kDebugMode) return;
    if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) return;

    final root = Directory(p.join(Directory.current.path, '.debug_data'));
    final mirrorFile = File(p.join(root.path, relative));
    final parent = Directory(p.dirname(mirrorFile.path));
    if (!await parent.exists()) await parent.create(recursive: true);
    await mirrorFile.writeAsString(content);
  }
}
