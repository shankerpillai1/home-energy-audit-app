import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/todo_item.dart';
import '../../../providers/todo_provider.dart';

/// A placeholder page for the "Thermostat Settings" retrofit module.
///
/// The button on this page now adds a new reminder to the central
/// to-do list via the [TodoListNotifier].
class ThermostatPage extends ConsumerWidget {
  const ThermostatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thermostat Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.thermostat_outlined, size: 80),
              const SizedBox(height: 20),
              Text(
                'Thermostat Retrofit Details',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              const Text(
                'Information about optimizing thermostat settings will be displayed here.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  // Add a new reminder to the list using the provider.
                  ref.read(todoListProvider.notifier).addItem(
                        title: 'Review thermostat schedule',
                        type: TodoItemType.reminder,
                        // Set a due date for 14 days from now.
                        dueDate: DateTime.now().add(const Duration(days: 14)),
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