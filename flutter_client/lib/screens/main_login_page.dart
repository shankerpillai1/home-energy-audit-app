import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  Map<String, Map<String, String>> _registeredUsers = {};
  bool isLogin = true;
  String? _loggedInUsername;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString('users');
    print('🔍 Loaded from SharedPreferences: $storedData');
    if (storedData != null) {
      final decoded = jsonDecode(storedData);
      setState(() {
        _registeredUsers = Map<String, Map<String, String>>.from(
          decoded.map((key, value) => MapEntry(key, Map<String, String>.from(value))),
        );
      });
    }
  }

  Future<void> _saveUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_registeredUsers);
    print('💾 Saving to SharedPreferences: $encoded');
    await prefs.setString('users', encoded);
  }

  void _submit() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final username = _usernameController.text.trim();

    if (email.isEmpty || password.isEmpty || (!isLogin && username.isEmpty)) {
      _showMessage('Please fill in all fields');
      return;
    }

    if (isLogin) {
      final match = _registeredUsers.entries.firstWhere(
        (entry) =>
            (entry.key == email || entry.value['username'] == email) &&
            entry.value['password'] == password,
        orElse: () => const MapEntry('', {}),
      );

      if (match.key.isNotEmpty) {
        _loggedInUsername = match.value['username'];
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardPage(userName: _loggedInUsername ?? 'User'),
          ),
        );
      } else {
        _showMessage('Invalid username/email or password');
      }
    } else {
      if (_registeredUsers.containsKey(email)) {
        _showMessage('Email already registered');
      } else {
        setState(() {
          _registeredUsers[email] = {'username': username, 'password': password};
        });
        _saveUsers();
        _showMessage('Registration successful! Please login.');
        setState(() => isLogin = true);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32.0),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isLogin ? 'Login' : 'Register',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 24),
              if (!isLogin)
                TextField(
                  controller: _usernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Color(0xFF2C2C2C),
                    border: OutlineInputBorder(),
                  ),
                ),
              if (!isLogin) const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: isLogin ? 'Email or Username' : 'Email',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF2C2C2C),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Color(0xFF2C2C2C),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                ),
                onPressed: _submit,
                child: Text(isLogin ? 'Login' : 'Register'),
              ),
              TextButton(
                onPressed: () => setState(() => isLogin = !isLogin),
                child: Text(
                  isLogin ? 'Create new account' : 'Already have an account? Login',
                  style: const TextStyle(color: Colors.white60),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
