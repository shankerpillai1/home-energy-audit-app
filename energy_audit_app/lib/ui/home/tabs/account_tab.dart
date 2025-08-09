import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/user_provider.dart';
import '../../../providers/leakage_task_provider.dart';
import '../../../providers/repository_providers.dart';

import '../../../services/settings_service.dart';
import '../../../services/auth_service.dart';

class AccountTab extends ConsumerWidget {
  const AccountTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final username = user.username ?? 'Unknown';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header card
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(username),
            subtitle: const Text('Signed in'),
          ),
        ),

        const SizedBox(height: 12),

        // Profile section
        _SectionHeader('Profile'),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.assignment_ind_outlined),
                title: const Text('Edit Intro answers'),
                subtitle: const Text('Revisit onboarding survey'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/intro'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.lock_reset),
                title: const Text('Change password'),
                subtitle: const Text('Coming soon'),
                enabled: false,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Data & privacy
        _SectionHeader('Data & Privacy'),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.storage_outlined),
                title: const Text('View storage info'),
                subtitle: const Text('Show data location and task counts'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showStorageInfo(context, ref),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.cleaning_services_outlined),
                title: const Text('Clear my leakage data'),
                subtitle: const Text('Delete this user’s leakage tasks on this device'),
                onTap: () => _confirmClearMyLeakage(context, ref),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                title: const Text('Clear ALL users & data'),
                subtitle: const Text('Danger: remove all local accounts and caches'),
                onTap: () => _confirmClearAll(context, ref),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Help & support
        _SectionHeader('Help & Support'),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: const Text('Open Assistant'),
                onTap: () => context.push('/assistant'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.school_outlined),
                title: const Text('Tutorials'),
                subtitle: const Text('How to use features'),
                enabled: false,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // About
        _SectionHeader('About'),
        Card(
          child: Column(
            children: const [
              ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Home Energy Audit'),
                subtitle: Text('Version 0.1.0'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Logout button at bottom
        OutlinedButton.icon(
          onPressed: () {
            ref.read(userProvider.notifier).logout();
            context.go('/login');
          },
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // --- Helpers ---

  Future<void> _showStorageInfo(BuildContext context, WidgetRef ref) async {
    final fs = ref.read(fileStorageServiceProvider);
    final repo = ref.read(taskRepositoryProvider);
    final user = ref.read(userProvider);
    final uid = (user.uid?.trim().isNotEmpty == true) ? user.uid!.trim() : 'local';

    // Use a known file to derive user root path
    final indexFile = await fs.moduleIndexFile(uid, 'leakage');
    final userRootDir = indexFile.parent.parent; // .../users/<uid>

    final tasks = await repo.fetchAll();
    final count = tasks.length;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Storage info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('User data root:'),
            const SizedBox(height: 4),
            SelectableText(userRootDir.path, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            Text('Leakage tasks: $count'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _confirmClearMyLeakage(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear leakage data?'),
        content: const Text(
          'This will delete all leakage tasks for the current user on this device. '
          'Your account remains.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;

    final user = ref.read(userProvider);
    final uid = (user.uid?.trim().isNotEmpty == true) ? user.uid!.trim() : 'local';

    final fs = ref.read(fileStorageServiceProvider);
    final settings = LocalStorageService();

    // Remove leakage module dir only
    final leakageDir = await fs.moduleRootDir(uid, 'leakage'); // make sure this exists in service
    if (await leakageDir.exists()) {
      await leakageDir.delete(recursive: true);
    }

    // Reset in-memory list
    ref.read(leakageTaskListProvider.notifier).resetAll();

    // Mark intro incomplete so user can redo if desired
    final username = user.username;
    if (username != null && username.isNotEmpty) {
      await settings.saveBool('introCompleted_$username', false);
      ref.read(userProvider.notifier).markIntroIncompleteForCurrent();
    }

    // Notify
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leakage data cleared for this user')),
      );
    }
  }

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear ALL users & data?'),
        content: const Text(
          'This will remove all registered users and all stored data on this device. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete all'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final fs = ref.read(fileStorageServiceProvider);
    final auth = AuthService();

    // Delete the whole /users folder mirror
    final root = await fs.usersRootDir(); // make sure this exists in service
    if (await root.exists()) {
      await root.delete(recursive: true);
    }

    // Clear auth registry and flags
    await auth.clearAll();

    // Reset providers and go to login
    ref.read(leakageTaskListProvider.notifier).resetAll();
    ref.read(userProvider.notifier).logout();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All users & data cleared')),
      );
      context.go('/login');
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      );
}
