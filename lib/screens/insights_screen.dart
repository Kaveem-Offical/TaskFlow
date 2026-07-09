import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/providers.dart';
import '../models/task_model.dart';
import '../models/focus_session_model.dart';
import '../widgets/premium/premium_card.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  String _detailsTab = 'Day';
  String _trendsTab = 'Week';
  
  DateTime _timelineDate = DateTime.now();
  DateTime _mostFocusedDate = DateTime.now();
  DateTime _yearGridDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksStreamProvider);
    final sessionsAsync = ref.watch(focusSessionsStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: false,
        title: Text('Insights', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.flame, color: theme.colorScheme.error),
            tooltip: 'Log Focus Record',
            onPressed: () {
              HapticFeedback.lightImpact();
              _showAddFocusRecordModal(context, DateTime.now());
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: tasksAsync.when(
        data: (tasks) {
          return sessionsAsync.when(
            data: (sessions) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTopKPIs(sessions, context).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart),
                    const SizedBox(height: 16),
                    _buildFocusRecord(sessions, tasks, context, ref).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart),
                    const SizedBox(height: 16),
                    _buildDetailsSection(sessions, tasks, context).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart),
                    const SizedBox(height: 16),
                    _buildTrendsSection(sessions, context).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart),
                    const SizedBox(height: 16),
                    _buildTimelineSection(sessions, context).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart),
                    const SizedBox(height: 16),
                    _buildMostFocusedTimeSection(sessions, context).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart),
                    const SizedBox(height: 16),
                    _buildYearGridsSection(sessions, context).animate().fadeIn(delay: 600.ms, duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e', style: TextStyle(color: theme.colorScheme.error))),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e', style: TextStyle(color: theme.colorScheme.error))),
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
            const SizedBox(width: 16),
            Expanded(
              child: _buildKPICard(
                title: "Today's Focus",
                value: "${todayFocusMinutes ~/ 60}h ${todayFocusMinutes % 60}m",
                trendText: "${focusDiffH}h${focusDiffM}m from yesterday",
                isUp: focusDiffMinutes >= 0,
                context: context,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
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
            const SizedBox(width: 16),
            Expanded(
              child: _buildKPICard(
                title: "Total Duration",
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
    return PremiumCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.headlineLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
              ),
            ),
          ),
          if (trendText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(isUp == true ? LucideIcons.trendingUp : LucideIcons.trendingDown, color: isUp == true ? Colors.green : theme.colorScheme.error, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    trendText, 
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isUp == true ? Colors.green : theme.colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ] else const SizedBox(height: 26),
        ],
      ),
    );
  }

  Widget _buildFocusRecord(List<FocusSession> sessions, List<Task> tasks, BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sortedSessions = List<FocusSession>.from(sessions)..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final recentSessions = sortedSessions.take(3).toList(); 

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Focus Record', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 20),
          if (recentSessions.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text('No focus records yet.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            )
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
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Dismissible(
                  key: Key(session.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(LucideIcons.trash2, color: theme.colorScheme.onError),
                  ),
                  onDismissed: (direction) {
                    ref.read(focusSessionRepositoryProvider).deleteFocusSession(session.id);
                    HapticFeedback.mediumImpact();
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 4, right: 16),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFirst ? theme.colorScheme.primary : Colors.transparent,
                          border: Border.all(color: isFirst ? theme.colorScheme.primary : theme.colorScheme.outline, width: 2),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(task.title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                Text('${session.durationMinutes ~/ 60 > 0 ? "${session.durationMinutes ~/ 60}h " : ""}${session.durationMinutes % 60 > 0 ? "${session.durationMinutes % 60}m" : ""}'.trim(), 
                                  style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${DateFormat('d MMM').format(session.timestamp)} • $startTimeStr - $endTimeStr', 
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(List<FocusSession> sessions, List<Task> tasks, BuildContext context) {
    final theme = Theme.of(context);
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 20),
          _buildSegmentedControl(['Day', 'Week', 'Month'], _detailsTab, (v) {
            HapticFeedback.selectionClick();
            setState(() => _detailsTab = v);
          }, context),
          const SizedBox(height: 32),
          Center(
            child: SizedBox(
              height: 180,
              width: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 65,
                      sections: [
                        PieChartSectionData(
                          value: 100,
                          color: theme.colorScheme.surfaceContainerHighest,
                          radius: 16,
                          showTitle: false,
                        ),
                      ],
                    ),
                  ),
                  Text('No Data', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Focus Ranking', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              Row(
                children: [
                  Text('List', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(width: 4),
                  Icon(LucideIcons.chevronDown, color: theme.colorScheme.onSurfaceVariant, size: 16),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('None', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildTrendsSection(List<FocusSession> sessions, BuildContext context) {
    final theme = Theme.of(context);
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Trends', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: _buildSegmentedControl(['Week', 'Month', 'Year'], _trendsTab, (v) {
              HapticFeedback.selectionClick();
              setState(() => _trendsTab = v);
            }, context, compact: true),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text('No Data', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'].map((day) => 
              Text(day, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))
            ).toList(),
          ),
          const SizedBox(height: 16),
          Divider(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Daily Average', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              Text('0m', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
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
      onPrev: () {
        HapticFeedback.lightImpact();
        setState(() => _timelineDate = _timelineDate.subtract(const Duration(days: 7)));
      },
      onNext: () {
        HapticFeedback.lightImpact();
        setState(() => _timelineDate = _timelineDate.add(const Duration(days: 7)));
      },
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
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(t, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  )
                ).toList(),
              ),
              Expanded(
                child: Container(
                  height: 140,
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
                          if (blockWidth < 4) blockWidth = 4;
                          if (leftPos + blockWidth > width) blockWidth = width - leftPos;

                          double topPos = dayIndex * dayHeight + (dayHeight * 0.2);

                          return Positioned(
                            left: leftPos,
                            top: topPos,
                            width: blockWidth,
                            height: dayHeight * 0.6,
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
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
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 40.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) => 
                Text(day, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))
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
      onPrev: () {
        HapticFeedback.lightImpact();
        setState(() => _mostFocusedDate = DateTime(_mostFocusedDate.year, _mostFocusedDate.month - 1, 1));
      },
      onNext: () {
        HapticFeedback.lightImpact();
        setState(() => _mostFocusedDate = DateTime(_mostFocusedDate.year, _mostFocusedDate.month + 1, 1));
      },
      context: context,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${maxMinutes ~/ 60}h${maxMinutes % 60}m', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              Text('${(maxMinutes * 0.75) ~/ 60}h${((maxMinutes * 0.75).toInt()) % 60}m', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              Text('${(maxMinutes * 0.5) ~/ 60}h${((maxMinutes * 0.5).toInt()) % 60}m', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              Text('${(maxMinutes * 0.25) ~/ 60}h${((maxMinutes * 0.25).toInt()) % 60}m', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              Text('0m', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ].map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: e)).toList(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 140,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(24, (index) {
                  double pct = hourlyMinutes[index] / maxMinutes;
                  double height = 140 * pct;
                  if (height < 2 && hourlyMinutes[index] > 0) height = 2;
                  
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutQuart,
                    width: 8,
                    height: height,
                    decoration: BoxDecoration(
                      color: height > 0 ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
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
      onPrev: () {
        HapticFeedback.lightImpact();
        setState(() => _yearGridDate = DateTime(year - 1, 1, 1));
      },
      onNext: () {
        HapticFeedback.lightImpact();
        setState(() => _yearGridDate = DateTime(year + 1, 1, 1));
      },
      context: context,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Jan', 'Apr', 'Jul', 'Oct'].map((m) => 
              Text(m, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))
            ).toList(),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(weeks, (weekIndex) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Column(
                    children: List.generate(7, (dayIndex) {
                      int dayOfYear = weekIndex * 7 + dayIndex;
                      if (dayOfYear >= totalDays) return const SizedBox(width: 12, height: 12);
                      
                      int minutes = dayMinutes[dayOfYear] ?? 0;
                      Color color = theme.colorScheme.surfaceContainerHighest;
                      if (minutes > 300) {
                         color = theme.colorScheme.primary;
                      } else if (minutes >= 180) {
                         color = theme.colorScheme.primary.withValues(alpha: 0.8);
                      } else if (minutes >= 60) {
                         color = theme.colorScheme.primary.withValues(alpha: 0.5);
                      } else if (minutes > 0) {
                         color = theme.colorScheme.primary.withValues(alpha: 0.2);
                      }
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4.0),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildLegendItem(theme.colorScheme.surfaceContainerHighest, '0m', context),
                const SizedBox(width: 12),
                _buildLegendItem(theme.colorScheme.primary.withValues(alpha: 0.2), '0-1h', context),
                const SizedBox(width: 12),
                _buildLegendItem(theme.colorScheme.primary.withValues(alpha: 0.5), '1h-3h', context),
                const SizedBox(width: 12),
                _buildLegendItem(theme.colorScheme.primary.withValues(alpha: 0.8), '3h-5h', context),
                const SizedBox(width: 12),
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
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: onPrev,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(LucideIcons.chevronLeft, color: theme.colorScheme.onSurface, size: 16),
                      )
                    ),
                    const SizedBox(width: 8),
                    Text(dateLabel, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onNext,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(LucideIcons.chevronRight, color: theme.colorScheme.onSurface, size: 16),
                      )
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
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
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: options.map((option) {
          final isSelected = selected == option;
          return Expanded(
            flex: compact ? 0 : 1,
            child: GestureDetector(
              onTap: () => onSelected(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: compact ? 16 : 8),
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ] : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  option,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showAddFocusRecordModal(BuildContext context, DateTime initialDate) {
    int durationMinutes = 25;
    DateTime date = initialDate;
    TimeOfDay time = TimeOfDay.now();
    String? selectedTaskId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final theme = Theme.of(context);
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24, right: 24, top: 24
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Log Focus Record', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                        IconButton(
                          icon: const Icon(LucideIcons.x),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Need to create a basic text field here since PremiumTextField might be custom
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Duration (minutes)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.number,
                      initialValue: durationMinutes.toString(),
                      onChanged: (val) {
                        durationMinutes = int.tryParse(val) ?? 25;
                      },
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            title: Text('Date: ${DateFormat.yMMMd().format(date)}', style: theme.textTheme.bodyMedium),
                            trailing: Icon(LucideIcons.calendar, color: theme.colorScheme.primary),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: date,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setModalState(() => date = picked);
                              }
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            title: Text('Time: ${time.format(context)}', style: theme.textTheme.bodyMedium),
                            trailing: Icon(LucideIcons.clock, color: theme.colorScheme.outline),
                            onTap: () async {
                              final picked = await showTimePicker(context: context, initialTime: time);
                              if (picked != null) {
                                setModalState(() => time = picked);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Link to Task (Optional)', style: theme.textTheme.labelMedium),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          isExpanded: true,
                          value: selectedTaskId,
                          hint: Text('Select a task', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          items: [
                            DropdownMenuItem<String?>(value: null, child: const Text('None')),
                            ...((ref.read(tasksStreamProvider).value ?? []).map((task) {
                              return DropdownMenuItem<String?>(
                                value: task.id,
                                child: Text(task.title, overflow: TextOverflow.ellipsis),
                              );
                            })),
                          ],
                          onChanged: (val) {
                            setModalState(() => selectedTaskId = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          if (durationMinutes > 0) {
                            final timestamp = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                            final record = FocusSession(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              durationMinutes: durationMinutes,
                              timestamp: timestamp,
                              linkedTaskId: selectedTaskId,
                            );
                            ref.read(focusSessionRepositoryProvider).addFocusSession(record);
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Save Focus Record', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }
}
