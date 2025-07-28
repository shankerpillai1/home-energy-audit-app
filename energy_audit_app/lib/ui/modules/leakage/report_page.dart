import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/leakage_task.dart';

class LeakageReportPage extends ConsumerWidget {
  final String taskId;
  const LeakageReportPage({Key? key, required this.taskId})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: 根据 taskId 从 Provider/Service 获取已分析的任务
    final task = LeakageTask(
      id: taskId,
      title: 'Sample Task',
      type: 'door',
      analysisSummary:
          'Found multiple gaps around the door frame. Estimated savings: 15 kWh/month.',
      recommendations: ['Seal gaps with foam tape', 'Install door sweep'],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Leakage Report')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.analysisSummary ?? '',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            Text('Recommendations:', style: Theme.of(context).textTheme.titleMedium),
            ...?task.recommendations?.map((r) => ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: Text(r),
                )),
            const Spacer(),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: 生成 PDF 或报告并下载/分享
                },
                icon: const Icon(Icons.download),
                label: const Text('Download Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
