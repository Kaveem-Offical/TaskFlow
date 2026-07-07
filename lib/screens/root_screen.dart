import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../providers/providers.dart';
import 'tasks_screen.dart';
import 'calendar_screen.dart';
import 'focus_screen.dart';
import 'insights_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationProvider);

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
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
              border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3))),
            ),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (index) {
                ref.read(navigationProvider.notifier).setIndex(index);
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
              selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
              unselectedLabelStyle: TextStyle(fontSize: 10),
              items: [
                BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), activeIcon: Icon(Icons.check_circle), label: 'Tasks'),
                BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), activeIcon: Icon(Icons.calendar_month), label: 'Calendar'),
                BottomNavigationBarItem(icon: Icon(Icons.timer_outlined), activeIcon: Icon(Icons.timer), label: 'Focus'),
                BottomNavigationBarItem(icon: Icon(Icons.insights_outlined), activeIcon: Icon(Icons.insights), label: 'Insights'),
                BottomNavigationBarItem(icon: Icon(Icons.pie_chart_outline), activeIcon: Icon(Icons.pie_chart), label: 'Widgets'),
                BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Settings'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
