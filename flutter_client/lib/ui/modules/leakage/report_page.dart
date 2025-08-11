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
    final task = ref.watch(leakageTaskListProvider).firstWhere((t) => t.id == taskId,
        orElse: () => ref.read(leakageTaskListProvider.notifier).getById(taskId)!);
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

          // Modify button right under title
          Row(
            children: [
              FilledButton.icon(
                onPressed: () => context.go('/leakage/task/$taskId'),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Modify Submission'),
              ),
              const SizedBox(width: 12),
              _StateChips(task: task, onChanged: (s) async {
                switch (s) {
                  case LeakageTaskState.draft:
                    await notifier.markDraft(task.id);
                    break;
                  case LeakageTaskState.open:
                    await notifier.markOpen(task.id);
                    break;
                  case LeakageTaskState.closed:
                    await notifier.markClosed(task.id);
                    break;
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('State updated')));
                }
              }),
            ],
          ),

          const SizedBox(height: 16),

          // Three even cards (fix text overflow)
          Row(children: [
            Expanded(child: _SmallCard(title: 'Energy Loss', line1: cost, line2: energy)),
            const SizedBox(width: 8),
            Expanded(child: _SmallCard(title: 'Leak Severity', line1: sev, line2: '')),
            const SizedBox(width: 8),
            Expanded(child: _SmallCard(title: 'Potential Savings', line1: saveC, line2: saveP)),
          ]),

          const SizedBox(height: 16),

          if (points.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No points available.',
                    style: Theme.of(context).textTheme.bodyLarge),
              ),
            )
          else
            for (final pt in points) _ReportPointTile(point: pt),
        ]),
      ),
    );
  }
}

class _StateChips extends StatelessWidget {
  final LeakageTask task;
  final ValueChanged<LeakageTaskState> onChanged;

  const _StateChips({super.key, required this.task, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = task.state;
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Draft'),
          selected: s == LeakageTaskState.draft,
          onSelected: (_) => onChanged(LeakageTaskState.draft),
        ),
        ChoiceChip(
          label: const Text('Open'),
          selected: s == LeakageTaskState.open,
          onSelected: (_) => onChanged(LeakageTaskState.open),
        ),
        ChoiceChip(
          label: const Text('Closed'),
          selected: s == LeakageTaskState.closed,
          onSelected: (_) => onChanged(LeakageTaskState.closed),
        ),
      ],
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

class _ReportPointTile extends ConsumerStatefulWidget {
  final LeakReportPoint point;
  const _ReportPointTile({super.key, required this.point});

  @override
  ConsumerState<_ReportPointTile> createState() => _ReportPointTileState();
}

class _ReportPointTileState extends ConsumerState<_ReportPointTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.point;
    final fs = ref.read(fileStorageServiceProvider);
    final user = ref.read(userProvider);
    final uid = (user.uid?.trim().isNotEmpty == true) ? user.uid!.trim() : 'local';

    Future<String?> absOrNull(String? relOrAbs) async {
      if (relOrAbs == null) return null;
      return await fs.resolveModuleAbsolute(uid, 'leakage', relOrAbs);
    }

    Widget buildThumb() {
      // square thumbnail for clarity
      return FutureBuilder<String?>(
        future: absOrNull(p.thumbPath ?? p.imagePath),
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

    Widget buildMarkedImage() {
      return FutureBuilder<String?>(
        future: absOrNull(p.imagePath),
        builder: (context, snap) {
          final path = snap.data;
          if (path == null || !File(path).existsSync()) {
            return Container(
              height: 240,
              color: Colors.grey.shade200,
              child: const Center(child: Icon(Icons.image, size: 48)),
            );
          }
          return AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.file(File(path), fit: BoxFit.contain),
                ),
                if (p.markerX != null &&
                    p.markerY != null &&
                    p.markerW != null &&
                    p.markerH != null)
                  LayoutBuilder(builder: (ctx, c) {
                    final x = p.markerX!.clamp(0.0, 1.0) * c.maxWidth;
                    final y = p.markerY!.clamp(0.0, 1.0) * c.maxHeight;
                    final w = p.markerW!.clamp(0.0, 1.0) * c.maxWidth;
                    final h = p.markerH!.clamp(0.0, 1.0) * c.maxHeight;
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
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.08),
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      );
    }

    Widget buildSuggestions() {
      final items = p.suggestions;
      if (items.isEmpty) return const SizedBox.shrink();
      return Column(
        children: items.map((s) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(s.title),
              subtitle: Text([
                if (s.costRange != null) 'Cost: ${s.costRange}',
                if (s.difficulty != null) ' | ${s.difficulty}',
                if (s.lifetime != null) '\n${s.lifetime}',
                if (s.estimatedReduction != null)
                  '\nEstimated reduction: ${s.estimatedReduction}',
              ].join()),
              trailing: IconButton(
                onPressed: () {
                  // TODO: add to To-Do list
                },
                icon: const Icon(Icons.favorite_border),
              ),
            ),
          );
        }).toList(),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(children: [
        ListTile(
          leading: buildThumb(),
          title: Text(p.title),
          subtitle: Text(p.subtitle),
          // removed chevron; tap toggles expansion
          onTap: () => setState(() => _expanded = !_expanded),
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          buildMarkedImage(),
          const SizedBox(height: 8),
          buildSuggestions(),
          const SizedBox(height: 8),
        ],
      ]),
    );
  }
}
