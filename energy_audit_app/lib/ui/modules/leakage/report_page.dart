import 'package:flutter/material.dart';
class LeakageReportPage extends StatelessWidget {
  final String taskId;
  const LeakageReportPage({super.key, required this.taskId});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Leakage Report: $taskId')),
      body: Center(child: Text('Report Page for $taskId')),
    );
  }
}
