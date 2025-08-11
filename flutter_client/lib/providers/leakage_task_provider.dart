import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/leakage_task.dart';
import '../repositories/task_repository.dart';
import 'repository_providers.dart';
import 'user_provider.dart';

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

  /// Change task lifecycle state. Optionally set decision/closedResult.
  Future<void> setTaskState(
    String taskId,
    LeakageTaskState newState, {
    String? decision,
    String? closedResult,
  }) async {
    final task = getById(taskId);
    if (task == null) return;

    final updated = task.copyWith(
      state: newState,
      decision: decision ?? task.decision,
      closedResult: closedResult ?? task.closedResult,
    );
    await upsertTask(updated);
  }

  /// Convenience helpers
  Future<void> markOpen(String taskId) => setTaskState(taskId, LeakageTaskState.open);
  Future<void> markClosed(String taskId, {String? decision, String? closedResult}) =>
      setTaskState(taskId, LeakageTaskState.closed,
          decision: decision, closedResult: closedResult);
  Future<void> markDraft(String taskId) => setTaskState(taskId, LeakageTaskState.draft);

  /// Submit for analysis (mock backend). Writes report, then moves to OPEN.
  Future<void> submitForAnalysis(String taskId, {int detectedCount = 2}) async {
    final task = getById(taskId);
    if (task == null) return;

    final backend = ref.read(backendApiServiceProvider);
    final report = await backend.analyzeLeakageTask(task, detectedCount: detectedCount);

    final updated = task.copyWith(
      report: report,
      state: LeakageTaskState.open, // move to OPEN after analysis available
    );

    await upsertTask(updated);
  }
}
