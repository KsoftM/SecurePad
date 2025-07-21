import 'package:flutter/material.dart';

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder templates list
    final templates = [
      'Contact Template',
      'Finance Log',
      'Custom Task List',
    ];
    return Scaffold(
      body: ListView.builder(
        itemCount: templates.length,
        itemBuilder: (context, index) => ListTile(
          leading: const Icon(Icons.view_list),
          title: Text(templates[index]),
          onTap: () {}, // Will open template details in the future
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to template editor
        },
        tooltip: 'Add Template',
        child: const Icon(Icons.add),
      ),
    );
  }
}
