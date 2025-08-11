import 'dart:io';

import 'package:flutter/foundation.dart'; // debugPrint
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import '../../../models/leakage_task.dart';
import '../../../providers/leakage_task_provider.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/user_provider.dart';

class LeakageDashboardPage extends ConsumerWidget {
  const LeakageDashboardPage({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(leakageTaskListProvider.notifier);
    final tasks = ref.watch(leakageTaskListProvider);

    final drafts = tasks.where((t) => t.state == LeakageTaskState.draft).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final opens = tasks.where((t) => t.state == LeakageTaskState.open).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final closeds = tasks.where((t) => t.state == LeakageTaskState.closed).toList()
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
              subtitle: const Text('Swipe a task left to Delete. Use state chips to Open/Close.'),
              onTap: () {},
            ),
          ),

          const SizedBox(height: 16),

          // New task card
          Card(
            child: ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Start New Leak Test'),
              onTap: () {
                final id = DateTime.now().microsecondsSinceEpoch.toString();
                notifier.upsertTask(LeakageTask(id: id, title: '', type: '', state: LeakageTaskState.draft));
                context.push('/leakage/task/$id');
              },
            ),
          ),

          const SizedBox(height: 16),

          // State buckets -> open bottom sheets (no inline expansion)
          _BucketCard(
            icon: Icons.edit_note,
            title: 'Draft',
            count: drafts.length,
            onTap: () => _showTaskListSheet(context, ref, 'Draft', drafts),
          ),
          const SizedBox(height: 12),
          _BucketCard(
            icon: Icons.play_circle_outline,
            title: 'Open',
            count: opens.length,
            onTap: () => _showTaskListSheet(context, ref, 'Open', opens),
          ),
          const SizedBox(height: 12),
          _BucketCard(
            icon: Icons.check_circle_outline,
            title: 'Closed',
            count: closeds.length,
            onTap: () => _showTaskListSheet(context, ref, 'Closed', closeds),
          ),
        ],
      ),
    );
  }

  void _showTaskListSheet(
    BuildContext context,
    WidgetRef ref,
    String title,
    List<LeakageTask> tasks,
  ) {
    final notifier = ref.read(leakageTaskListProvider.notifier);
    final fs = ref.read(fileStorageServiceProvider);
    final user = ref.read(userProvider);
    final uid = (user.uid?.trim().isNotEmpty == true) ? user.uid!.trim() : 'local';

    Future<Widget> thumb(LeakageTask t) async {
      // Choose the first RGB (even index) else any
      String? rel;
      for (int i = 0; i < t.photoPaths.length; i++) {
        if (i % 2 == 0) {
          rel = t.photoPaths[i];
          break;
        }
      }
      rel ??= t.photoPaths.isNotEmpty ? t.photoPaths.first : null;
      if (rel == null) {
        return const SizedBox(
          width: 56,
          height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(color: Color(0xFFE0E0E0)),
            child: Icon(Icons.image_not_supported),
          ),
        );
      }
      final abs = await fs.resolveModuleAbsolute(uid, 'leakage', rel);
      if (!File(abs).existsSync()) {
        return const SizedBox(
          width: 56,
          height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(color: Color(0xFFE0E0E0)),
            child: Icon(Icons.image_not_supported),
          ),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(File(abs), width: 56, height: 56, fit: BoxFit.cover),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.66,
        minChildSize: 0.38,
        maxChildSize: 0.9,
        builder: (ctx, scrollCtrl) {
          return Column(
            children: [
              ListTile(
                title: Text('$title Tasks', style: Theme.of(ctx).textTheme.titleMedium),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  controller: scrollCtrl,
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final t = tasks[i];
                    return Slidable(
                      key: Key('sheet-${t.id}'),
                      endActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        extentRatio: 0.22,
                        children: [
                          SlidableAction(
                            onPressed: (_) => ref.read(leakageTaskListProvider.notifier).deleteTask(t.id),
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            label: 'Delete',
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: FutureBuilder<Widget>(
                          future: thumb(t),
                          builder: (c, s) => s.data ?? const SizedBox(width: 56, height: 56),
                        ),
                        title: Text(t.title.isEmpty ? 'Untitled Task' : t.title),
                        onTap: () {
                          // If open -> go report; else -> go edit
                          if (t.state == LeakageTaskState.open || t.state == LeakageTaskState.closed) {
                            context.push('/leakage/report/${t.id}');
                          } else {
                            context.push('/leakage/task/${t.id}');
                          }
                        },
                        trailing: _StateQuickActions(task: t, onChange: (newState) async {
                          switch (newState) {
                            case LeakageTaskState.draft:
                              await notifier.markDraft(t.id);
                              break;
                            case LeakageTaskState.open:
                              await notifier.markOpen(t.id);
                              break;
                            case LeakageTaskState.closed:
                              await notifier.markClosed(t.id);
                              break;
                          }
                        }),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BucketCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final VoidCallback onTap;

  const _BucketCard({
    super.key,
    required this.icon,
    required this.title,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: Icon(icon, color: cs.primary),
        title: Text(title),
        subtitle: Text('$count task(s)'),
        trailing: const Icon(Icons.keyboard_arrow_up), // indicates bottom sheet
        onTap: onTap,
      ),
    );
  }
}

/// Small trailing control to quickly move a task between states.
class _StateQuickActions extends StatelessWidget {
  final LeakageTask task;
  final ValueChanged<LeakageTaskState> onChange;

  const _StateQuickActions({super.key, required this.task, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final current = task.state;
    return PopupMenuButton<LeakageTaskState>(
      tooltip: 'Change state',
      icon: const Icon(Icons.swap_horiz),
      onSelected: onChange,
      itemBuilder: (ctx) => [
        CheckedPopupMenuItem(
          value: LeakageTaskState.draft,
          checked: current == LeakageTaskState.draft,
          child: const Text('Draft'),
        ),
        CheckedPopupMenuItem(
          value: LeakageTaskState.open,
          checked: current == LeakageTaskState.open,
          child: const Text('Open'),
        ),
        CheckedPopupMenuItem(
          value: LeakageTaskState.closed,
          checked: current == LeakageTaskState.closed,
          child: const Text('Closed'),
        ),
      ],
    );
  }
}
