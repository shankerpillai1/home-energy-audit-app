import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/leakage_task.dart';
import '../repositories/task_repository.dart';
import 'repository_providers.dart';
import 'user_provider.dart';

/// Transport channel for analysis (optional param when submitting).
/// Default remains [mock] to keep existing behavior unchanged.
enum AnalysisTransport {
  mock, // local mock analysis
  http, // HTTP pipeline implemented in BackendApiService.analyzeLeakageTaskHttp()
}

/// Expose the list of leakage tasks.
final leakageTaskListProvider =
    StateNotifierProvider<LeakageTaskListNotifier, List<LeakageTask>>(
  (ref) => LeakageTaskListNotifier(ref),
);

class LeakageTaskListNotifier extends StateNotifier<List<LeakageTask>> {
  final Ref ref;
  late TaskRepository _repo;

  /// Pending delete timers and snapshots for undo.
  final Map<String, Timer> _pendingDeleteTimers = {};
  final Map<String, LeakageTask> _pendingDeleteSnapshots = {};

  /// Grace period for undo.
  static const Duration _kDeleteUndoWindow = Duration(seconds: 5);

  LeakageTaskListNotifier(this.ref) : super(const []) {
    _repo = ref.read(taskRepositoryProvider);
    _load();

    // Reload when user switches (login/logout).
    ref.listen(userProvider, (prev, next) {
      final prevUid = prev?.uid;
      final nextUid = next.uid;
      if (prevUid != nextUid) {
        _repo = ref.read(taskRepositoryProvider);
        _load();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Internal load
  // ---------------------------------------------------------------------------

  Future<void> _load() async {
    final list = await _repo.fetchAll();
    state = List.unmodifiable(list);
  }

  // ---------------------------------------------------------------------------
  // Compatibility methods (kept as in your original code)
  // ---------------------------------------------------------------------------

  /// Clear in-memory tasks (used when clearing local cache via Account page).
  void resetAll() {
    state = const [];
  }

  /// Get a task by id, or null if not found.
  LeakageTask? getById(String id) {
    try {
      return state.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Upsert a task and update in-memory list without reloading everything.
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

  /// Delete a task immediately (physical delete via repository) and update state.
  Future<void> deleteTask(String id) async {
    // Cancel any pending soft delete for this id.
    await _cancelPendingDelete(id);

    await _repo.delete(id);
    state = List.unmodifiable(state.where((t) => t.id != id));
  }

  /// SOFT DELETE with UNDO window.
  /// - Immediately removes the task from in-memory list (so UI updates).
  /// - Starts a timer; when it fires, performs physical delete via repository.
  /// - If user calls [undoDelete(id)] within the window, we cancel and restore.
  void scheduleDeleteWithUndo(String id, {Duration? grace}) {
    // If already scheduled, ignore duplicate presses.
    if (_pendingDeleteTimers.containsKey(id)) return;

    final task = getById(id);
    if (task == null) return;

    // Keep a snapshot for potential restore.
    _pendingDeleteSnapshots[id] = task;

    // Remove from in-memory state immediately for instant UI feedback.
    state = List.unmodifiable(state.where((t) => t.id != id));

    // Start the timer for physical delete.
    final timer = Timer(grace ?? _kDeleteUndoWindow, () async {
      _pendingDeleteTimers.remove(id);

      // If another operation already removed the snapshot, abort.
      final snap = _pendingDeleteSnapshots.remove(id);
      if (snap == null) return;

      // Physical delete on repository; repository is expected to delete media too.
      // If your repository doesn't remove media, add a deletion call inside repository.
      await _repo.delete(id);
      // Done: nothing else to update; state already removed.
    });

    _pendingDeleteTimers[id] = timer;
  }

  /// Undo a previously scheduled delete (within the grace window).
  Future<void> undoDelete(String id) async {
    // Cancel the timer if still pending.
    final t = _pendingDeleteTimers.remove(id);
    t?.cancel();

    // Restore snapshot if we still have it.
    final snap = _pendingDeleteSnapshots.remove(id);
    if (snap != null) {
      await _repo.upsert(snap);
      // Put it back into in-memory state.
      final list = [...state];
      list.add(snap);
      // Keep order by createdAt desc (same as other places)
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = List.unmodifiable(list);
    }
  }

  Future<void> _cancelPendingDelete(String id) async {
    final t = _pendingDeleteTimers.remove(id);
    t?.cancel();
    _pendingDeleteSnapshots.remove(id);
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

  /// Convenience helpers (kept)
  Future<void> markOpen(String taskId) =>
      setTaskState(taskId, LeakageTaskState.open);

  Future<void> markClosed(
    String taskId, {
    String? decision,
    String? closedResult,
  }) =>
      setTaskState(
        taskId,
        LeakageTaskState.closed,
        decision: decision,
        closedResult: closedResult,
      );

  Future<void> markDraft(String taskId) =>
      setTaskState(taskId, LeakageTaskState.draft);

  // ---------------------------------------------------------------------------
  // Submit & analyze (mock or HTTP dry-run/real, controlled by providers)
  // ---------------------------------------------------------------------------

  Future<void> submitForAnalysis(
    String taskId, {
    int detectedCount = 2,
    AnalysisTransport? transport,
    bool? httpDryRun,
  }) async {
    final task = getById(taskId);
    if (task == null) return;

    final backend = ref.read(backendApiServiceProvider);

    // Decide which pipeline to use:
    final useHttpGlobal = ref.read(useHttpForAnalysisProvider);
    final mode = transport ??
        (useHttpGlobal ? AnalysisTransport.http : AnalysisTransport.mock);

    LeakReport report;

    if (mode == AnalysisTransport.mock) {
      report = await backend.analyzeLeakageTask(
        task,
        detectedCount: detectedCount,
      );
    } else {
      final bool dry = httpDryRun ?? ref.read(httpDryRunSettingProvider);
      report = await backend.analyzeLeakageTaskHttp(
        task,
        overrideDetectedCount: detectedCount,
        dryRun: dry,
      );
    }

    // Persist as OPEN with the returned report
    final updated = task.copyWith(
      report: report,
      state: LeakageTaskState.open,
    );
    await upsertTask(updated);
  }
}
