import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    final status = await Permission.notification.status;
    setState(() {
      _notificationsEnabled = status.isGranted;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        setState(() => _notificationsEnabled = true);
      } else if (status.isPermanentlyDenied) {
        // Direct the user to app settings
        openAppSettings();
      } else {
        setState(() => _notificationsEnabled = false);
      }
    } else {
      // In iOS/Android you can't easily "un-request" permissions programmatically
      // Usually you just direct them to settings if they want to turn it off completely.
      openAppSettings();
      // Alternatively just keep the local toggle state and don't schedule notifications.
      setState(() => _notificationsEnabled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
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
