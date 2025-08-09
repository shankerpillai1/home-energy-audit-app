import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../models/leakage_task.dart';
import '../../../providers/leakage_task_provider.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/user_provider.dart';
import '../../../repositories/task_repository.dart';

class LeakageDashboardPage extends ConsumerWidget {
  const LeakageDashboardPage({Key? key}) : super(key: key);

  Future<void> _debugPrintStore(BuildContext context, WidgetRef ref) async {
    final fs = ref.read(fileStorageServiceProvider);
    final repo = ref.read(taskRepositoryProvider);
    final user = ref.read(userProvider);
    final uid = user.uid?.trim();

    if (uid == null || uid.isEmpty) {
      debugPrint('No uid yet; not printing.');
      return;
    }

    final indexFile = await fs.moduleIndexFile(uid, 'leakage');
    debugPrint('leakage index.json path: ${indexFile.path}');
    if (await indexFile.exists()) {
      final content = await indexFile.readAsString();
      debugPrint('leakage index.json content:\n$content');
    } else {
      debugPrint('leakage index.json does not exist yet.');
    }

    final tasks = await repo.fetchAll();
    debugPrint('Repository loaded tasks: ${tasks.length} item(s).');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Printed index.json & task count to console')),
    );
  }

  bool _isCompleted(LeakageTask t) {
    final r = t.report;
    if (r == null) return false;
    final anySummary = r.energyLossCost != null ||
        r.energyLossValue != null ||
        r.leakSeverity != null ||
        r.savingsCost != null ||
        r.savingsPercent != null;
    return anySummary || r.points.isNotEmpty;
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, LeakageTask task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('This will remove "${task.title.isEmpty ? 'Untitled Task' : task.title}".'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(leakageTaskListProvider.notifier).deleteTask(task.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Task deleted'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      ref.read(leakageTaskListProvider.notifier).upsertTask(task);
                    },
                  ),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openTaskListSheet({
    required BuildContext context,
    required WidgetRef ref,
    required List<LeakageTask> tasks,
    required String title,
    required bool isCompletedList,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          builder: (ctx, scrollCtrl) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  // Grip
                  Container(
                    width: 36,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // Header
                  Row(
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      Text('${tasks.length} item(s)'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // List
                  Expanded(
                    child: tasks.isEmpty
                        ? Center(
                            child: Text(
                              isCompletedList ? 'No completed tasks' : 'No tasks in progress',
                            ),
                          )
                        : ListView.separated(
                            controller: scrollCtrl,
                            itemCount: tasks.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (ctx, i) {
                              final task = tasks[i];
                              return Slidable(
                                key: Key('${isCompletedList ? "done" : "in"}-${task.id}'),
                                endActionPane: ActionPane(
                                  motion: const DrawerMotion(),
                                  extentRatio: 0.22,
                                  children: [
                                    SlidableAction(
                                      onPressed: (_) {
                                        Navigator.pop(ctx); // close sheet first
                                        _confirmDelete(context, ref, task);
                                      },
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      icon: Icons.delete,
                                      label: 'Delete',
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  leading: _TaskThumb(task: task, size: 48),
                                  title: Text(task.title.isEmpty ? 'Untitled Task' : task.title),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    if (isCompletedList) {
                                      context.push('/leakage/report/${task.id}');
                                    } else {
                                      context.push('/leakage/task/${task.id}');
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(leakageTaskListProvider.notifier);
    final tasks = ref.watch(leakageTaskListProvider);

    final inProgress = tasks.where((t) => !_isCompleted(t)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final completed = tasks.where(_isCompleted).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text('Leakage Detection'),
        actions: [
          IconButton(
            tooltip: 'Print store debug info',
            icon: const Icon(Icons.bug_report),
            onPressed: () => _debugPrintStore(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tutorial card
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('How to Perform a Leakage Test'),
              subtitle: const Text('Swipe a task left to delete. Tap a section to view tasks.'),
              onTap: () {
                // TODO: navigate to a detailed tutorial page
              },
            ),
          ),

          const SizedBox(height: 16),

          // New task card
          Card(
            child: ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Start New Leak Test'),
              onTap: () {
                final newId = const Uuid().v4();
                notifier.upsertTask(LeakageTask(id: newId, title: '', type: ''));
                context.push('/leakage/task/$newId');
              },
            ),
          ),

          const SizedBox(height: 16),

          // In-progress section (opens a bottom sheet)
          Card(
            child: ListTile(
              leading: const Icon(Icons.pending),
              title: const Text('In-Progress Tasks'),
              subtitle: Text('${inProgress.length} item(s)'),
              onTap: () => _openTaskListSheet(
                context: context,
                ref: ref,
                tasks: inProgress,
                title: 'In-Progress Tasks',
                isCompletedList: false,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Completed section
          Card(
            child: ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Completed Tasks'),
              subtitle: Text('${completed.length} item(s)'),
              onTap: () => _openTaskListSheet(
                context: context,
                ref: ref,
                tasks: completed,
                title: 'Completed Tasks',
                isCompletedList: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskThumb extends ConsumerWidget {
  final LeakageTask task;
  final double size;
  const _TaskThumb({Key? key, required this.task, this.size = 48}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fs = ref.read(fileStorageServiceProvider);
    final user = ref.read(userProvider);
    final uid = user.uid?.trim();

    if (uid == null || uid.isEmpty) {
      return _placeholder(size);
    }

    // Prefer the first image (usually RGB), otherwise fallback to any.
    String? _firstImageRel() {
      if (task.photoPaths.isEmpty) return null;
      return task.photoPaths.first;
    }

    Future<String?> _absOrNull(String? relOrAbs) async {
      if (relOrAbs == null) return null;
      return await fs.resolveModuleAbsolute(uid, 'leakage', relOrAbs);
    }

    final rel = _firstImageRel();

    return FutureBuilder<String?>(
      future: _absOrNull(rel),
      builder: (context, snap) {
        final path = snap.data;
        if (path == null || !File(path).existsSync()) {
          return _placeholder(size);
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.file(File(path), width: size, height: size, fit: BoxFit.cover),
        );
      },
    );
  }

  Widget _placeholder(double s) => Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: Colors.grey.shade300,
        ),
        child: const Icon(Icons.image, size: 20, color: Colors.black45),
      );
}
