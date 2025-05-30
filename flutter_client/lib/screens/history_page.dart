import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  final String userName;
  const HistoryPage({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'History records for $userName will be shown here.',
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}
