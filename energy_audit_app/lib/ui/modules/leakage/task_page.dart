import 'package:flutter/material.dart';
class LeakageHistoryPage extends StatelessWidget {
  const LeakageHistoryPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leakage History')),
      body: const Center(child: Text('Leakage History Page')),
    );
  }
}