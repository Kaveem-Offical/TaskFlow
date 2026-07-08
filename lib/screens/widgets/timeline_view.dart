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
    const double hourWidth = 80.0;
    const int startHour = 7;
    const int endHour = 20; // 7 AM to 8 PM
    final double totalWidth = (endHour - startHour + 1) * hourWidth;
    
    // Sort items by start time
    final sortedItems = List.from(items)..sort((a, b) {
      DateTime? timeA = _getStartTime(a);
      DateTime? timeB = _getStartTime(b);
      if (timeA == null && timeB == null) return 0;
      if (timeA == null) return 1;
      if (timeB == null) return -1;
      return timeA.compareTo(timeB);
    });

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: totalWidth,
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
            Padding(
              padding: const EdgeInsets.only(top: 40.0), // Space for time labels
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedItems.length,
                itemBuilder: (context, index) {
                  final item = sortedItems[index];
                  final startTime = _getStartTime(item);
                  if (startTime == null) return const SizedBox();
                  
                  final endTime = _getEndTime(item) ?? startTime.add(const Duration(hours: 1));
                  
                  // Calculate positions
                  double leftOffset = ((startTime.hour - startHour) + (startTime.minute / 60.0)) * hourWidth;
                  if (leftOffset < 0) leftOffset = 0;
                  
                  double durationHours = endTime.difference(startTime).inMinutes / 60.0;
                  if (durationHours <= 0) durationHours = 1.0;
                  double width = durationHours * hourWidth;
                  
                  // Ensure minimum width for readability
                  if (width < 120) width = 120;

                  return Container(
                    height: 80,
                    margin: const EdgeInsets.only(bottom: 16.0),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Hatched duration background (optional, simple version uses just card)
                        Positioned(
                          left: leftOffset,
                          child: GestureDetector(
                            onTap: () => onItemTap(item),
                            child: _buildItemCard(context, item, width),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
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

  Widget _buildItemCard(BuildContext context, dynamic item, double width) {
    final String title = item.title;
    final String subtitle = item is Task ? item.description : 'Event';
    final bool isTask = item is Task;
    final bool isCompleted = isTask ? item.isCompleted : false;
    
    // Choose color based on type or completion
    Color stripColor = isTask 
        ? (isCompleted ? Theme.of(context).colorScheme.outline : const Color(0xFF47d79c)) // Greenish for tasks
        : Theme.of(context).colorScheme.primary;

    return Container(
      width: width,
      height: 64,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: stripColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      color: isCompleted ? Theme.of(context).colorScheme.outline : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                ],
              ),
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
