import 'package:flutter/material.dart';
import 'package:flutter_client/screens/login_page.dart';
import 'package:flutter_client/screens/dashboard_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoggedIn = false;
  String _userName = 'User';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      _userName = prefs.getString('userName') ?? 'User';
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      title: 'Responsive Login App',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF2C2C2C),
          border: OutlineInputBorder(),
          labelStyle: TextStyle(color: Colors.white70),
        ),
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
      ),
      debugShowCheckedModeBanner: false,
      home: _isLoggedIn ? DashboardPage(userName: _userName) : const LoginPage(),
      onGenerateRoute: (settings) {
        final args = settings.arguments;

        switch (settings.name) {
          case '/dashboard/home':
            final userName = args is String ? args : _userName;
            return MaterialPageRoute(builder: (_) => DashboardPage(userName: userName));
          default:
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text('404 - Page not found')),
              ),
            );
        }
      },
    );
  }
}
