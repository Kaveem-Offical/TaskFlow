import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/providers.dart';
import '../models/focus_session_model.dart';
import '../models/task_model.dart';
import 'tasks_screen.dart';
import 'calendar_screen.dart';
import 'focus_screen.dart';
import 'insights_screen.dart';
import 'analytics_screen.dart';
import 'dart:async';
import 'package:home_widget/home_widget.dart';
import 'settings_screen.dart';
import '../services/widget_service.dart';
import '../services/notification_service.dart';

class RootScreen extends ConsumerStatefulWidget {
  const RootScreen({super.key});

  @override
  ConsumerState<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends ConsumerState<RootScreen> with WidgetsBindingObserver {
  final List<Widget> _screens = [
    const TasksScreen(),
    const CalendarScreen(),
    const FocusScreen(),
    const InsightsScreen(),
    const AnalyticsScreen(),
    const SettingsScreen(),
  ];

  List<Task> _latestTasks = [];
  List<FocusSession> _latestSessions = [];
  StreamSubscription<Uri?>? _widgetClickSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService().clearDeliveredNotifications();
    _listenToWidgetClicks();
  }

  void _listenToWidgetClicks() {
    // Cold launch from widget click
    HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
      if (uri != null) {
        _handleWidgetClick(uri);
      }
    });

    // Warm launch/resume from widget click
    _widgetClickSub = HomeWidget.widgetClicked.listen((uri) {
      if (uri != null) {
        _handleWidgetClick(uri);
      }
    });
  }

  void _handleWidgetClick(Uri uri) {
    final uriStr = uri.toString();
    if (uri.host == 'insights' || uriStr.contains('insights')) {
      ref.read(navigationProvider.notifier).setIndex(3);
    } else if (uri.host == 'focus' || uriStr.contains('focus')) {
      ref.read(navigationProvider.notifier).setIndex(2);
    } else if (uri.host == 'add_task' || uriStr.contains('add_task')) {
      ref.read(navigationProvider.notifier).setIndex(0);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          showTaskModal(context, ref, null);
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _widgetClickSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationService().clearDeliveredNotifications();
    }
  }

  void _refreshWidget() {
    WidgetService.updateWidget(_latestTasks, _latestSessions);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);
    final theme = Theme.of(context);

    // Listen to tasks + focus sessions and refresh widget whenever either changes
    ref.listen(tasksStreamProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        _latestTasks = next.value!;
        _refreshWidget();
      }
    });

    ref.listen(focusSessionsStreamProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        _latestSessions = next.value!;
        _refreshWidget();
      }
    });

    return Scaffold(
      extendBody: true, // Needed for floating/glassmorphism navbar
      body: _screens[currentIndex]
        .animate(key: ValueKey(currentIndex))
        .fadeIn(duration: 300.ms, curve: Curves.easeOut)
        .slideY(begin: 0.05, end: 0, duration: 300.ms, curve: Curves.easeOutQuart),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showTaskModal(context, ref, null),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(LucideIcons.plus, size: 28),
      ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.elasticOut),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5), width: 0.5)),
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: BottomAppBar(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              color: theme.colorScheme.surface.withValues(alpha: 0.7),
              elevation: 0,
              shape: const CircularNotchedRectangle(),
              notchMargin: 12.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(context, currentIndex, 0, LucideIcons.checkCircle2, 'Tasks'),
                        _buildNavItem(context, currentIndex, 1, LucideIcons.calendar, 'Calendar'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 64), // Space for FAB
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(context, currentIndex, 3, LucideIcons.barChart3, 'Insights'),
                        _buildNavItem(context, currentIndex, 5, LucideIcons.settings, 'Settings'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int currentIndex, int itemIndex, IconData icon, String label) {
    final isSelected = currentIndex == itemIndex;
    final theme = Theme.of(context);
    
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(navigationProvider.notifier).setIndex(itemIndex);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            )
            .animate(target: isSelected ? 1 : 0)
            .scaleXY(begin: 1.0, end: 1.1, duration: 150.ms, curve: Curves.easeOutBack)
            .tint(color: theme.colorScheme.primary, duration: 150.ms),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
