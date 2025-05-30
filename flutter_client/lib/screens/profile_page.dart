import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class ProfilePage extends StatelessWidget {
  final String userName;
  final bool showLogout;
  const ProfilePage({super.key, required this.userName, this.showLogout = false});

  bool get isMobile =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      // 移动端布局
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Colors.blueAccent,
        ),
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello, $userName!',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              if (showLogout)
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Logout'),
                ),
            ],
          ),
        ),
      );
    } else {
      // 网页端布局
      return Scaffold(
        backgroundColor: const Color(0xFF1E1E1E),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome to your profile, $userName!',
                style: const TextStyle(fontSize: 24, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'This is the desktop/web version of the profile page.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
  }
}
