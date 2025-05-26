import 'package:flutter/material.dart';

class InputPage extends StatelessWidget {
  final String userName;
  const InputPage({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          width: double.infinity,
          child: Text(
            'Welcome, $userName',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
        const Expanded(
          child: Center(
            child: Text(
              'This is the Input page placeholder.',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      ],
    );
  }
}
