import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/file_storage_service.dart';
import '../repositories/task_repository.dart';
import '../repositories/file_backed_task_repository.dart'; // <-- renamed impl (see below)
import 'user_provider.dart';
import '../services/backend_api_service.dart';

/// Low-level file service (with optional workspace mirror for debug).
final fileStorageServiceProvider = Provider<FileStorageService>((ref) {
  return FileStorageService(enableWorkspaceMirror: true);
});

/// Non-null leakage task repository scoped by current user id.
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final fs = ref.read(fileStorageServiceProvider);
  final user = ref.watch(userProvider);
  final uid = (user.uid?.trim().isNotEmpty == true) ? user.uid!.trim() : 'local';
  return FileBackedTaskRepository(fs, uid: uid, module: 'leakage');
});

/// Non-null simulated backend.
final backendApiServiceProvider = Provider<BackendApiService>((ref) {
  final fs = ref.read(fileStorageServiceProvider);
  final user = ref.watch(userProvider);
  final uid = (user.uid?.trim().isNotEmpty == true) ? user.uid!.trim() : 'local';
  return BackendApiService(fs: fs, uid: uid, module: 'leakage');
});
