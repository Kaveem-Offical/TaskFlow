import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WeeklyStripCalendar extends StatefulWidget {
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  const WeeklyStripCalendar({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  State<WeeklyStripCalendar> createState() => _WeeklyStripCalendarState();
}

class _WeeklyStripCalendarState extends State<WeeklyStripCalendar> {
  late DateTime _currentMonth;
  late ScrollController _scrollController;
  final double _itemWidth = 60.0;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.selectedDay.year, widget.selectedDay.month, 1);
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDay();
    });
  }
  
  @override
  void didUpdateWidget(WeeklyStripCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDay.month != _currentMonth.month || widget.selectedDay.year != _currentMonth.year) {
      _currentMonth = DateTime(widget.selectedDay.year, widget.selectedDay.month, 1);
      _scrollToSelectedDay();
    } else if (oldWidget.selectedDay != widget.selectedDay) {
       _scrollToSelectedDay();
    }
  }
  
  void _scrollToSelectedDay() {
    if (_scrollController.hasClients) {
      final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
      final index = widget.selectedDay.day - 1;
      
      double screenWidth = MediaQuery.of(context).size.width;
      double targetOffset = (index * _itemWidth) - (screenWidth / 2) + (_itemWidth / 2);
      targetOffset = targetOffset.clamp(0.0, (daysInMonth * _itemWidth) - screenWidth + 32.0);
      
      if (targetOffset > 0) {
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuart,
        );
      }
    }
  }

  void _previousMonth() {
    HapticFeedback.lightImpact();
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
      widget.onDaySelected(_currentMonth);
    });
  }

  void _nextMonth() {
    HapticFeedback.lightImpact();
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
      widget.onDaySelected(_currentMonth);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Month / Year Selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(_currentMonth),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ).animate(key: ValueKey(_currentMonth)).fadeIn().slideX(begin: 0.1, end: 0, curve: Curves.easeOutQuart),
              Row(
                children: [
                  IconButton(
                    icon: Icon(LucideIcons.chevronLeft, color: theme.colorScheme.onSurfaceVariant),
                    onPressed: _previousMonth,
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.chevronRight, color: theme.colorScheme.onSurfaceVariant),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Days Strip
        SizedBox(
          height: 80,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: daysInMonth,
            itemBuilder: (context, index) {
              DateTime day = DateTime(_currentMonth.year, _currentMonth.month, index + 1);
              bool isSelected = DateUtils.isSameDay(day, widget.selectedDay);
              
              return GestureDetector(
                onTap: () => widget.onDaySelected(day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _itemWidth - 8,
                  margin: const EdgeInsets.only(right: 8.0),
                  decoration: BoxDecoration(
                    color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('E').format(day),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected 
                              ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${day.day}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isSelected 
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
