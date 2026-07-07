import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/providers.dart';
import '../models/task_model.dart';
import '../models/focus_session_model.dart';
import '../theme/app_theme.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  String _dateRange = 'Last 7 Days'; // Last 7 Days, This Month, This Year

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksStreamProvider);
    final sessionsAsync = ref.watch(focusSessionsStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Insights', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.background,
        elevation: 0,
      ),
      body: tasksAsync.when(
        data: (tasks) {
          return sessionsAsync.when(
            data: (sessions) {
              final now = DateTime.now();
              DateTime startDate;
              
              if (_dateRange == 'Last 7 Days') {
                startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
              } else if (_dateRange == 'This Month') {
                startDate = DateTime(now.year, now.month, 1);
              } else {
                startDate = DateTime(now.year, 1, 1);
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
              final totalSessions = filteredSessions.length;
              final avgSession = totalSessions > 0 ? (focusMinutes / totalSessions).toStringAsFixed(0) : '0';

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 160.0), // Generous bottom padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time Range Selector
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['Last 7 Days', 'This Month', 'This Year'].map((range) {
                          final isSelected = _dateRange == range;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(
                                range,
                                style: TextStyle(
                                  color: isSelected ? AppTheme.onPrimary : AppTheme.onSurfaceVariant,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (val) {
                                if (val) setState(() => _dateRange = range);
                              },
                              backgroundColor: AppTheme.surface,
                              selectedColor: AppTheme.primary,
                              showCheckmark: false,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected ? AppTheme.primary : AppTheme.outlineVariant,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Metrics Grid
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.3,
                      children: [
                        _buildMetricCard('Tasks Done', completedTasksCount.toString(), Icons.check_circle_outline, AppTheme.tertiary),
                        _buildMetricCard('Focus Hours', focusHours, Icons.timer_outlined, AppTheme.primary),
                        _buildMetricCard('Sessions', totalSessions.toString(), Icons.play_circle_outline, AppTheme.secondary),
                        _buildMetricCard('Avg Session', '$avgSession m', Icons.analytics_outlined, AppTheme.error),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Productivity Overview Chart
                    const Text('Productivity Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Tasks completed over time', style: TextStyle(color: AppTheme.outline, fontSize: 14)),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 250,
                      child: Card(
                        elevation: 0,
                        color: AppTheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: AppTheme.outlineVariant.withOpacity(0.5)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                          child: _buildBarChart(filteredTasks, startDate),
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

  Widget _buildMetricCard(String title, String value, IconData icon, Color iconColor) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<Task> tasks, DateTime startDate) {
    final int itemsCount = _dateRange == 'This Year' ? 12 : (_dateRange == 'This Month' ? 31 : 7);
    Map<int, int> counts = {};

    for (var t in tasks) {
      if (t.dueDate != null) {
        if (_dateRange == 'This Year') {
          // Group by month
          int monthIndex = t.dueDate!.month - 1; // 0-based
          counts[monthIndex] = (counts[monthIndex] ?? 0) + 1;
        } else {
          // Group by days from start date
          int diff = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day)
              .difference(DateTime(startDate.year, startDate.month, startDate.day))
              .inDays;
          if (diff >= 0 && diff < itemsCount) {
            counts[diff] = (counts[diff] ?? 0) + 1;
          }
        }
      }
    }

    final barGroups = List.generate(itemsCount, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: (counts[i] ?? 0).toDouble(),
            color: AppTheme.primary,
            width: _dateRange == 'This Month' ? 6 : 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _getMaxY(counts) * 1.2,
              color: AppTheme.surfaceContainerHighest,
            ),
          )
        ],
      );
    });

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxY(counts) * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => AppTheme.onSurface,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toInt()} tasks',
                const TextStyle(color: AppTheme.surface, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return _getBottomTitles(value, meta, startDate);
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }

  double _getMaxY(Map<int, int> counts) {
    if (counts.isEmpty) return 5;
    double maxVal = counts.values.reduce((a, b) => a > b ? a : b).toDouble();
    return maxVal < 5 ? 5 : maxVal;
  }

  Widget _getBottomTitles(double value, TitleMeta meta, DateTime startDate) {
    final int index = value.toInt();
    String text = '';

    if (_dateRange == 'Last 7 Days') {
      final date = startDate.add(Duration(days: index));
      text = DateFormat('E').format(date); // Mon, Tue, Wed
    } else if (_dateRange == 'This Month') {
      if (index % 5 == 0 || index == 30) {
        final date = startDate.add(Duration(days: index));
        text = DateFormat('d').format(date);
      }
    } else if (_dateRange == 'This Year') {
      if (index % 2 == 0) { // Show every other month to avoid crowding
        final date = DateTime(startDate.year, index + 1, 1);
        text = DateFormat('MMM').format(date);
      }
    }

    if (text.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.outline,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
