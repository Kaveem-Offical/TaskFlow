import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'widgets/weekly_strip_calendar.dart';
import 'widgets/timeline_view.dart';
import '../providers/providers.dart';
import '../models/task_model.dart';
import '../models/event_model.dart';
import 'tasks_screen.dart'; // Import to use showTaskModal

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<dynamic> _getEventsForDay(DateTime day, List<Task> tasks, List<Event> events) {
    List<dynamic> dayItems = [];
    
    // Add tasks due or starting on this day
    dayItems.addAll(tasks.where((t) {
      if (t.startTime != null) {
        return DateUtils.isSameDay(t.startTime, day);
      } else if (t.dueDate != null) {
        return DateUtils.isSameDay(t.dueDate, day);
      }
      return false;
    }));

    // Add events on this day
    dayItems.addAll(events.where((e) {
      return DateUtils.isSameDay(e.startTime, day);
    }));

    // Sort items by time if available
    dayItems.sort((a, b) {
      DateTime? timeA = a is Task ? a.startTime ?? a.dueDate : (a as Event).startTime;
      DateTime? timeB = b is Task ? b.startTime ?? b.dueDate : (b as Event).startTime;
      if (timeA == null && timeB == null) return 0;
      if (timeA == null) return 1;
      if (timeB == null) return -1;
      return timeA.compareTo(timeB);
    });

    return dayItems;
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksStreamProvider);
    final eventsAsync = ref.watch(eventsStreamProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text('Calendar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary),
            onPressed: () => _showEventModal(context, ref, null),
          ),
          IconButton(
            icon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: tasksAsync.when(
        data: (tasks) {
          return eventsAsync.when(
            data: (events) {
              final selectedDayItems = _getEventsForDay(_selectedDay ?? _focusedDay, tasks, events);

              return Column(
                children: [
                  WeeklyStripCalendar(
                    selectedDay: _selectedDay ?? _focusedDay,
                    onDaySelected: (day) {
                      setState(() {
                        _selectedDay = day;
                        _focusedDay = day;
                      });
                    },
                  ),
                  const SizedBox(height: 24.0),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: selectedDayItems.isEmpty
                          ? Center(
                              key: ValueKey('empty_${_selectedDay?.toIso8601String()}'),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.event_busy, size: 48, color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
                                  const SizedBox(height: 16),
                                  Text('No events or tasks for this day.', style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                                ],
                              ),
                            )
                          : TimelineViewWidget(
                              key: ValueKey('timeline_${_selectedDay?.toIso8601String()}'),
                              items: selectedDayItems,
                              selectedDay: _selectedDay ?? _focusedDay,
                              onItemTap: (item) {
                                if (item is Task) {
                                  showTaskModal(context, ref, item);
                                } else if (item is Event) {
                                  _showEventModal(context, ref, item);
                                }
                              },
                            ),
                    ),
                  ),
                ],
              );
            },
            loading: () => Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error loading events: $e')),
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading tasks: $e')),
      ),
    );
  }



  void _showEventModal(BuildContext context, WidgetRef ref, Event? existingEvent) {
    String title = existingEvent?.title ?? '';
    TimeOfDay startTime = existingEvent != null ? TimeOfDay.fromDateTime(existingEvent.startTime) : TimeOfDay.now();
    TimeOfDay endTime = existingEvent != null ? TimeOfDay.fromDateTime(existingEvent.endTime) : TimeOfDay.now().replacing(hour: (TimeOfDay.now().hour + 1) % 24);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20, right: 20, top: 24
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(existingEvent == null ? 'Create Event' : 'Edit Event', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                        if (existingEvent != null)
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                            onPressed: () {
                              ref.read(eventRepositoryProvider).deleteEvent(existingEvent.id);
                              Navigator.pop(context);
                            },
                          ),
                      ],
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      initialValue: title,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Event Title',
                        labelStyle: TextStyle(color: Theme.of(context).colorScheme.outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
                      ),
                      onChanged: (val) => title = val,
                    ),
                    SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              title: Text('Start: ${startTime.format(context)}', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500)),
                              trailing: Icon(Icons.access_time, size: 20, color: Theme.of(context).colorScheme.outline),
                              onTap: () async {
                                final picked = await showTimePicker(context: context, initialTime: startTime);
                                if (picked != null) {
                                  setModalState(() => startTime = picked);
                                }
                              },
                            ),
                          ),
                          Container(height: 30, width: 1, color: Theme.of(context).colorScheme.outlineVariant),
                          Expanded(
                            child: ListTile(
                              title: Text('End: ${endTime.format(context)}', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500)),
                              trailing: Icon(Icons.access_time, size: 20, color: Theme.of(context).colorScheme.outline),
                              onTap: () async {
                                final picked = await showTimePicker(context: context, initialTime: endTime);
                                if (picked != null) {
                                  setModalState(() => endTime = picked);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        if (title.isNotEmpty) {
                          final now = _selectedDay ?? DateTime.now();
                          final startDateTime = DateTime(now.year, now.month, now.day, startTime.hour, startTime.minute);
                          final endDateTime = DateTime(now.year, now.month, now.day, endTime.hour, endTime.minute);
                          
                          final event = Event(
                            id: existingEvent?.id ?? '', // Handled by repository if empty
                            title: title,
                            startTime: startDateTime,
                            endTime: endDateTime,
                          );

                          if (existingEvent == null) {
                            ref.read(eventRepositoryProvider).addEvent(event);
                          } else {
                            ref.read(eventRepositoryProvider).updateEvent(event);
                          }
                          Navigator.pop(context);
                        }
                      },
                      child: Text(existingEvent == null ? 'Add Event' : 'Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(height: 32),
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
