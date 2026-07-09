import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'dart:ui' as ui;
import '../models/task_model.dart';
import '../models/focus_session_model.dart';

class WidgetService {
  static Future<void> init() async {
    await HomeWidget.setAppGroupId('group.com.example.taskflow_suite');
  }

  static Future<void> updateWidget(
    List<Task> tasks,
    List<FocusSession> sessions,
  ) async {
    try {
      await HomeWidget.renderFlutterWidget(
        _FocusDistributionWidget(tasks: tasks, sessions: sessions),
        logicalSize: const Size(400, 200),
        key: 'chart_image',
      );

      await HomeWidget.updateWidget(
        name: 'ProductivityWidgetProvider',
        iOSName: 'ProductivityWidget',
      );
    } catch (e) {
      debugPrint('Error updating widget: $e');
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Root widget rendered off-screen.
// RULES: no MaterialApp / Scaffold / ScaffoldMessenger / fl_chart.
//        Use only MediaQuery → Directionality → Material → CustomPaint.
// ──────────────────────────────────────────────────────────────────────────────
class _FocusDistributionWidget extends StatelessWidget {
  final List<Task> tasks;
  final List<FocusSession> sessions;

  const _FocusDistributionWidget({
    required this.tasks,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // Find start of current week (Monday)
    final weekdayOffset = (now.weekday - 1); // Mon=0
    final weekStart = todayStart.subtract(Duration(days: weekdayOffset));

    // Build task id → category map
    final taskCategory = <String, String>{};
    for (final t in tasks) {
      taskCategory[t.id] = t.category;
    }

    // Palette: category → color (assigned in order of first appearance)
    final palette = [
      const Color(0xFF6785FF),
      const Color(0xFFF08080),
      const Color(0xFFFFD56C),
      const Color(0xFFC780FF),
      const Color(0xFF7DE5C3),
    ];
    final categoryColors = <String, Color>{};
    Color colorFor(String cat) {
      return categoryColors.putIfAbsent(
          cat, () => palette[categoryColors.length % palette.length]);
    }

    // Aggregate sessions into: dayIndex (0=Mon … 6=Sun) → category → minutes
    final Map<int, Map<String, double>> dayData = {};
    int todayMinutes = 0;
    int weekMinutes = 0;

    for (final s in sessions) {
      final sDay = DateTime(s.timestamp.year, s.timestamp.month, s.timestamp.day);
      final diffFromWeekStart = sDay.difference(weekStart).inDays;
      if (diffFromWeekStart < 0 || diffFromWeekStart > 6) continue;

      weekMinutes += s.durationMinutes;
      if (sDay == todayStart) todayMinutes += s.durationMinutes;

      final cat = (s.linkedTaskId != null && taskCategory.containsKey(s.linkedTaskId))
          ? taskCategory[s.linkedTaskId]!
          : 'Other';
      colorFor(cat); // register color in order

      dayData.putIfAbsent(diffFromWeekStart, () => {});
      dayData[diffFromWeekStart]![cat] =
          (dayData[diffFromWeekStart]![cat] ?? 0) + s.durationMinutes;
    }

    // If no sessions at all, ensure we still show something for the categories
    if (sessions.isEmpty) {
      for (final t in tasks) {
        colorFor(t.category);
      }
    }

    // Today / Week stat strings
    final todayH = todayMinutes ~/ 60;
    final todayStr = todayH > 0 ? '${todayH}h' : '${todayMinutes}m';

    final weekH = weekMinutes ~/ 60;
    final weekM = weekMinutes % 60;
    final weekStr = weekM > 0 ? '${weekH}h${weekM}m' : '${weekH}h';

    // Day labels Mon → Sun
    final dayLabels = List.generate(7, (i) {
      final d = weekStart.add(Duration(days: i));
      const names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
      return names[d.weekday - 1];
    });

    return MediaQuery(
      data: const MediaQueryData(size: Size(400, 200)),
      child: Directionality(
        textDirection: ui.TextDirection.ltr,
        child: Material(
          color: const Color(0xFF1C1C1E),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // LEFT: stats + chart
                Expanded(
                  flex: 62,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats row
                      Row(
                        children: [
                          _StatLabel(title: 'Today', value: todayStr),
                          const SizedBox(width: 28),
                          _StatLabel(title: 'Week', value: weekStr),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Chart
                      Expanded(
                        child: _BarChart(
                          dayData: dayData,
                          categoryColors: categoryColors,
                          dayLabels: dayLabels,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // RIGHT: legend
                SizedBox(
                  width: 108,
                  child: _Legend(categoryColors: categoryColors),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Stat block  (Today / Week)
// ──────────────────────────────────────────────────────────────────────────────
class _StatLabel extends StatelessWidget {
  final String title;
  final String value;
  const _StatLabel({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: Color(0xFF9E9E9E), fontSize: 12, fontWeight: FontWeight.w400)),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold,
                height: 1.1)),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Legend
// ──────────────────────────────────────────────────────────────────────────────
class _Legend extends StatelessWidget {
  final Map<String, Color> categoryColors;
  const _Legend({required this.categoryColors});

  @override
  Widget build(BuildContext context) {
    if (categoryColors.isEmpty) {
      return const Center(
        child: Text('No data',
            style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 11)),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: categoryColors.entries.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Row(
            children: [
              Container(
                width: 9, height: 9,
                decoration: BoxDecoration(color: e.value, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  e.key,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Bar chart (pure CustomPaint – no fl_chart)
// ──────────────────────────────────────────────────────────────────────────────
class _BarChart extends StatelessWidget {
  final Map<int, Map<String, double>> dayData;
  final Map<String, Color> categoryColors;
  final List<String> dayLabels;

  const _BarChart({
    required this.dayData,
    required this.categoryColors,
    required this.dayLabels,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ChartPainter(
        dayData: dayData,
        categoryColors: categoryColors,
        dayLabels: dayLabels,
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final Map<int, Map<String, double>> dayData;
  final Map<String, Color> categoryColors;
  final List<String> dayLabels;

  _ChartPainter({
    required this.dayData,
    required this.categoryColors,
    required this.dayLabels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const xLabelH = 18.0; // height reserved for day labels
    const yLabelW = 30.0; // width reserved for hour labels

    final chartH = size.height - xLabelH;
    final chartW = size.width - yLabelW;

    // ── find max minutes ─────────────────────────────────────────────────────
    double maxMin = 0;
    for (final day in dayData.values) {
      final total = day.values.fold(0.0, (a, b) => a + b);
      if (total > maxMin) maxMin = total;
    }
    // round up maxMin to nearest "nice" hour boundary
    double maxMinutes = maxMin <= 0 ? 240 : maxMin * 1.25; // at least 4 h
    // Y labels: 0m, 4h, 8h, 12h (or scaled)
    final maxHours = (maxMinutes / 60).ceil();
    // choose step so we get ~3-4 labels
    int stepH = 4;
    if (maxHours > 12) stepH = 4;
    if (maxHours > 24) stepH = 8;
    final topH = ((maxHours / stepH).ceil() * stepH).clamp(stepH, 999);
    maxMinutes = topH * 60.0;

    // ── grid & y-axis labels ─────────────────────────────────────────────────
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.13)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final steps = topH ~/ stepH;
    for (int i = 0; i <= steps; i++) {
      final y = chartH - (chartH * i / steps);
      // dashed line
      _drawDashedLine(canvas, Offset(yLabelW, y), Offset(size.width, y), gridPaint);

      final hours = i * stepH;
      final label = hours == 0 ? '0m' : '${hours}h';
      _drawText(canvas, label, Offset(0, y - 7), const Color(0xFF9E9E9E), 9.5,
          align: ui.TextAlign.right, maxWidth: yLabelW - 4);
    }

    // ── bars ─────────────────────────────────────────────────────────────────
    final barSlot = chartW / 7;
    final barW = barSlot * 0.50;

    for (int dayIdx = 0; dayIdx < 7; dayIdx++) {
      final dayCounts = dayData[dayIdx] ?? {};
      final x = yLabelW + dayIdx * barSlot + (barSlot - barW) / 2;

      final total = dayCounts.values.fold(0.0, (a, b) => a + b);

      if (dayCounts.isEmpty || total == 0) {
        // tiny placeholder nub
        final rect = RRect.fromRectAndCorners(
          Rect.fromLTWH(x, chartH - 3, barW, 3),
          topLeft: const Radius.circular(2),
          topRight: const Radius.circular(2),
        );
        canvas.drawRRect(rect, Paint()..color = Colors.white10);
      } else {
        double currentPx = 0;
        final entries = dayCounts.entries.toList();

        for (int ei = 0; ei < entries.length; ei++) {
          final cat = entries[ei].key;
          final val = entries[ei].value;
          final segH = (val / maxMinutes) * chartH;
          final color = categoryColors[cat] ?? Colors.grey;
          final isTop = ei == entries.length - 1;

          final rect = RRect.fromRectAndCorners(
            Rect.fromLTWH(x, chartH - currentPx - segH, barW, segH),
            topLeft: isTop ? const Radius.circular(4) : Radius.zero,
            topRight: isTop ? const Radius.circular(4) : Radius.zero,
          );
          canvas.drawRRect(rect, Paint()..color = color);
          currentPx += segH;
        }
      }

      // day label
      _drawText(
        canvas,
        dayLabels[dayIdx],
        Offset(x + barW / 2 - 5, chartH + 4),
        const Color(0xFF9E9E9E),
        10.5,
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLen = 4.0;
    const gapLen = 4.0;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final dist = (end - start).distance;
    double drawn = 0;
    while (drawn < dist) {
      final segEnd = (drawn + dashLen).clamp(0, dist);
      final t0 = drawn / dist;
      final t1 = segEnd / dist;
      canvas.drawLine(
        Offset(start.dx + dx * t0, start.dy + dy * t0),
        Offset(start.dx + dx * t1, start.dy + dy * t1),
        paint,
      );
      drawn += dashLen + gapLen;
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    Color color,
    double fontSize, {
    ui.TextAlign align = ui.TextAlign.left,
    double maxWidth = 200,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      textAlign: align,
    )..layout(maxWidth: maxWidth);
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_ChartPainter old) => true;
}