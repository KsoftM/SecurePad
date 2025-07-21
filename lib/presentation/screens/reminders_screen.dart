import 'package:flutter/material.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder reminders list
    final reminders = [
      'Pay bills (Monthly)',
      'Workout (Weekly)',
      'Call Mom (Sunday)'
    ];
    return Scaffold(
      body: ListView.builder(
        itemCount: reminders.length,
        itemBuilder: (context, index) => ListTile(
          leading: const Icon(Icons.alarm),
          title: Text(reminders[index]),
          onTap: () {}, // Will open reminder details in the future
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to add reminder screen
        },
        tooltip: 'Add Reminder',
        child: const Icon(Icons.add),
      ),
    );
  }
}
