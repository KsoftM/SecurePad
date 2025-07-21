import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import 'account_screen.dart';
import 'security_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = [
      {'icon': Icons.person, 'title': 'Account', 'section': 'Profile'},
      {'icon': Icons.security, 'title': 'Security', 'section': 'Preferences'},
      {'icon': Icons.info, 'title': 'About', 'section': 'App'},
      {'icon': Icons.logout, 'title': 'Logout', 'section': 'App'},
    ];

    String? lastSection;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: settings.length,
        itemBuilder: (context, index) {
          final setting = settings[index];
          final section = setting['section'] as String;
          final showSectionHeader = section != lastSection;
          lastSection = section;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showSectionHeader)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    section,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: Icon(setting['icon'] as IconData),
                  title: Text(setting['title'] as String),
                  trailing: setting['title'] != 'Logout'
                      ? const Icon(Icons.arrow_forward_ios, size: 16)
                      : null,
                  onTap: () async {
                    switch (setting['title']) {
                      case 'Account':
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const AccountScreen()),
                        );
                        break;
                      case 'Security':
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const SecurityScreen()),
                        );
                        break;
                      case 'About':
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const AboutScreen()),
                        );
                        break;
                      case 'Logout':
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Sign out'),
                            content: const Text(
                                'Are you sure you want to sign out?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Sign out'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          context.read<AuthBloc>().add(AuthSignOut());
                        }
                        break;
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
