import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/todo_item.dart';
import '../../../providers/todo_provider.dart';

/// A placeholder page for the "LED Light Bulbs" retrofit module.
///
/// This page is displayed when a user navigates to the LED retrofit section.
/// The button now interacts with the [TodoListNotifier] to add a new reminder.
class LedPage extends ConsumerWidget {
  const LedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LED Light Bulbs'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lightbulb_outline, size: 80),
              const SizedBox(height: 20),
              Text(
                'LED Retrofit Details',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              const Text(
                'Information about switching to LED bulbs will be displayed here.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  // Add a new reminder to the list using the provider.
                  ref.read(todoListProvider.notifier).addItem(
                        title: 'Buy and install LED bulbs',
                        type: TodoItemType.reminder,
                        // Set a due date for 30 days from now.
                        dueDate: DateTime.now().add(const Duration(days: 30)),
                      );
                  // Show a confirmation message.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Added a reminder to your to-do list!'),
                    ),
                  );
                },
                icon: const Icon(Icons.calendar_today),
                label: const Text('Add to Periodic Reminder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}