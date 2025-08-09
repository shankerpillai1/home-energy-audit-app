// lib/providers/repository_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/leakage_task.dart';              // <-- needed for _NullTaskRepository
import '../services/file_storage_service.dart';
import '../repositories/task_repository.dart';
import '../repositories/file_task_repository.dart';
import '../services/backend_api_service.dart';
import 'user_provider.dart';

final fileStorageServiceProvider = Provider<FileStorageService>((ref) {
  return FileStorageService(enableWorkspaceMirror: true);
});

/// Provide a real repo only after login; otherwise a no-op repo that does nothing.
/// This prevents creating users/local/... directories before login.
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final fs = ref.read(fileStorageServiceProvider);
  final user = ref.watch(userProvider);
  final uid = user.uid?.trim();
  if (uid == null || uid.isEmpty) {
    return _NullTaskRepository();
  }
  return FileTaskRepository(fs, uid: uid, module: 'leakage');
});

/// Backend is nullable before login.
final backendApiServiceProvider = Provider<BackendApiService?>((ref) {
  final fs = ref.read(fileStorageServiceProvider);
  final user = ref.watch(userProvider);
  final uid = user.uid?.trim();
  if (uid == null || uid.isEmpty) return null;
  return BackendApiService(fs: fs, uid: uid, module: 'leakage');
});

/// Minimal no-op repository used when not logged in.
class _NullTaskRepository implements TaskRepository {
  @override
  Future<void> delete(String id) async {}

  @override
  Future<List<LeakageTask>> fetchAll() async => const [];

  @override
  Future<LeakageTask?> fetchById(String id) async => null;

  @override
  Future<void> upsert(LeakageTask task) async {}
}
