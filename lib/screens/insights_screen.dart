import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../models/task_model.dart';
import '../models/focus_session_model.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  String _detailsTab = 'Day';
  String _trendsTab = 'Week';
  
  // Date tracking for real data charts
  DateTime _timelineDate = DateTime.now();
  DateTime _mostFocusedDate = DateTime.now();
  DateTime _yearGridDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksStreamProvider);
    final sessionsAsync = ref.watch(focusSessionsStreamProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Focus Statistics', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: tasksAsync.when(
        data: (tasks) {
          return sessionsAsync.when(
            data: (sessions) {
              return SingleChildScrollView(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTopKPIs(sessions, context),
                    const SizedBox(height: 16),
                    _buildFocusRecord(sessions, tasks, context, ref),
                    const SizedBox(height: 16),
                    _buildDetailsSection(sessions, tasks, context),
                    const SizedBox(height: 16),
                    _buildTrendsSection(sessions, context),
                    const SizedBox(height: 16),
                    _buildTimelineSection(sessions, context),
                    const SizedBox(height: 16),
                    _buildMostFocusedTimeSection(sessions, context),
                    const SizedBox(height: 16),
                    _buildYearGridsSection(sessions, context),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e', style: TextStyle(color: Theme.of(context).colorScheme.error))),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e', style: TextStyle(color: Theme.of(context).colorScheme.error))),
      ),
    );
  }

  Widget _buildTopKPIs(List<FocusSession> sessions, BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    int todayPomos = 0;
    int yesterdayPomos = 0;
    int todayFocusMinutes = 0;
    int yesterdayFocusMinutes = 0;
    int totalPomos = sessions.length;
    int totalFocusMinutes = 0;

    for (var s in sessions) {
      totalFocusMinutes += s.durationMinutes;
      final sessionDate = DateTime(s.timestamp.year, s.timestamp.month, s.timestamp.day);
      if (sessionDate.isAtSameMomentAs(today)) {
        todayPomos++;
        todayFocusMinutes += s.durationMinutes;
      } else if (sessionDate.isAtSameMomentAs(yesterday)) {
        yesterdayPomos++;
        yesterdayFocusMinutes += s.durationMinutes;
      }
    }

    final pomoDiff = todayPomos - yesterdayPomos;
    final focusDiffMinutes = todayFocusMinutes - yesterdayFocusMinutes;
    final focusDiffH = focusDiffMinutes.abs() ~/ 60;
    final focusDiffM = focusDiffMinutes.abs() % 60;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                title: "Today's Pomo",
                value: todayPomos.toString(),
                trendText: "${pomoDiff.abs()} from yesterday",
                isUp: pomoDiff >= 0,
                context: context,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKPICard(
                title: "Today's Focus (h)",
                value: "${todayFocusMinutes ~/ 60}h ${todayFocusMinutes % 60}m",
                trendText: "${focusDiffH}h${focusDiffM}m from yesterday",
                isUp: focusDiffMinutes >= 0,
                context: context,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                title: "Total Pomos",
                value: totalPomos.toString(),
                trendText: "",
                context: context,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKPICard(
                title: "Total Focus Duration",
                value: "${totalFocusMinutes ~/ 60}h ${totalFocusMinutes % 60}m",
                trendText: "",
                context: context,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKPICard({required String title, required String value, required String trendText, bool? isUp, required BuildContext context}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (trendText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    trendText, 
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(isUp == true ? Icons.arrow_upward : Icons.arrow_downward, color: isUp == true ? Colors.green : theme.colorScheme.error, size: 12),
              ],
            ),
          ],
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusRecord(List<FocusSession> sessions, List<Task> tasks, BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sortedSessions = List<FocusSession>.from(sessions)..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final recentSessions = sortedSessions.take(3).toList(); 

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Focus Record', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.bold)),
              IconButton(
                icon: Icon(Icons.add, color: theme.colorScheme.primary, size: 24),
                onPressed: () => _showAddSessionDialog(context, ref, tasks),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recentSessions.isEmpty)
            Text('No focus records yet.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13))
          else
            ...recentSessions.asMap().entries.map((entry) {
              final idx = entry.key;
              final session = entry.value;
              final task = tasks.firstWhere((t) => t.id == session.linkedTaskId, orElse: () => Task(id: '', title: 'General Task'));
              final isFirst = idx == 0;
              
              final timeFormat = DateFormat('hh:mm a');
              final startTimeStr = timeFormat.format(session.timestamp);
              final endTimeStr = timeFormat.format(session.timestamp.add(Duration(minutes: session.durationMinutes)));
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4, right: 12),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFirst ? theme.colorScheme.primary : Colors.transparent,
                        border: Border.all(color: theme.colorScheme.primary, width: 2),
                      ),
                      child: isFirst ? Icon(Icons.check, size: 10, color: theme.colorScheme.onPrimary) : null,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(DateFormat('d MMM').format(session.timestamp), style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w500)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '$startTimeStr - $endTimeStr', 
                                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('${session.durationMinutes ~/ 60 > 0 ? "${session.durationMinutes ~/ 60}h " : ""}${session.durationMinutes % 60 > 0 ? "${session.durationMinutes % 60}m" : ""}'.trim(), 
                                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(task.title, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(List<FocusSession> sessions, List<Task> tasks, BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Details', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Icon(Icons.chevron_left, color: theme.colorScheme.onSurfaceVariant, size: 18),
                  const SizedBox(width: 4),
                  Text('Today', style: TextStyle(color: theme.colorScheme.primary, fontSize: 13)),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: theme.colorScheme.primary, size: 18),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSegmentedControl(['Day', 'Week', 'Month', 'Custom'], _detailsTab, (v) => setState(() => _detailsTab = v), context),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              height: 150,
              width: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 55,
                      sections: [
                        PieChartSectionData(
                          value: 100,
                          color: theme.dividerColor,
                          radius: 12,
                          showTitle: false,
                        ),
                      ],
                    ),
                  ),
                  Text('No Data', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Focus Ranking', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13)),
              Row(
                children: [
                  Text('List', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                  Icon(Icons.keyboard_arrow_down, color: theme.colorScheme.onSurfaceVariant, size: 16),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('None', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTrendsSection(List<FocusSession> sessions, BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Trends', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Icon(Icons.chevron_left, color: theme.colorScheme.primary, size: 18),
                  const SizedBox(width: 4),
                  Text('This Week', style: TextStyle(color: theme.colorScheme.primary, fontSize: 13)),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant, size: 18),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: _buildSegmentedControl(['Week', 'Month', 'Year'], _trendsTab, (v) => setState(() => _trendsTab = v), context, compact: true),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text('No Data', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14)),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'].map((day) => 
              Text(day, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12))
            ).toList(),
          ),
          const SizedBox(height: 16),
          Divider(color: theme.dividerColor),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Daily Average', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
              Text('0m', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(List<FocusSession> sessions, BuildContext context) {
    final theme = Theme.of(context);
    DateTime startOfWeek = _timelineDate.subtract(Duration(days: _timelineDate.weekday - 1));
    startOfWeek = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));

    final weekSessions = sessions.where((s) => s.timestamp.isAfter(startOfWeek) && s.timestamp.isBefore(endOfWeek)).toList();

    return _buildChartSection(
      title: 'Timeline',
      dateLabel: 'This Week',
      onPrev: () => setState(() => _timelineDate = _timelineDate.subtract(const Duration(days: 7))),
      onNext: () => setState(() => _timelineDate = _timelineDate.add(const Duration(days: 7))),
      context: context,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: ['00:00', '06:00', '12:00', '18:00'].map((t) => 
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(t, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10)),
                  )
                ).toList(),
              ),
              Expanded(
                child: Container(
                  height: 120,
                  padding: const EdgeInsets.only(left: 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final height = constraints.maxHeight;
                      final dayHeight = height / 7.0;

                      return Stack(
                        children: weekSessions.map((session) {
                          int dayIndex = session.timestamp.weekday - 1;
                          int minutesSinceMidnight = session.timestamp.hour * 60 + session.timestamp.minute;
                          
                          double leftPos = (minutesSinceMidnight / 1440.0) * width;
                          double blockWidth = (session.durationMinutes / 1440.0) * width;
                          if (blockWidth < 2) blockWidth = 2;
                          if (leftPos + blockWidth > width) blockWidth = width - leftPos;

                          double topPos = dayIndex * dayHeight + (dayHeight * 0.2);

                          return Positioned(
                            left: leftPos,
                            top: topPos,
                            width: blockWidth,
                            height: dayHeight * 0.6,
                            child: Container(
                              color: theme.colorScheme.primary.withValues(alpha: 0.8),
                            ),
                          );
                        }).toList(),
                      );
                    }
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 40.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) => 
                Text(day, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10))
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMostFocusedTimeSection(List<FocusSession> sessions, BuildContext context) {
    final theme = Theme.of(context);
    final monthSessions = sessions.where((s) => s.timestamp.year == _mostFocusedDate.year && s.timestamp.month == _mostFocusedDate.month).toList();

    List<int> hourlyMinutes = List.filled(24, 0);
    for (var s in monthSessions) {
      hourlyMinutes[s.timestamp.hour] += s.durationMinutes;
    }

    int maxMinutes = hourlyMinutes.reduce((curr, next) => curr > next ? curr : next);
    if (maxMinutes == 0) maxMinutes = 60;

    return _buildChartSection(
      title: 'Most Focused Time',
      dateLabel: DateFormat('MMM yyyy').format(_mostFocusedDate),
      onPrev: () => setState(() => _mostFocusedDate = DateTime(_mostFocusedDate.year, _mostFocusedDate.month - 1, 1)),
      onNext: () => setState(() => _mostFocusedDate = DateTime(_mostFocusedDate.year, _mostFocusedDate.month + 1, 1)),
      context: context,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${maxMinutes ~/ 60}h${maxMinutes % 60}m', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10)),
              Text('${(maxMinutes * 0.75) ~/ 60}h${((maxMinutes * 0.75).toInt()) % 60}m', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10)),
              Text('${(maxMinutes * 0.5) ~/ 60}h${((maxMinutes * 0.5).toInt()) % 60}m', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10)),
              Text('${(maxMinutes * 0.25) ~/ 60}h${((maxMinutes * 0.25).toInt()) % 60}m', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10)),
              Text('0m', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10)),
            ].map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: e)).toList(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(24, (index) {
                  double pct = hourlyMinutes[index] / maxMinutes;
                  double height = 120 * pct;
                  if (height < 2 && hourlyMinutes[index] > 0) height = 2;
                  
                  return Container(
                    width: 8,
                    height: height,
                    decoration: BoxDecoration(
                      color: height > 0 ? theme.colorScheme.primary : theme.dividerColor,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(2), topRight: Radius.circular(2)),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearGridsSection(List<FocusSession> sessions, BuildContext context) {
    final theme = Theme.of(context);
    int year = _yearGridDate.year;
    
    Map<int, int> dayMinutes = {};
    for (var s in sessions) {
      if (s.timestamp.year == year) {
        int dayOfYear = s.timestamp.difference(DateTime(year, 1, 1)).inDays;
        dayMinutes[dayOfYear] = (dayMinutes[dayOfYear] ?? 0) + s.durationMinutes;
      }
    }

    bool isLeap = (year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0));
    int totalDays = isLeap ? 366 : 365;
    int weeks = (totalDays / 7).ceil();

    return _buildChartSection(
      title: 'Year Grids',
      dateLabel: year.toString(),
      onPrev: () => setState(() => _yearGridDate = DateTime(year - 1, 1, 1)),
      onNext: () => setState(() => _yearGridDate = DateTime(year + 1, 1, 1)),
      context: context,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Jan', 'Apr', 'Jul', 'Oct'].map((m) => 
              Text(m, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10))
            ).toList(),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(weeks, (weekIndex) {
                return Padding(
                  padding: const EdgeInsets.only(right: 2.0),
                  child: Column(
                    children: List.generate(7, (dayIndex) {
                      int dayOfYear = weekIndex * 7 + dayIndex;
                      if (dayOfYear >= totalDays) return const SizedBox(width: 10, height: 10);
                      
                      int minutes = dayMinutes[dayOfYear] ?? 0;
                      Color color = theme.dividerColor;
                      if (minutes > 300) {
                        color = theme.colorScheme.primary;
                      } else if (minutes >= 180) {
                        color = theme.colorScheme.primary.withValues(alpha: 0.8);
                      } else if (minutes >= 60) {
                        color = theme.colorScheme.primary.withValues(alpha: 0.5);
                      } else if (minutes > 0) {
                        color = theme.colorScheme.primary.withValues(alpha: 0.2); // Replacing white with a low opacity primary to match theme better
                      }
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 2.0),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildLegendItem(theme.dividerColor, '0m', context),
                const SizedBox(width: 8),
                _buildLegendItem(theme.colorScheme.primary.withValues(alpha: 0.2), '0-1h', context),
                const SizedBox(width: 8),
                _buildLegendItem(theme.colorScheme.primary.withValues(alpha: 0.5), '1h-3h', context),
                const SizedBox(width: 8),
                _buildLegendItem(theme.colorScheme.primary.withValues(alpha: 0.8), '3h-5h', context),
                const SizedBox(width: 8),
                _buildLegendItem(theme.colorScheme.primary, '>5h', context),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10)),
      ],
    );
  }

  Widget _buildChartSection({
    required String title, 
    required String dateLabel, 
    required VoidCallback onPrev,
    required VoidCallback onNext,
    required Widget child,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  GestureDetector(
                    onTap: onPrev,
                    child: Icon(Icons.chevron_left, color: theme.colorScheme.primary, size: 24)
                  ),
                  const SizedBox(width: 4),
                  Text(dateLabel, style: TextStyle(color: theme.colorScheme.primary, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onNext,
                    child: Icon(Icons.chevron_right, color: theme.colorScheme.primary, size: 24)
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSegmentedControl(List<String> options, String selected, ValueChanged<String> onSelected, BuildContext context, {bool compact = false}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: options.map((option) {
          final isSelected = selected == option;
          return Expanded(
            flex: compact ? 0 : 1,
            child: GestureDetector(
              onTap: () => onSelected(option),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: compact ? 16 : 8),
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  void _showAddSessionDialog(BuildContext context, WidgetRef ref, List<Task> tasks) {
    int durationMinutes = 25;
    String? selectedTaskId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Focus Session'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: 'Duration (minutes)'),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      durationMinutes = int.tryParse(val) ?? 25;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Task (Optional)'),
                    value: selectedTaskId,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('No Task')),
                      ...tasks.where((t) => !t.isCompleted).map((t) => DropdownMenuItem(
                        value: t.id,
                        child: Text(t.title, overflow: TextOverflow.ellipsis),
                      )),
                    ],
                    onChanged: (val) {
                      setState(() => selectedTaskId = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    ref.read(focusSessionRepositoryProvider).addFocusSession(FocusSession(
                      id: '',
                      durationMinutes: durationMinutes,
                      timestamp: DateTime.now(),
                      linkedTaskId: selectedTaskId,
                    ));
                    Navigator.pop(context);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
