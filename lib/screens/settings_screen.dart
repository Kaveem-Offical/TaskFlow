import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final user = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(user?.email?.substring(0, 1).toUpperCase() ?? 'U'),
            ),
            title: Text(user?.displayName ?? 'Kaveem Uddin', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(user?.email ?? 'kaveem@kaveem.com'),
          ),
          Divider(),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Appearance', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          RadioListTile<ThemeMode>(
            title: Text('System Default'),
            value: ThemeMode.system,
            groupValue: themeMode,
            onChanged: (val) => themeNotifier.setTheme(val!),
          ),
          RadioListTile<ThemeMode>(
            title: Text('Light Mode'),
            value: ThemeMode.light,
            groupValue: themeMode,
            onChanged: (val) => themeNotifier.setTheme(val!),
          ),
          RadioListTile<ThemeMode>(
            title: Text('Dark Mode'),
            value: ThemeMode.dark,
            groupValue: themeMode,
            onChanged: (val) => themeNotifier.setTheme(val!),
          ),
          Divider(),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          SwitchListTile(
            title: Text('Push Notifications'),
            value: true,
            onChanged: (val) {
            },
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
          Divider(),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Account', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Log Out', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await authNotifier.signOut();
            },
          ),
        ],
      ),
    );
  }
}
