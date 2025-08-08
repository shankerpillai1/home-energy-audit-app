import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/file_storage_service.dart';
import '../repositories/task_repository.dart';
import '../repositories/file_task_repository.dart';
import '../services/backend_api_service.dart';
import 'user_provider.dart';

final fileStorageServiceProvider = Provider<FileStorageService>((ref) {
  return FileStorageService(enableWorkspaceMirror: true);
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final fs = ref.read(fileStorageServiceProvider);
  final user = ref.watch(userProvider);
  final uid = (user.uid?.trim().isNotEmpty == true) ? user.uid!.trim() : 'local';
  return FileTaskRepository(fs, uid: uid, module: 'leakage');
});

final backendApiServiceProvider = Provider<BackendApiService>((ref) {
  final fs = ref.read(fileStorageServiceProvider);
  final user = ref.watch(userProvider);
  final uid = (user.uid?.trim().isNotEmpty == true) ? user.uid!.trim() : 'local';
  return BackendApiService(fs: fs, uid: uid, module: 'leakage');
});
