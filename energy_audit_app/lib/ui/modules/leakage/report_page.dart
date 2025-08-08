// lib/ui/modules/leakage/leakage_report_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/leakage_task.dart';
import '../../../state/leakage_task_provider.dart';

class LeakageReportPage extends ConsumerWidget {
  final String taskId;
  const LeakageReportPage({Key? key, required this.taskId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read the task from Riverpod
    final task = ref.read(leakageTaskListProvider.notifier).getById(taskId);

    // Dynamic values or fallback
    final cost     = task?.energyLossCost  ?? '--';
    final energy   = task?.energyLossValue ?? '--';
    final severity = task?.leakSeverity    ?? '--';
    final saveCost = task?.savingsCost     ?? '--';
    final savePct  = task?.savingsPercent  ?? '--';

    // Report points list
    final points   = task?.reportPoints    ?? [];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/leakage'),
        ),
        title: const Text('Report'),
        actions: [
          TextButton(
            onPressed: () => context.go('/leakage/task/$taskId'),
            child: const Text(
              'Modify Submission',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task title
            Text(
              (task?.title.isNotEmpty == true) ? task!.title : 'Untitled Task',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Summary cards
            Row(
              children: [
                _SmallCard(
                  title: 'Energy Loss',
                  line1: cost,
                  line2: energy,
                ),
                const SizedBox(width: 8),
                _SmallCard(
                  title: 'Leak Severity',
                  line1: severity,
                  line2: '',
                ),
                const SizedBox(width: 8),
                _SmallCard(
                  title: 'Potential Savings',
                  line1: saveCost,
                  line2: savePct,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Report points
            for (var pt in points)
              _ReportPointTile(
                title: pt.title,
                subtitle: pt.subtitle,
                imagePath: pt.imagePath,
              ),
          ],
        ),
      ),
    );
  }
}

/// Small info card used in the summary row.
class _SmallCard extends StatelessWidget {
  final String title, line1, line2;
  const _SmallCard({
    Key? key,
    required this.title,
    required this.line1,
    required this.line2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                line1,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (line2.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  line2,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A single report point with expandable image and action.
class _ReportPointTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? imagePath;

  const _ReportPointTile({
    Key? key,
    required this.title,
    required this.subtitle,
    this.imagePath,
  }) : super(key: key);

  @override
  State<_ReportPointTile> createState() => _ReportPointTileState();
}

class _ReportPointTileState extends State<_ReportPointTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          ListTile(
            title: Text(widget.title),
            subtitle: Text(widget.subtitle),
            trailing: IconButton(
              icon: Icon(
                _expanded ? Icons.expand_less : Icons.expand_more
              ),
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
          ),
          if (_expanded) ...[
            if (widget.imagePath != null)
              Image.file(
                File(widget.imagePath!),
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              )
            else
              Container(
                height: 200,
                color: Colors.grey.shade200,
                child: const Center(child: Icon(Icons.image, size: 48)),
              ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Add to To-Do list when implemented
                },
                icon: const Icon(Icons.playlist_add),
                label: const Text('Add to To-Do'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
