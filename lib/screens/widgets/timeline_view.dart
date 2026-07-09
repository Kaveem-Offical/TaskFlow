import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import '../../models/event_model.dart';

class TimelineViewWidget extends StatefulWidget {
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
  State<TimelineViewWidget> createState() => _TimelineViewWidgetState();
}

class _TimelineViewWidgetState extends State<TimelineViewWidget> {
  final ScrollController _scrollController = ScrollController();
  final double hourHeight = 60.0;
  final int startHour = 0;
  final int endHour = 24;
  final double timeColumnWidth = 60.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (DateUtils.isSameDay(widget.selectedDay, DateTime.now())) {
        final now = DateTime.now();
        final offset = (now.hour * hourHeight) - (MediaQuery.of(context).size.height / 3);
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            offset.clamp(0, (endHour - startHour) * hourHeight),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      } else {
        // Find earliest event and scroll to it
        if (widget.items.isNotEmpty) {
          final sorted = List.from(widget.items)..sort((a, b) {
            final tA = _getStartTime(a) ?? DateTime.now();
            final tB = _getStartTime(b) ?? DateTime.now();
            return tA.compareTo(tB);
          });
          final firstTime = _getStartTime(sorted.first);
          if (firstTime != null) {
            final offset = (firstTime.hour * hourHeight) - 60;
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                offset.clamp(0.0, (endHour - startHour) * hourHeight),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final double totalHeight = (endHour - startHour) * hourHeight;
    final theme = Theme.of(context);

    // Calculate overlapping items to adjust widths
    final sortedItems = List.from(widget.items)..sort((a, b) {
      DateTime? timeA = _getStartTime(a);
      DateTime? timeB = _getStartTime(b);
      if (timeA == null && timeB == null) return 0;
      if (timeA == null) return 1;
      if (timeB == null) return -1;
      return timeA.compareTo(timeB);
    });

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      child: SizedBox(
        height: totalHeight,
        child: Stack(
          children: [
            // Background grid
            Positioned.fill(
              child: CustomPaint(
                painter: _VerticalGridPainter(
                  startHour: startHour,
                  endHour: endHour,
                  hourHeight: hourHeight,
                  timeColumnWidth: timeColumnWidth,
                  lineColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  textColor: theme.colorScheme.outline,
                ),
              ),
            ),
            
            // Current Time Indicator
            if (DateUtils.isSameDay(widget.selectedDay, DateTime.now()))
              Positioned.fill(
                child: CustomPaint(
                  painter: _VerticalCurrentTimePainter(
                    startHour: startHour,
                    hourHeight: hourHeight,
                    timeColumnWidth: timeColumnWidth,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),

            // Events
            ...sortedItems.map((item) {
              final startTime = _getStartTime(item);
              if (startTime == null) return const SizedBox();
              
              final endTime = _getEndTime(item) ?? startTime.add(const Duration(minutes: 45));
              
              double topOffset = ((startTime.hour - startHour) + (startTime.minute / 60.0)) * hourHeight;
              if (topOffset < 0) topOffset = 0;
              
              double durationHours = endTime.difference(startTime).inMinutes / 60.0;
              if (durationHours <= 0) durationHours = 0.5; // Min 30 mins visual height
              double height = durationHours * hourHeight;
              if (height > 4) height -= 4; // Padding

              return Positioned(
                top: topOffset,
                left: timeColumnWidth + 8,
                right: 16,
                height: height,
                child: GestureDetector(
                  onTap: () => widget.onItemTap(item),
                  child: _buildItemCard(context, item),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, dynamic item) {
    final String title = item.title;
    final String subtitle = item is Task ? item.description : 'Event';
    final bool isTask = item is Task;
    final bool isCompleted = isTask ? item.isCompleted : false;
    
    final List<Color> palette = const [
      Color(0xFF7986cb), Color(0xFF33b679), Color(0xFF3f51b5), 
      Color(0xFF0b8043), Color(0xFF039be5), Color(0xFFd50000), 
      Color(0xFF4285f4), Color(0xFFe67c73), Color(0xFF8e24aa), 
      Color(0xFFf4511e), Color(0xFFb39ddb), Color(0xFFef6c00),
    ];
    
    final int hash = item.id.hashCode;
    final Color itemColor = palette[hash.abs() % palette.length];
    Color bgColor = isTask && isCompleted 
        ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)
        : itemColor.withValues(alpha: 0.2);
    Color fgColor = isTask && isCompleted
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : itemColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: fgColor, width: 4)),
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
              fontSize: 13,
              fontWeight: FontWeight.w600,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class _VerticalGridPainter extends CustomPainter {
  final int startHour;
  final int endHour;
  final double hourHeight;
  final double timeColumnWidth;
  final Color lineColor;
  final Color textColor;

  _VerticalGridPainter({
    required this.startHour,
    required this.endHour,
    required this.hourHeight,
    required this.timeColumnWidth,
    required this.lineColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5;

    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);

    for (int i = 0; i <= (endHour - startHour); i++) {
      double y = i * hourHeight;
      
      // Draw horizontal line
      canvas.drawLine(Offset(timeColumnWidth, y), Offset(size.width, y), linePaint);
      
      // Draw time text
      int hour = startHour + i;
      String timeText = hour == 0 ? '12 AM' : (hour < 12 ? '$hour AM' : (hour == 12 ? '12 PM' : '${hour - 12} PM'));
      
      textPainter.text = TextSpan(
        text: timeText,
        style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w500),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(timeColumnWidth - textPainter.width - 12, y - (textPainter.height / 2)));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _VerticalCurrentTimePainter extends CustomPainter {
  final int startHour;
  final double hourHeight;
  final double timeColumnWidth;
  final Color color;

  _VerticalCurrentTimePainter({
    required this.startHour,
    required this.hourHeight,
    required this.timeColumnWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    if (now.hour < startHour) return;

    double y = ((now.hour - startHour) + (now.minute / 60.0)) * hourHeight;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;

    // Draw horizontal line
    canvas.drawLine(Offset(timeColumnWidth, y), Offset(size.width, y), paint);
    
    // Draw dot at start
    canvas.drawCircle(Offset(timeColumnWidth, y), 4, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
