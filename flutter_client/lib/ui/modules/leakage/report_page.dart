import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/leakage_task.dart';
import '../../../providers/leakage_task_provider.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/user_provider.dart';

class LeakageReportPage extends ConsumerWidget {
  final String taskId;
  const LeakageReportPage({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(leakageTaskListProvider.notifier);
    final list = ref.watch(leakageTaskListProvider);

    // Safe lookup: from state, fallback to notifier.getById, then guard.
    final task = list.firstWhere(
      (t) => t.id == taskId,
      orElse: () => notifier.getById(taskId) ?? _missingTaskFallback(),
    );
    if (task.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/leakage/dashboard'),
          ),
          title: const Text('Report'),
        ),
        body: const Center(child: Text('Task not found')),
      );
    }

    final report = task.report;
    final cost = report?.energyLossCost ?? '--';
    final energy = report?.energyLossValue ?? '--';
    final sev = report?.leakSeverity ?? '--';
    final saveC = report?.savingsCost ?? '--';
    final saveP = report?.savingsPercent ?? '--';
    final points = report?.points ?? const <LeakReportPoint>[];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/leakage/dashboard'),
        ),
        title: const Text('Report'),
        actions: [
          // Edit entry in AppBar.
          // If currently CLOSED, confirm and reopen to OPEN (keep report), then go edit.
          IconButton(
            tooltip: 'Modify Submission',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              if (task.state == LeakageTaskState.closed) {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Reopen as Open?'),
                    content: const Text(
                        'This report is closed. Editing will reopen it to Open (report preserved). Continue?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reopen')),
                    ],
                  ),
                );
                if (ok != true) return;
                await notifier.markOpen(task.id);
              }
              if (context.mounted) context.go('/leakage/task/$taskId');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Title
          Text(
            (task.title.isNotEmpty) ? task.title : 'Untitled Task',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          // Read-only status badge
          _StatusBadge(state: task.state),
          const SizedBox(height: 12),

          // Keep THREE CARDS IN A ROW; guard against text overflow.
          Row(
            children: [
              Expanded(child: _SmallCard(title: 'Energy Loss', line1: cost, line2: energy)),
              const SizedBox(width: 8),
              Expanded(child: _SmallCard(title: 'Leak Severity', line1: sev, line2: '')),
              const SizedBox(width: 8),
              Expanded(child: _SmallCard(title: 'Potential Savings', line1: saveC, line2: saveP)),
            ],
          ),

          const SizedBox(height: 16),

          if (points.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No points available.', style: Theme.of(context).textTheme.bodyLarge),
              ),
            )
          else
            Column(
              children: points
                  .map((pt) => _PointListTile(
                        taskId: task.id,
                        point: pt,
                      ))
                  .toList(),
            ),
        ]),
      ),

      // Context-aware primary action at the bottom (single action to avoid overflow).
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: OverflowBar(
            spacing: 12,
            overflowAlignment: OverflowBarAlignment.center,
            children: [
              if (task.state == LeakageTaskState.open)
                FilledButton(
                  onPressed: () async {
                    await notifier.markClosed(task.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as closed')));
                    }
                  },
                  child: const Text('Mark Closed'),
                ),
              if (task.state == LeakageTaskState.closed)
                FilledButton(
                  onPressed: () async {
                    await notifier.markOpen(task.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reopened to Open')));
                    }
                  },
                  child: const Text('Reopen'),
                ),
              if (task.state == LeakageTaskState.draft)
                FilledButton(
                  onPressed: () => context.go('/leakage/task/$taskId'),
                  child: const Text('Edit & Submit'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Bottom sheet for point details (keeps the original “slide up” UX).
  void _showPointBottomSheet(BuildContext context, WidgetRef ref, LeakReportPoint p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (ctx, scrollCtrl) {
          return _PointDetailSheet(point: p);
        },
      ),
    );
  }

  // Fallback for missing task id (safe guard)
  LeakageTask _missingTaskFallback() => LeakageTask(
        id: '',
        title: '',
        type: 'window',
        state: LeakageTaskState.draft,
      );
}

class _StatusBadge extends StatelessWidget {
  final LeakageTaskState state;
  const _StatusBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    final map = {
      LeakageTaskState.draft: ('Draft', Colors.grey),
      LeakageTaskState.open: ('Open', Colors.orange),
      LeakageTaskState.closed: ('Closed', Colors.green),
    };
    final (label, color) = map[state]!;
    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        label: Text(label),
        labelStyle: TextStyle(color: color.shade800),
        backgroundColor: color.withOpacity(0.12),
        side: BorderSide(color: color.withOpacity(0.24)),
      ),
    );
  }
}

class _SmallCard extends StatelessWidget {
  final String title, line1, line2;
  const _SmallCard({super.key, required this.title, required this.line1, required this.line2});

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    final valueStyle = Theme.of(context).textTheme.bodyLarge;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 80),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Text(line1, style: valueStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (line2.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(line2, style: valueStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// List tile for a detected point. Tap -> slide-up bottom sheet with details.
class _PointListTile extends ConsumerWidget {
  final String taskId;
  final LeakReportPoint point;
  const _PointListTile({super.key, required this.taskId, required this.point});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: _PointThumb(point: point),
        title: Text(point.title),
        subtitle: Text(point.subtitle),
        trailing: const Icon(Icons.keyboard_arrow_up), // hint for slide-up detail
        onTap: () {
          (context.findAncestorWidgetOfExactType<LeakageReportPage>())
              ?._showPointBottomSheet(context, ref, point);
        },
      ),
    );
  }
}

class _PointThumb extends ConsumerWidget {
  final LeakReportPoint point;
  const _PointThumb({required this.point});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fs = ref.read(fileStorageServiceProvider);
    final user = ref.read(userProvider);
    final uid = (user.uid?.trim().isNotEmpty == true) ? user.uid!.trim() : 'local';

    Future<String?> absOrNull(String? relOrAbs) async {
      if (relOrAbs == null) return null;
      return await fs.resolveModuleAbsolute(uid, 'leakage', relOrAbs);
    }

    return FutureBuilder<String?>(
      future: absOrNull(point.thumbPath ?? point.imagePath),
      builder: (context, snap) {
        final path = snap.data;
        if (path == null || !File(path).existsSync()) {
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
          child: Image.file(File(path), width: 56, height: 56, fit: BoxFit.cover),
        );
      },
    );
  }
}

/// Slide-up sheet content: marked image + suggestions.
class _PointDetailSheet extends ConsumerWidget {
  final LeakReportPoint point;
  const _PointDetailSheet({required this.point});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fs = ref.read(fileStorageServiceProvider);
    final user = ref.read(userProvider);
    final uid = (user.uid?.trim().isNotEmpty == true) ? user.uid!.trim() : 'local';

    Future<String?> absOrNull(String? relOrAbs) async {
      if (relOrAbs == null) return null;
      return await fs.resolveModuleAbsolute(uid, 'leakage', relOrAbs);
    }

    Widget buildMarkedImage() {
      return FutureBuilder<String?>(
        future: absOrNull(point.imagePath),
        builder: (context, snap) {
          final path = snap.data;
          if (path == null || !File(path).existsSync()) {
            return Container(
              height: 260,
              color: Colors.grey.shade200,
              child: const Center(child: Icon(Icons.image, size: 48)),
            );
          }
          return AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                Positioned.fill(child: Image.file(File(path), fit: BoxFit.contain)),
                if (point.markerX != null &&
                    point.markerY != null &&
                    point.markerW != null &&
                    point.markerH != null)
                  LayoutBuilder(
                    builder: (ctx, c) {
                      final x = point.markerX!.clamp(0.0, 1.0) * c.maxWidth;
                      final y = point.markerY!.clamp(0.0, 1.0) * c.maxHeight;
                      final w = point.markerW!.clamp(0.0, 1.0) * c.maxWidth;
                      final h = point.markerH!.clamp(0.0, 1.0) * c.maxHeight;
                      return Positioned(
                        left: x,
                        top: y,
                        width: w,
                        height: h,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(4),
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      );
    }

    Widget buildSuggestions() {
      final items = point.suggestions;
      if (items.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: items.map((s) {
          final lines = <String>[];
          if (s.costRange != null && s.costRange!.isNotEmpty) lines.add('Cost: ${s.costRange}');
          if (s.difficulty != null && s.difficulty!.isNotEmpty) lines.add(' | ${s.difficulty}');
          if (s.lifetime != null && s.lifetime!.isNotEmpty) lines.add('\n${s.lifetime}');
          if (s.estimatedReduction != null && s.estimatedReduction!.isNotEmpty) {
            lines.add('\nEstimated reduction: ${s.estimatedReduction}');
          }
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(s.title),
              subtitle: lines.isEmpty ? null : Text(lines.join()),
            ),
          );
        }).toList(),
      );
    }

    return Material(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: ListView(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(point.title, style: Theme.of(context).textTheme.titleMedium),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(point.subtitle),
              const SizedBox(height: 12),
              buildMarkedImage(),
              const SizedBox(height: 12),
              buildSuggestions(),
            ],
          ),
        ),
      ),
    );
  }
}
