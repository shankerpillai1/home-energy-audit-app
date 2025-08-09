import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Demo totals
    final savedMoney = 100;
    final savedElectric = 30;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            color: theme.colorScheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '\$$savedMoney Saved\n$savedElectric kWh Saved',
                      style: theme.textTheme.bodyLarge!.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.onPrimary.withOpacity(0.3),
                    child: Icon(
                      Icons.energy_savings_leaf_outlined,
                      size: 28,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildSection(
                  context,
                  title: 'Projects I want to do',
                  items: const ['Seal Air Leaks', 'Switch to LED Bulbs'],
                ),
                _buildSection(
                  context,
                  title: 'Periodic Reminders',
                  items: const [
                    'Annual heating maintenance (Due Now)',
                    'Annual AC maintenance',
                  ],
                  redItems: const {0},
                ),
                _buildSection(
                  context,
                  title: 'Done List',
                  items: const ['Completed Task A'],
                ),
              ],
            ),
          ),
        ],
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
