import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
      
      // Try to center the selected day
      double screenWidth = MediaQuery.of(context).size.width;
      double targetOffset = (index * _itemWidth) - (screenWidth / 2) + (_itemWidth / 2);
      targetOffset = targetOffset.clamp(0.0, (daysInMonth * _itemWidth) - screenWidth + 32.0); // 32.0 for padding
      
      if (targetOffset > 0) {
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
      // Select first day of previous month
      widget.onDaySelected(_currentMonth);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
      // Select first day of next month
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Month / Year Selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: Theme.of(context).colorScheme.outlineVariant, size: 28),
                onPressed: _previousMonth,
              ),
              const SizedBox(width: 24),
              Text(
                DateFormat('MMMM yyyy').format(_currentMonth),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                icon: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.outlineVariant, size: 28),
                onPressed: _nextMonth,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Days Strip
        SizedBox(
          height: 90,
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
                child: Container(
                  width: _itemWidth,
                  margin: const EdgeInsets.only(right: 8.0),
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('E').format(day), // Mon, Tue, etc.
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected 
                              ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8)
                              : Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected 
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurface,
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
