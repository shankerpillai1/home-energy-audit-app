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
    final suggestions = report?.suggestions ?? const <LeakSuggestion>[];

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

          _ReportImage(report: report),

          const SizedBox(height: 16),

          if (suggestions.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No suggestions available.', style: Theme.of(context).textTheme.bodyLarge),
              ),
            )
          else
            Column(
              children: suggestions.map((s) => _SuggestionTile(s)).toList(),
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
  const _SmallCard({required this.title, required this.line1, required this.line2});

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

class _ReportImage extends ConsumerWidget {
  final LeakReport? report;
  const _ReportImage({required this.report});

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
      future: absOrNull(report!.imagePath),
      builder: (context, snap) {
        final path = snap.data;
        if (path == null || !File(path).existsSync()) {
          return const SizedBox(
            height: 240,
            child: DecoratedBox(
              decoration: BoxDecoration(color: Color(0xFFE0E0E0)),
              child: Center(child: Icon(Icons.image_not_supported)),
            ),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Center(child: Image.file(File(path), height: 240, fit: BoxFit.cover)),
        );
      },
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final LeakSuggestion s;
  const _SuggestionTile(this.s);

  @override
  Widget build(BuildContext context) {
    final lines = <String>[
      if (s.costRange != null && s.costRange?.isNotEmpty == true) 'Cost: ${s.costRange}',
      if (s.difficulty != null && s.difficulty?.isNotEmpty == true) 'Difficulty: ${s.difficulty}',
      if (s.lifetime != null && s.lifetime?.isNotEmpty == true) 'Lifetime: ${s.lifetime}',
      if (s.estimatedReduction != null && s.estimatedReduction?.isNotEmpty == true) 'Estimated Reduction: ${s.estimatedReduction}',
    ];
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(s.title),
        subtitle: lines.isEmpty ? null : Text(lines.join("\n")),
      ),
    );
  }
}
