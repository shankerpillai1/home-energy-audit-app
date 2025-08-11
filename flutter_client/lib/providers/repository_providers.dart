import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/file_storage_service.dart';
import '../repositories/task_repository.dart';
import '../repositories/file_backed_task_repository.dart';
import '../services/backend_api_service.dart';
import 'user_provider.dart';

/// ===== Toggle switches for analysis transport (build-time friendly) =====
/// Set to true to route analysis to the HTTP pipeline by default.
/// If false, the app uses the local mock analysis (existing behavior).
const bool kUseHttpForAnalysis = true;

/// When using HTTP, you can choose to do a "dry-run":
/// - true  -> do not send real network requests; return a backend-like JSON and test the mapping.
/// - false -> actually call your backend (you must set kBackendBaseUrl below).
const bool kHttpDryRunDefault = true;

/// ===== Backend HTTP config (only used if/when you enable HTTP) =====
/// Replace with your real API base URL, e.g. https://api.your-domain.com
const String kBackendBaseUrl = 'https://api.example.com'; // TODO: change me
/// Optional API key/token if your backend needs it (add "Bearer " prefix in service).
const String? kBackendApiKey = null; // e.g. 'YOUR_TOKEN'

/// File storage service (used by repositories and backend to resolve media files).
final fileStorageServiceProvider = Provider<FileStorageService>((ref) {
  return FileStorageService(enableWorkspaceMirror: true); // dev helper
});

/// Task repository — file-backed implementation (source of truth on device).
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final fs = ref.read(fileStorageServiceProvider);
  final user = ref.watch(userProvider);
  final uid = (user.uid?.trim().isNotEmpty == true) ? user.uid!.trim() : 'local';
  return FileBackedTaskRepository(fs, uid: uid, module: 'leakage');
});

/// Whether to use HTTP for analysis (read by the LeakageTaskListNotifier).
final useHttpForAnalysisProvider = Provider<bool>((ref) => kUseHttpForAnalysis);

/// Default HTTP dry-run setting (read by the LeakageTaskListNotifier when using HTTP).
final httpDryRunSettingProvider = Provider<bool>((ref) => kHttpDryRunDefault);

/// Backend service provider.
/// - Always constructs the service; HTTP config is present regardless of the current mode.
/// - If you actually call the HTTP method while kBackendBaseUrl is the placeholder,
///   it will fail with an error — that’s expected until you set a real URL.
final backendApiServiceProvider = Provider<BackendApiService>((ref) {
  final fs = ref.read(fileStorageServiceProvider);
  final user = ref.watch(userProvider);
  final uid = (user.uid?.trim().isNotEmpty == true) ? user.uid!.trim() : 'local';

  final cfg = BackendConfig(
    baseUri: Uri.parse(kBackendBaseUrl),
    apiKey: kBackendApiKey,
    // You can tweak timeouts/poll intervals here if needed:
    // timeout: Duration(seconds: 20),
    // pollInterval: Duration(seconds: 2),
    // maxWait: Duration(seconds: 45),
  );

  return BackendApiService(fs: fs, uid: uid, module: 'leakage', config: cfg);
});
