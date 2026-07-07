import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/providers.dart';
import '../models/task_model.dart';
import '../models/focus_session_model.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  String _dateRange = 'This Week'; // This Week, This Month, All Time

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksStreamProvider);
    final sessionsAsync = ref.watch(focusSessionsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        title: const Text('Insights', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF9F9FF),
        elevation: 0,
      ),
      body: tasksAsync.when(
        data: (tasks) {
          return sessionsAsync.when(
            data: (sessions) {
              final now = DateTime.now();
              DateTime startDate;
              if (_dateRange == 'This Week') {
                startDate = now.subtract(Duration(days: now.weekday - 1));
              } else if (_dateRange == 'This Month') {
                startDate = DateTime(now.year, now.month, 1);
              } else {
                startDate = DateTime(2000);
              }

              final filteredTasks = tasks.where((t) {
                if (!t.isCompleted || t.dueDate == null) return false;
                return t.dueDate!.isAfter(startDate.subtract(const Duration(days: 1)));
              }).toList();

              final filteredSessions = sessions.where((s) {
                return s.timestamp.isAfter(startDate.subtract(const Duration(days: 1)));
              }).toList();

              final completedTasksCount = filteredTasks.length;
              final focusMinutes = filteredSessions.fold<int>(0, (prev, s) => prev + s.durationMinutes);
              final focusHours = (focusMinutes / 60).toStringAsFixed(1);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['This Week', 'This Month', 'All Time'].map((range) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(range),
                              selected: _dateRange == range,
                              onSelected: (val) {
                                if (val) setState(() => _dateRange = range);
                              },
                              selectedColor: const Color(0xFFC3C0FF),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Row(
                      children: [
                        Expanded(child: _buildMetricCard('Tasks Completed', completedTasksCount.toString(), Icons.check_circle)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildMetricCard('Focus Hours', focusHours, Icons.timer)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const Text('Productivity Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 300,
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: (completedTasksCount > 10 ? completedTasksCount.toDouble() : 10) + 2,
                              barTouchData: BarTouchData(enabled: false),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text('D${value.toInt()}', style: const TextStyle(fontSize: 10)),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              barGroups: _generateBarGroups(filteredTasks, startDate),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF3525CD)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'Geist')),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _generateBarGroups(List<Task> tasks, DateTime startDate) {
    int days = _dateRange == 'This Week' ? 7 : (_dateRange == 'This Month' ? 30 : 7);
    Map<int, int> counts = {};
    for (var t in tasks) {
      if (t.dueDate != null) {
        int diff = t.dueDate!.difference(startDate).inDays;
        if (diff >= 0 && diff < days) {
          counts[diff] = (counts[diff] ?? 0) + 1;
        }
      }
    }

    return List.generate(days, (i) {
      return BarChartGroupData(
        x: i + 1,
        barRods: [
          BarChartRodData(
            toY: (counts[i] ?? 0).toDouble(),
            color: const Color(0xFF3525CD),
            width: 16,
            borderRadius: BorderRadius.circular(4),
          )
        ],
      );
    });
  }
}
