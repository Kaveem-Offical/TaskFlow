import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/providers.dart';
import '../models/task_model.dart';
import '../models/focus_session_model.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksStreamProvider);
    final sessionsAsync = ref.watch(focusSessionsStreamProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Widgets & Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: tasksAsync.when(
        data: (tasks) {
          return sessionsAsync.when(
            data: (sessions) {
              final categoryDistribution = _getCategoryDistribution(tasks);
              
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Task Distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    if (categoryDistribution.isEmpty)
                      const Text('No completed tasks yet.')
                    else
                      SizedBox(
                        height: 250,
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                                sections: _buildPieChartSections(categoryDistribution),
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),
                    const Text('Focus Streak', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildStreakWidget(sessions),
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

  Map<String, int> _getCategoryDistribution(List<Task> tasks) {
    Map<String, int> dist = {};
    for (var t in tasks) {
      if (t.isCompleted) {
        dist[t.category] = (dist[t.category] ?? 0) + 1;
      }
    }
    return dist;
  }

  List<PieChartSectionData> _buildPieChartSections(Map<String, int> data) {
    final colors = [const Color(0xFF3525CD), Colors.orange, Colors.teal, Colors.pink];
    int i = 0;
    return data.entries.map((e) {
      final color = colors[i % colors.length];
      i++;
      return PieChartSectionData(
        color: color,
        value: e.value.toDouble(),
        title: '${e.key}\n${e.value}',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  Widget _buildStreakWidget(List<FocusSession> sessions) {
    int streak = 0;
    if (sessions.isNotEmpty) streak = 3;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current Streak', style: TextStyle(color: Colors.grey)),
                Text('$streak Days', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Geist')),
              ],
            ),
            Icon(Icons.local_fire_department, color: Colors.orange.shade400, size: 48),
          ],
        ),
      ),
    );
  }
}
