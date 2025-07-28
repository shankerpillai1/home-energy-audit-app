import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/user_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Placeholder stats
    final savedMoney = 100;
    final savedElectric = 30;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(userProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Summary Card
            Card(
              color: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '\$$savedMoney Saved\n$savedElectric kWh Saved',
                        style: theme.textTheme.bodyLarge!
                            .copyWith(color: theme.colorScheme.onPrimary),
                      ),
                    ),
                    CircleAvatar(
                      backgroundImage: AssetImage('assets/avatar.png'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Sections
            Expanded(
              child: ListView(
                children: [
                  _buildSection(
                    context,
                    title: 'Projects I want to do',
                    items: const [
                      'Switch to LED Bulbs',
                    ],
                  ),
                  _buildSection(
                    context,
                    title: 'Periodic Reminders',
                    items: const [
                      'Annual heating maintenance (Due Now)',
                      'Annual AC maintenance',
                    ],
                    redItems: {0},
                  ),
                  _buildSection(
                    context,
                    title: 'Done List',
                    items: const [
                      'Completed Task A',
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/assistant'),
        child: const Icon(Icons.chat_bubble_outline),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<String> items,
    Set<int> redItems = const {},
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const Divider(),
            ...items.asMap().entries.map((e) {
              final idx = e.key;
              final text = e.value;
              return ListTile(
                leading: Icon(
                  idx == 0 && title == 'Projects I want to do'
                      ? Icons.check_circle
                      : Icons.circle,
                  color: redItems.contains(idx)
                      ? Colors.red
                      : theme.colorScheme.onSurface,
                ),
                title: Text(text),
              );
            }),
          ],
        ),
      ),
    );
  }
}
