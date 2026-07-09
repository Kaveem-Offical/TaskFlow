import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../providers/providers.dart';
import '../models/focus_session_model.dart';
import '../models/task_model.dart';
import 'tasks_screen.dart';
import 'calendar_screen.dart';
import 'focus_screen.dart';
import 'insights_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';
import '../services/widget_service.dart';

class RootScreen extends ConsumerStatefulWidget {
  const RootScreen({super.key});

  @override
  ConsumerState<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends ConsumerState<RootScreen> {
  final List<Widget> _screens = [
    TasksScreen(),
    CalendarScreen(),
    FocusScreen(),
    InsightsScreen(),
    AnalyticsScreen(),
    SettingsScreen(),
  ];

  List<Task> _latestTasks = [];
  List<FocusSession> _latestSessions = [];

  void _refreshWidget() {
    WidgetService.updateWidget(_latestTasks, _latestSessions);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);

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
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 250),
        child: IndexedStack(
          key: ValueKey<int>(currentIndex),
          index: currentIndex,
          children: _screens,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showTaskModal(context, ref, null),
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: const CircleBorder(),
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: BottomAppBar(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            height: 64,
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(context, currentIndex, 0, Icons.check_circle_outline, Icons.check_circle, 'Tasks'),
                      _buildNavItem(context, currentIndex, 1, Icons.calendar_month_outlined, Icons.calendar_month, 'Calendar'),
                    ],
                  ),
                ),
                const SizedBox(width: 48), // Space for FAB
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(context, currentIndex, 3, Icons.insights_outlined, Icons.insights, 'Insights'),
                      _buildNavItem(context, currentIndex, 5, Icons.settings_outlined, Icons.settings, 'Settings'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int currentIndex, int itemIndex, IconData icon, IconData activeIcon, String label) {
    final isSelected = currentIndex == itemIndex;
    return InkWell(
      onTap: () => ref.read(navigationProvider.notifier).setIndex(itemIndex),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
