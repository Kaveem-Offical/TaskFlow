import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';
import '../widgets/premium/premium_card.dart';

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
    HapticFeedback.lightImpact();
    if (value) {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        setState(() => _notificationsEnabled = true);
      } else if (status.isPermanentlyDenied) {
        openAppSettings();
      } else {
        setState(() => _notificationsEnabled = false);
      }
    } else {
      openAppSettings();
      setState(() => _notificationsEnabled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final user = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: false,
        title: Text('Settings', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          // Profile Section
          PremiumCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'Kaveem Uddin',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? 'kaveem@kaveem.com',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart),
          
          const SizedBox(height: 32),
          
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text('Appearance', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          ).animate().fadeIn(delay: 100.ms),
          
          PremiumCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildThemeOption(
                  context,
                  title: 'System Default',
                  icon: LucideIcons.smartphone,
                  mode: ThemeMode.system,
                  currentMode: themeMode,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    themeNotifier.setTheme(ThemeMode.system);
                  },
                ),
                Divider(height: 1, color: theme.colorScheme.outline.withValues(alpha: 0.2), indent: 56),
                _buildThemeOption(
                  context,
                  title: 'Light Mode',
                  icon: LucideIcons.sun,
                  mode: ThemeMode.light,
                  currentMode: themeMode,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    themeNotifier.setTheme(ThemeMode.light);
                  },
                ),
                Divider(height: 1, color: theme.colorScheme.outline.withValues(alpha: 0.2), indent: 56),
                _buildThemeOption(
                  context,
                  title: 'Dark Mode',
                  icon: LucideIcons.moon,
                  mode: ThemeMode.dark,
                  currentMode: themeMode,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    themeNotifier.setTheme(ThemeMode.dark);
                  },
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart),

          const SizedBox(height: 32),

          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text('Notifications', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          ).animate().fadeIn(delay: 300.ms),

          PremiumCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)),
                child: Icon(LucideIcons.bellRing, color: theme.colorScheme.primary, size: 20),
              ),
              title: Text('Push Notifications', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              trailing: Switch.adaptive(
                value: _notificationsEnabled,
                onChanged: _toggleNotifications,
                activeTrackColor: theme.colorScheme.primary,
              ),
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart),

          const SizedBox(height: 12),

          PremiumCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(LucideIcons.send, color: theme.colorScheme.primary, size: 20),
              ),
              title: Text('Send Test Notification', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text('Verify notification alerts work on this device', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              onTap: () async {
                HapticFeedback.mediumImpact();
                await NotificationService().showTestNotification();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(LucideIcons.bellRing, size: 18, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Test notification sent! Check your notification center.'),
                        ],
                      ),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
            ),
          ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart),

          const SizedBox(height: 32),

          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text('Account', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          ).animate().fadeIn(delay: 500.ms),

          PremiumCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: theme.colorScheme.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(LucideIcons.logOut, color: theme.colorScheme.error, size: 20),
              ),
              title: Text('Log Out', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.error, fontWeight: FontWeight.w600)),
              onTap: () async {
                HapticFeedback.mediumImpact();
                await authNotifier.signOut();
              },
            ),
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isSelected = mode == currentMode;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: theme.colorScheme.onSurface, size: 20),
      ),
      title: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
      trailing: isSelected ? Icon(LucideIcons.check, color: theme.colorScheme.primary) : null,
      onTap: onTap,
    );
  }
}
