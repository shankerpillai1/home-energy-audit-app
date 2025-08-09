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
    final task = ref.read(leakageTaskListProvider.notifier).getById(taskId);
    final report = task?.report;
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
            (task?.title.isNotEmpty == true) ? task!.title : 'Untitled Task',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          // Modify button below title
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('Modify Submission'),
              onPressed: () => context.go('/leakage/task/$taskId'),
            ),
          ),
          const SizedBox(height: 12),

          // Uniform stat cards (no overflow)
          _StatsRow(
            cost: report?.energyLossCost ?? '--',
            energy: report?.energyLossValue ?? '--',
            severity: report?.leakSeverity ?? '--',
            savingsCost: report?.savingsCost ?? '--',
            savingsPercent: report?.savingsPercent ?? '--',
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
              children: points.map((pt) => _PointListTile(point: pt)).toList(),
            ),
        ]),
      ),
    );
  }
}

/// Three uniform, evenly spaced cards (Energy Loss / Severity / Savings).
class _StatsRow extends StatelessWidget {
  final String cost, energy, severity, savingsCost, savingsPercent;
  const _StatsRow({
    super.key,
    required this.cost,
    required this.energy,
    required this.severity,
    required this.savingsCost,
    required this.savingsPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(title: 'Energy Loss', lines: [cost, energy]),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(title: 'Leak Severity', lines: [severity]),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(title: 'Potential Savings', lines: [savingsCost, savingsPercent]),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final List<String> lines;
  const _StatCard({super.key, required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    final valueStyle = Theme.of(context).textTheme.bodyMedium; // slightly smaller to avoid overflow

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 104), // uniform min height; can grow if needed
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center, // vertically pleasant
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false),
              const SizedBox(height: 6),
              for (final line in lines)
                Text(
                  line,
                  style: valueStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One-line tile; tapping opens a modal bottom sheet with full details.
/// No trailing arrow icon; left thumb is now square.
class _PointListTile extends ConsumerWidget {
  final LeakReportPoint point;
  const _PointListTile({super.key, required this.point});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: _SquareThumb(point: point, size: 48),
        title: Text(point.title),
        subtitle: Text(point.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        onTap: () => _openPointSheet(context, ref, point),
      ),
    );
  }

  void _openPointSheet(BuildContext context, WidgetRef ref, LeakReportPoint p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _PointDetailSheet(point: p),
    );
  }
}

class _SquareThumb extends ConsumerWidget {
  final LeakReportPoint point;
  final double size;
  const _SquareThumb({super.key, required this.point, this.size = 48});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fs = ref.read(fileStorageServiceProvider);
    final user = ref.read(userProvider);
    final uid = user.uid?.trim();

    if (uid == null || uid.isEmpty) {
      return _placeholder(size);
    }

    Future<String?> absOrNull(String? relOrAbs) async {
      if (relOrAbs == null) return null;
      return await fs.resolveModuleAbsolute(uid, 'leakage', relOrAbs);
    }

    return FutureBuilder<String?>(
      future: absOrNull(point.thumbPath ?? point.imagePath),
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

/// Bottom sheet content: marked image + suggestions list.
/// Removed explicit "Close" button; swipe down to dismiss.
class _PointDetailSheet extends ConsumerWidget {
  final LeakReportPoint point;
  const _PointDetailSheet({super.key, required this.point});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fs = ref.read(fileStorageServiceProvider);
    final user = ref.read(userProvider);
    final uid = user.uid?.trim();

    Future<String?> absOrNull(String? relOrAbs) async {
      if (uid == null || uid.isEmpty || relOrAbs == null) return null;
      return await fs.resolveModuleAbsolute(uid, 'leakage', relOrAbs);
    }

    Widget buildMarkedImage() {
      return FutureBuilder<String?>(
        future: absOrNull(point.imagePath),
        builder: (context, snap) {
          final path = snap.data;
          if (path == null || !File(path).existsSync()) {
            return Container(
              height: 280,
              color: Colors.grey.shade200,
              child: const Center(child: Icon(Icons.image, size: 56)),
            );
          }
          return AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.file(File(path), fit: BoxFit.contain),
                ),
                if (point.markerX != null &&
                    point.markerY != null &&
                    point.markerW != null &&
                    point.markerH != null)
                  LayoutBuilder(builder: (ctx, c) {
                    final x = point.markerX!.clamp(0.0, 1.0) * c.maxWidth;
                    final y = point.markerY!.clamp(0.0, 1.0) * c.maxWidth; // keep square scale
                    final w = point.markerW!.clamp(0.0, 1.0) * c.maxWidth;
                    final h = point.markerH!.clamp(0.0, 1.0) * c.maxWidth;
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
                  }),
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

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListView(
            controller: scrollCtrl,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(point.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(point.subtitle),
              const SizedBox(height: 12),
              buildMarkedImage(),
              const SizedBox(height: 12),
              buildSuggestions(),
            ],
          ),
        );
      },
    );
  }
}
