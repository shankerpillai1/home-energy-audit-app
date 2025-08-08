import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/user_provider.dart';
import '../../providers/repository_providers.dart';
import '../../providers/leakage_task_provider.dart';

import '../../services/auth_service.dart';
import '../../services/settings_service.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _userCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _auth = AuthService();

  bool _isLoading = false;
  bool _isClearing = false;

  Future<void> _clearLocalData() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear local data?'),
        content: const Text(
          'This will remove app settings (SharedPreferences), ALL local task data '
          '(users/* JSON & media), and ALL registered accounts stored in AuthService. '
          'Use this to fully reset the app for testing.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _isClearing = true);
    try {
      // 1) Clear SharedPreferences flags/settings
      await SettingsService().clearAll();

      // 2) Delete ALL local users tree (every uid/module, JSON + media + mirrors)
      await ref.read(fileStorageServiceProvider).deleteAllUsersTree();

      // 3) Clear ALL registered accounts in AuthService (the missing piece)
      await _auth.clearAllUsers();

      // 4) Reset in-memory states
      ref.read(leakageTaskListProvider.notifier).resetAll();
      ref.read(userProvider.notifier).logout();
      // Refresh known users to reflect the cleared secure store
      await ref.read(userProvider.notifier).reloadKnownUsers();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All local data cleared')),
      );
    } finally {
      if (mounted) setState(() => _isClearing = false);
    }
  }

  Future<void> _doLogin() async {
    final user = _userCtrl.text.trim();
    final pwd = _pwdCtrl.text;
    if (user.isEmpty || pwd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // First: explicit existence check (so we can show a clear message)
      final known = await _auth.getAllUsers();
      final exists = known.contains(user);
      if (!exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('User does not exist.'),
            action: SnackBarAction(
              label: 'Go to Register',
              onPressed: () => context.push('/register'),
            ),
          ),
        );
        return;
      }

      // Then validate credentials
      final ok = await _auth.login(user, pwd);
      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid username or password')),
        );
        return;
      }

      await ref.read(userProvider.notifier).login(user);
      if (!mounted) return;
      context.go('/home');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        actions: [
          IconButton(
            tooltip: 'Clear local cache',
            onPressed: _isClearing ? null : _clearLocalData,
            icon: _isClearing
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.delete_forever),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Login', style: theme.textTheme.displayLarge),
                    const SizedBox(height: 24),

                    TextField(
                      controller: _userCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _pwdCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _doLogin,
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('LOGIN'),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: _isLoading ? null : () => context.push('/register'),
                      style: TextButton.styleFrom(textStyle: theme.textTheme.labelLarge),
                      child: const Text('Create an account'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
