// lib/ui/modules/leakage/leakage_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:uuid/uuid.dart';

import '../../../models/leakage_task.dart';
import '../../../state/leakage_task_provider.dart';

class LeakageDashboardPage extends ConsumerWidget {
  const LeakageDashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(leakageTaskListProvider.notifier);
    final tasks = ref.watch(leakageTaskListProvider);
    final inProgress = tasks.where((t) => t.analysisSummary == null).toList();
    final completed = tasks.where((t) => t.analysisSummary != null).toList();

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
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tutorial Card
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('How to Perform a Leakage Test'),
              subtitle: const Text(
                  'Swipe left on a task to reveal "Delete". Tap here to learn more.'),
              onTap: () {
                // TODO: Navigate to detailed tutorial screen
              },
            ),
          ),

          const SizedBox(height: 16),

          // New Task Card
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

          // In-Progress Tasks with Slidable
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.pending),
              title: const Text('In-Progress Tasks'),
              children: inProgress.isNotEmpty
                  ? inProgress.map((task) {
                      return Slidable(
                        key: Key('in-${task.id}'),
                        // swipe from right to left
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          extentRatio: 0.25,
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
                              task.title.isEmpty ? 'Untitled Task' : task.title),
                          subtitle: Text(
                            'Created: ${task.createdAt.toLocal().toString().split('.').first}',
                          ),
                          onTap: () => context.push('/leakage/task/${task.id}'),
                        ),
                      );
                    }).toList()
                  : [
                      const ListTile(title: Text('No tasks in progress')),
                    ],
            ),
          ),

          const SizedBox(height: 16),

          // Completed Tasks with Slidable
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Completed Tasks'),
              children: completed.isNotEmpty
                  ? completed.map((task) {
                      return Slidable(
                        key: Key('done-${task.id}'),
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          extentRatio: 0.25,
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
                          title: Text(task.title),
                          subtitle: Text(
                            'Analyzed: ${task.createdAt.toLocal().toString().split('.').first}',
                          ),
                          onTap: () => context.push('/leakage/report/${task.id}'),
                        ),
                      );
                    }).toList()
                  : [
                      const ListTile(title: Text('No completed tasks')),
                    ],
            ),
          ),
        ],
      ),
    );
  }
}
