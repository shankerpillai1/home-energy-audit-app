// lib/providers/leakage_task_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/leakage_task.dart';
import '../repositories/task_repository.dart';
import 'repository_providers.dart';
import 'user_provider.dart';
import '../services/backend_api_service.dart';

final leakageTaskListProvider =
    StateNotifierProvider<LeakageTaskListNotifier, List<LeakageTask>>(
  (ref) => LeakageTaskListNotifier(ref),
);

class LeakageTaskListNotifier extends StateNotifier<List<LeakageTask>> {
  final Ref ref;
  late TaskRepository _repo;

  LeakageTaskListNotifier(this.ref) : super(const []) {
    _repo = ref.read(taskRepositoryProvider);
    _load();

    // Reload when user changes (e.g., login/logout/switch)
    ref.listen(userProvider, (prev, next) {
      final prevUid = prev?.uid;
      final nextUid = next.uid;
      if (prevUid != nextUid) {
        _repo = ref.read(taskRepositoryProvider);
        _load();
      }
    });
  }

  Future<void> _load() async {
    final list = await _repo.fetchAll();
    state = List.unmodifiable(list);
  }

  /// Clear in-memory tasks (used when clearing local cache).
  void resetAll() {
    state = const [];
  }

  LeakageTask? getById(String id) {
    try {
      return state.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> upsertTask(LeakageTask task) async {
    await _repo.upsert(task);
    final list = [...state];
    final i = list.indexWhere((t) => t.id == task.id);
    if (i >= 0) {
      list[i] = task;
    } else {
      list.add(task);
    }
    state = List.unmodifiable(list);
  }

  Future<void> deleteTask(String id) async {
    await _repo.delete(id);
    state = List.unmodifiable(state.where((t) => t.id != id));
  }

  /// Submit a task for analysis (mock backend). You can specify how many
  /// leak points to generate (>=0). Writes report back and updates state.
  Future<void> submitForAnalysis(String taskId, {int detectedCount = 2}) async {
    final task = getById(taskId);
    if (task == null) return;

    final backend = ref.read(backendApiServiceProvider);
    final report = await backend.analyzeLeakageTask(task, detectedCount: detectedCount);

    final updated = LeakageTask(
      id: task.id,
      title: task.title,
      type: task.type,
      photoPaths: task.photoPaths,
      createdAt: task.createdAt,
      analysisSummary: task.analysisSummary,
      recommendations: task.recommendations,
      report: report,
    );

    await upsertTask(updated);
  }
}
