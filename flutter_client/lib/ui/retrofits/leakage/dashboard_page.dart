import 'dart:io';
import 'dart:async';

// debugPrint
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
              subtitle: const Text('Swipe a task left to Delete. Use state menu to switch Draft/Open/Closed.'),
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
                // Provide sensible defaults for better first-run UX.
                notifier.upsertTask(
                  LeakageTask(
                    id: id,
                    title: 'Untitled Task',
                    type: 'window',
                    state: LeakageTaskState.draft,
                  ),
                );
                context.push('/leakage/task/$id');
              },
            ),
          ),

          const SizedBox(height: 16),

          // State buckets -> open bottom sheets (live lists)
          _BucketCard(
            icon: Icons.edit_note,
            title: 'Draft',
            count: drafts.length,
            onTap: () => _openBucketSheet(context, LeakageTaskState.draft),
          ),
          const SizedBox(height: 12),
          _BucketCard(
            icon: Icons.play_circle_outline,
            title: 'Open',
            count: opens.length,
            onTap: () => _openBucketSheet(context, LeakageTaskState.open),
          ),
          const SizedBox(height: 12),
          _BucketCard(
            icon: Icons.check_circle_outline,
            title: 'Closed',
            count: closeds.length,
            onTap: () => _openBucketSheet(context, LeakageTaskState.closed),
          ),
        ],
      ),
    );
  }

  void _openBucketSheet(BuildContext context, LeakageTaskState bucket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _TaskListSheet(bucket: bucket),
    );
  }
}

class _TaskListSheet extends ConsumerStatefulWidget {
  final LeakageTaskState bucket;
  const _TaskListSheet({required this.bucket});

  @override
  ConsumerState<_TaskListSheet> createState() => _TaskListSheetState();
}

class _TaskListSheetState extends ConsumerState<_TaskListSheet> {
  // In-sheet undo banner state
  String? _pendingUndoId;
  String _pendingUndoTitle = '';
  Timer? _undoHideTimer;

  static const Duration _undoWindow = Duration(seconds: 5);

  @override
  void dispose() {
    _undoHideTimer?.cancel();
    super.dispose();
  }

  Future<Widget> _thumb(LeakageTask t) async {
    final fs = ref.read(fileStorageServiceProvider);
    final user = ref.read(userProvider);
    final uid = (user.uid?.trim().isNotEmpty == true) ? user.uid!.trim() : 'local';

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

  void _showUndoBanner(String id, String title) {
    _undoHideTimer?.cancel();
    setState(() {
      _pendingUndoId = id;
      _pendingUndoTitle = title;
    });
    _undoHideTimer = Timer(_undoWindow, () {
      if (mounted) {
        setState(() {
          _pendingUndoId = null;
          _pendingUndoTitle = '';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(leakageTaskListProvider);
    final tasks = all.where((t) => t.state == widget.bucket).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.66,
      minChildSize: 0.38,
      maxChildSize: 0.9,
      builder: (ctx, scrollCtrl) {
        return Column(
          children: [
            ListTile(
              title: Text('${_bucketTitle(widget.bucket)} Tasks', style: Theme.of(ctx).textTheme.titleMedium),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),

            // In-sheet undo banner (visible above the list, not hidden by the sheet)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: (_pendingUndoId == null)
                  ? const SizedBox.shrink()
                  : Container(
                      key: const ValueKey('undo-banner'),
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.inversePrimary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Theme.of(context).colorScheme.inversePrimary),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('Deleted "$_pendingUndoTitle"', maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () async {
                              final id = _pendingUndoId!;
                              await ref.read(leakageTaskListProvider.notifier).undoDelete(id);
                              if (!mounted) return;
                              setState(() {
                                _pendingUndoId = null;
                                _pendingUndoTitle = '';
                              });
                            },
                            child: const Text('UNDO'),
                          ),
                        ],
                      ),
                    ),
            ),

            const Divider(height: 1),

            if (tasks.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inbox, size: 40, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text('No tasks in this bucket', style: Theme.of(ctx).textTheme.bodyLarge),
                    ],
                  ),
                ),
              )
            else
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
                        extentRatio: 0.18, // compact, icon-only
                        children: [
                          CustomSlidableAction(
                            onPressed: (_) async {
                              final title = t.title.isEmpty ? 'Untitled Task' : t.title;
                              // Soft delete with undo window (provider handles delayed physical delete).
                              ref.read(leakageTaskListProvider.notifier).scheduleDeleteWithUndo(t.id);
                              // Show in-sheet undo banner so it's not hidden by the bottom sheet.
                              _showUndoBanner(t.id, title);
                            },
                            backgroundColor: Colors.red,
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: FutureBuilder<Widget>(
                          future: _thumb(t),
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
                          final notifier = ref.read(leakageTaskListProvider.notifier);
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
    );
  }

  String _bucketTitle(LeakageTaskState s) {
    switch (s) {
      case LeakageTaskState.draft:
        return 'Draft';
      case LeakageTaskState.open:
        return 'Open';
      case LeakageTaskState.closed:
        return 'Closed';
    }
  }
}

class _BucketCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final VoidCallback onTap;

  const _BucketCard({
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

  const _StateQuickActions({required this.task, required this.onChange});

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
