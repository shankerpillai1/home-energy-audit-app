import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import '../services/file_storage_service.dart';

/// Copies an asset into the module-scoped directory and returns a RELATIVE path
/// (e.g., "templates/thermal_template.jpg").
/// If the file already exists, it is reused.
class AssetToFile {
  final FileStorageService fs;
  final String uid;
  final String module;

  AssetToFile(this.fs, {required this.uid, required this.module});

  Future<String> ensureCopied({
    required String assetPath,
    String targetRelativePath = 'templates/thermal_template.jpg',
  }) async {
    final target = await fs.moduleFile(uid, module, targetRelativePath);
    if (await target.exists()) {
      return targetRelativePath;
    }
    final data = await rootBundle.load(assetPath);
    final bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    final parent = Directory(p.dirname(target.path));
    if (!await parent.exists()) await parent.create(recursive: true);
    await target.writeAsBytes(bytes, flush: true);
    return targetRelativePath;
  }
}
