import 'package:flutter/material.dart';

class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder credentials list
    final credentials = [
      {'site': 'Email', 'username': 'user@email.com'},
      {'site': 'Bank', 'username': 'mybankuser'},
    ];
    return Scaffold(
      body: ListView.builder(
        itemCount: credentials.length,
        itemBuilder: (context, index) => ListTile(
          leading: const Icon(Icons.vpn_key),
          title: Text(credentials[index]['site']!),
          subtitle: Text(credentials[index]['username']!),
          onTap: () {}, // Will open password details in the future
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to add password screen
        },
        tooltip: 'Add Password',
        child: const Icon(Icons.add),
      ),
    );
  }
}
