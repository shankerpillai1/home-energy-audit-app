// lib/ui/modules/leakage/report_page.dart
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
  const LeakageReportPage({Key? key, required this.taskId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref.read(leakageTaskListProvider.notifier).getById(taskId);
    final report = task?.report;
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
          TextButton(
            onPressed: () => context.go('/leakage/task/$taskId'),
            child: const Text('Modify Submission',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            (task?.title.isNotEmpty == true) ? task!.title : 'Untitled Task',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          Row(children: [
            _SmallCard(title: 'Energy Loss', line1: cost, line2: energy),
            const SizedBox(width: 8),
            _SmallCard(title: 'Leak Severity', line1: sev, line2: ''),
            const SizedBox(width: 8),
            _SmallCard(title: 'Potential Savings', line1: saveC, line2: saveP),
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

class _SmallCard extends StatelessWidget {
  final String title, line1, line2;
  const _SmallCard({Key? key, required this.title, required this.line1, required this.line2})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(line1, style: Theme.of(context).textTheme.bodyLarge),
            if (line2.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(line2, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ]),
        ),
      ),
    );
  }
}

class _ReportPointTile extends ConsumerStatefulWidget {
  final LeakReportPoint point;
  const _ReportPointTile({Key? key, required this.point}) : super(key: key);

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

    Future<String?> _absOrNull(String? relOrAbs) async {
      if (relOrAbs == null) return null;
      return await fs.resolveModuleAbsolute(uid, 'leakage', relOrAbs);
    }

    Widget buildThumb() {
      return FutureBuilder<String?>(
        future: _absOrNull(p.thumbPath ?? p.imagePath),
        builder: (context, snap) {
          final path = snap.data;
          if (path == null) {
            return const CircleAvatar(child: Icon(Icons.image));
          }
          final file = File(path);
          if (!file.existsSync()) {
            return const CircleAvatar(child: Icon(Icons.image_not_supported));
          }
          return CircleAvatar(backgroundImage: FileImage(file));
        },
      );
    }

    Widget buildMarkedImage() {
      return FutureBuilder<String?>(
        future: _absOrNull(p.imagePath),
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
          trailing: IconButton(
            icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
            onPressed: () => setState(() => _expanded = !_expanded),
          ),
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
