import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../models/todo_item.dart';
import '../../../providers/todo_provider.dart';


/// The main tab displayed on the home screen, formerly "DashboardTab".
///
/// This tab shows a summary of savings and three lists of tasks:
/// - Projects to do
/// - Periodic Reminders
/// - A list of completed items
/// These lists are now powered by the [todoListProvider].
class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Watch the provider to get the list of all to-do items.
    // The UI will automatically rebuild when this list changes.
    final allTodos = ref.watch(todoListProvider);

    // Filter the lists based on their type and completion status.
    final projects = allTodos.where((t) => t.type == TodoItemType.project && !t.isDone).toList();
    final reminders = allTodos.where((t) => t.type == TodoItemType.reminder && !t.isDone).toList();
    final doneItems = allTodos.where((t) => t.isDone).toList();

    // Sort projects by priority (higher priority first).
    projects.sort((a, b) => b.priority.compareTo(a.priority));

    // Sort reminders by due date (items without a due date go last, others ascending).
    reminders.sort((a, b) {
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });


    // Demo totals (static for now)
    final savedMoney = 100;
    final savedElectric = 30;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Summary card
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

          // Lists are now built dynamically from the provider state.
          Expanded(
            child: ListView(
              children: [
                _buildSection(
                  context,
                  ref: ref,
                  title: 'Projects I want to do',
                  items: projects,
                ),
                _buildSection(
                  context,
                  ref: ref,
                  title: 'Periodic Reminders',
                  items: reminders,
                ),
                _buildSection(
                  context,
                  ref: ref,
                  title: 'Done List',
                  items: doneItems,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A reusable widget to build a section for a list of to-do items.
  Widget _buildSection(
    BuildContext context, {
    required WidgetRef ref,
    required String title,
    required List<TodoItem> items,
  }) {
    final theme = Theme.of(context);
    final isDoneList = title == 'Done List';

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
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(child: Text('No items yet.')),
              )
            else
              ...items.map((item) {
                // Determine if a reminder is due today or overdue.
                final isDueOrOverdue = item.dueDate != null &&
                                     !item.dueDate!.isAfter(DateTime.now());

                return ListTile(
                  // The leading widget is an interactive Checkbox.
                  leading: Checkbox(
                    value: item.isDone,
                    onChanged: (bool? value) {
                      ref.read(todoListProvider.notifier).toggleDone(item.id);
                    },
                  ),
                  // The title of the ListTile shows the to-do item's title.
                  title: Text(
                    item.title,
                    style: TextStyle(
                      decoration: item.isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  // The subtitle displays due date and urgency.
                  subtitle: item.type == TodoItemType.reminder && item.dueDate != null
                      ? Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Due: ${DateFormat.yMMMd().format(item.dueDate!)}',
                              ),
                              if (!isDoneList && isDueOrOverdue)
                                const TextSpan(
                                  text: ' (Due Now)',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        )
                      : null,
                  // Trailing icon to indicate priority.
                  trailing: !isDoneList && item.priority > 0
                    ? Icon(Icons.priority_high, color: theme.colorScheme.secondary)
                    : null,
                );
              }),
          ],
        ),
      ),
    );
  }
}