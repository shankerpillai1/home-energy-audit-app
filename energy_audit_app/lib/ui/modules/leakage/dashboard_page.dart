// lib/ui/modules/leakage/leakage_dashboard.dart
import 'package:flutter/foundation.dart'; // debugPrint
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

  /// Print index.json path and content, plus number of task files loaded via repository.
  Future<void> _debugPrintStore(BuildContext context, WidgetRef ref) async {
    final fs = ref.read(fileStorageServiceProvider);
    final repo = ref.read(taskRepositoryProvider);
    final user = ref.read(userProvider);
    final uid = (user.uid?.trim().isNotEmpty == true) ? user.uid!.trim() : 'local';

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
              subtitle: const Text(
                  'Swipe a task left to reveal Delete. Tap here to learn more.'),
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
                notifier.upsertTask(
                  LeakageTask(id: newId, title: '', type: ''),
                );
                context.push('/leakage/task/$newId');
              },
            ),
          ),

          const SizedBox(height: 16),

          // In-progress
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.pending),
              title: const Text('In-Progress Tasks'),
              children: inProgress.isNotEmpty
                  ? inProgress.map((task) {
                      return Slidable(
                        key: Key('in-${task.id}'),
                        endActionPane: ActionPane(
                          // DrawerMotion keeps the action revealed until swiped back
                          motion: const DrawerMotion(),
                          extentRatio: 0.22,
                          children: [
                            SlidableAction(
                              onPressed: (_) {
                                notifier.deleteTask(task.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Task deleted'),
                                    action: SnackBarAction(
                                      label: 'Undo',
                                      onPressed: () {
                                        notifier.upsertTask(task);
                                      },
                                    ),
                                  ),
                                );
                              },
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                              label: 'Delete',
                            ),
                          ],
                        ),
                        child: ListTile(
                          title: Text(
                            task.title.isEmpty ? 'Untitled Task' : task.title,
                          ),
                          subtitle: Text(
                            'Created: ${task.createdAt.toLocal().toString().split('.').first}',
                          ),
                          onTap: () => context.push('/leakage/task/${task.id}'),
                        ),
                      );
                    }).toList()
                  : const [ListTile(title: Text('No tasks in progress'))],
            ),
          ),

          const SizedBox(height: 16),

          // Completed
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Completed Tasks'),
              children: completed.isNotEmpty
                  ? completed.map((task) {
                      return Slidable(
                        key: Key('done-${task.id}'),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          extentRatio: 0.22,
                          children: [
                            SlidableAction(
                              onPressed: (_) {
                                notifier.deleteTask(task.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Task deleted'),
                                    action: SnackBarAction(
                                      label: 'Undo',
                                      onPressed: () {
                                        notifier.upsertTask(task);
                                      },
                                    ),
                                  ),
                                );
                              },
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                              label: 'Delete',
                            ),
                          ],
                        ),
                        child: ListTile(
                          title: Text(
                            task.title.isEmpty ? 'Untitled Task' : task.title,
                          ),
                          subtitle: Text(
                            'Analyzed: ${task.createdAt.toLocal().toString().split('.').first}',
                          ),
                          onTap: () => context.push('/leakage/report/${task.id}'),
                        ),
                      );
                    }).toList()
                  : const [ListTile(title: Text('No completed tasks'))],
            ),
          ),
        ],
      ),
    );
  }
}
