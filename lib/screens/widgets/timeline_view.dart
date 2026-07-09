import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/task_model.dart';
import '../../models/event_model.dart';

class TimelineViewWidget extends StatelessWidget {
  final List<dynamic> items; // Tasks and Events
  final DateTime selectedDay;
  final Function(dynamic) onItemTap;

  const TimelineViewWidget({
    super.key,
    required this.items,
    required this.selectedDay,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    const double hourWidth = 100.0; // Slightly wider for better readability
    const int startHour = 7;
    const int endHour = 20; // 7 AM to 8 PM
    final double totalWidth = (endHour - startHour + 1) * hourWidth;
    const double laneHeight = 70.0;
    
    // Sort items by start time
    final sortedItems = List.from(items)..sort((a, b) {
      DateTime? timeA = _getStartTime(a);
      DateTime? timeB = _getStartTime(b);
      if (timeA == null && timeB == null) return 0;
      if (timeA == null) return 1;
      if (timeB == null) return -1;
      return timeA.compareTo(timeB);
    });

    // Calculate lanes
    final List<List<dynamic>> lanes = [];
    final Map<dynamic, int> itemLanes = {};
    
    for (var item in sortedItems) {
      final startTime = _getStartTime(item);
      if (startTime == null) continue;
      
      final endTime = _getEndTime(item) ?? startTime.add(const Duration(hours: 1));
      
      int assignedLane = -1;
      for (int i = 0; i < lanes.length; i++) {
        bool overlap = false;
        for (var laneItem in lanes[i]) {
          final laneItemStart = _getStartTime(laneItem)!;
          final laneItemEnd = _getEndTime(laneItem) ?? laneItemStart.add(const Duration(hours: 1));
          
          if (startTime.isBefore(laneItemEnd) && endTime.isAfter(laneItemStart)) {
            overlap = true;
            break;
          }
        }
        if (!overlap) {
          assignedLane = i;
          break;
        }
      }
      
      if (assignedLane == -1) {
        assignedLane = lanes.length;
        lanes.add([]);
      }
      
      lanes[assignedLane].add(item);
      itemLanes[item] = assignedLane;
    }

    final double totalHeight = 40.0 + (lanes.isEmpty ? laneHeight : lanes.length * laneHeight);

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: totalWidth,
          height: totalHeight > MediaQuery.of(context).size.height ? totalHeight : MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              // Background Grid and Time Labels
              Positioned.fill(
                child: CustomPaint(
                  painter: _GridPainter(
                    startHour: startHour,
                    endHour: endHour,
                    hourWidth: hourWidth,
                    lineColor: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                    textColor: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
              
              // Current Time Indicator (if selected day is today)
              if (DateUtils.isSameDay(selectedDay, DateTime.now()))
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CurrentTimePainter(
                      startHour: startHour,
                      hourWidth: hourWidth,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              
              // Items
              ...sortedItems.map((item) {
                final startTime = _getStartTime(item);
                if (startTime == null) return const SizedBox();
                
                final endTime = _getEndTime(item) ?? startTime.add(const Duration(hours: 1));
                
                // Calculate positions
                double leftOffset = ((startTime.hour - startHour) + (startTime.minute / 60.0)) * hourWidth;
                if (leftOffset < 0) leftOffset = 0;
                
                double durationHours = endTime.difference(startTime).inMinutes / 60.0;
                if (durationHours <= 0) durationHours = 1.0; // Minimum 1 hour block visually
                double width = durationHours * hourWidth;
                
                // Keep some padding between items
                if (width > 4) width -= 4; 
                
                final lane = itemLanes[item] ?? 0;
                final topOffset = 40.0 + (lane * laneHeight);

                return Positioned(
                  left: leftOffset + 2, // slight margin
                  top: topOffset + 2, // slight margin
                  child: GestureDetector(
                    onTap: () => onItemTap(item),
                    child: _buildItemCard(context, item, width, laneHeight - 4),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  DateTime? _getStartTime(dynamic item) {
    if (item is Task) return item.startTime ?? item.dueDate;
    if (item is Event) return item.startTime;
    return null;
  }
  
  DateTime? _getEndTime(dynamic item) {
    if (item is Task) return item.endTime;
    if (item is Event) return item.endTime;
    return null;
  }

  Widget _buildItemCard(BuildContext context, dynamic item, double width, double height) {
    final String title = item.title;
    final String subtitle = item is Task ? item.description : 'Event';
    final bool isTask = item is Task;
    final bool isCompleted = isTask ? item.isCompleted : false;
    
    // Google Calendar style solid color blocks
    Color bgColor = isTask 
        ? (isCompleted ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.6) : const Color(0xFF0F9D58)) // Google Green for tasks
        : Theme.of(context).colorScheme.primary;

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              color: Colors.white,
            ),
          ),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final int startHour;
  final int endHour;
  final double hourWidth;
  final Color lineColor;
  final Color textColor;

  _GridPainter({
    required this.startHour,
    required this.endHour,
    required this.hourWidth,
    required this.lineColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
    );

    for (int i = 0; i <= (endHour - startHour); i++) {
      double x = i * hourWidth;
      
      // Draw vertical dashed line
      double dashHeight = 4.0;
      double dashSpace = 4.0;
      double startY = 30.0;
      while (startY < size.height) {
        canvas.drawLine(Offset(x, startY), Offset(x, startY + dashHeight), linePaint);
        startY += dashHeight + dashSpace;
      }
      
      // Draw time text
      int hour = startHour + i;
      String timeText = '${hour.toString().padLeft(2, '0')}:00';
      
      textPainter.text = TextSpan(
        text: timeText,
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - (textPainter.width / 2), 10));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CurrentTimePainter extends CustomPainter {
  final int startHour;
  final double hourWidth;
  final Color color;

  _CurrentTimePainter({
    required this.startHour,
    required this.hourWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    if (now.hour < startHour) return;

    double x = ((now.hour - startHour) + (now.minute / 60.0)) * hourWidth;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0;

    // Draw vertical line
    canvas.drawLine(Offset(x, 30), Offset(x, size.height), paint);
    
    // Draw dot at bottom
    canvas.drawCircle(Offset(x, size.height - 10), 4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true; // Re-paint as time changes
}
