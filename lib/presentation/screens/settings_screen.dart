import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder settings options
    final settings = [
      {'icon': Icons.person, 'title': 'Account'},
      {'icon': Icons.security, 'title': 'Security'},
      {'icon': Icons.info, 'title': 'About'},
      {'icon': Icons.logout, 'title': 'Logout'},
    ];
    return Scaffold(
      body: ListView.builder(
        itemCount: settings.length,
        itemBuilder: (context, index) => ListTile(
          leading: Icon(settings[index]['icon'] as IconData),
          title: Text(settings[index]['title'] as String),
          onTap: () async {
            if (settings[index]['title'] == 'Logout') {
              // Use AuthProvider to sign out
              final auth = Provider.of<AuthProvider>(context, listen: false);
              await auth.signOut();
            }
          },
        ),
      ),
    );
  }
}
