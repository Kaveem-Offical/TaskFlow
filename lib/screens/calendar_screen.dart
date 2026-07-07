import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
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
        return isSameDay(t.startTime, day);
      } else if (t.dueDate != null) {
        return isSameDay(t.dueDate, day);
      }
      return false;
    }));

    // Add events on this day
    dayItems.addAll(events.where((e) {
      return isSameDay(e.startTime, day);
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
        title: Text('Calendar', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: tasksAsync.when(
        data: (tasks) {
          return eventsAsync.when(
            data: (events) {
              final selectedDayItems = _getEventsForDay(_selectedDay ?? _focusedDay, tasks, events);

              return Column(
                children: [
                  TableCalendar(
                    firstDay: DateTime.utc(2020, 10, 16),
                    lastDay: DateTime.utc(2030, 3, 14),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      if (!isSameDay(_selectedDay, selectedDay)) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      }
                    },
                    eventLoader: (day) {
                      return _getEventsForDay(day, tasks, events);
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: selectedDayItems.isEmpty
                          ? Center(
                              key: ValueKey('empty_${_selectedDay?.toIso8601String()}'),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.event_busy, size: 48, color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
                                  SizedBox(height: 16),
                                  Text('No events or tasks for this day.', style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              key: ValueKey('list_${_selectedDay?.toIso8601String()}'),
                              padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 160.0),
                              itemCount: selectedDayItems.length,
                              itemBuilder: (context, index) {
                                final item = selectedDayItems[index];
                                if (item is Task) {
                                  return _buildTaskTile(item);
                                } else if (item is Event) {
                                  return _buildEventTile(item);
                                }
                                return SizedBox();
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
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 80.0),
        child: FloatingActionButton(
          onPressed: () => _showEventModal(context, ref, null),
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
        ),
      ),
    );
  }

  Widget _buildTaskTile(Task task) {
    String subtitle = 'Task';
    if (task.startTime != null && task.endTime != null) {
      subtitle = '${DateFormat.jm().format(task.startTime!)} - ${DateFormat.jm().format(task.endTime!)}';
    } else if (task.dueDate != null) {
      subtitle = 'Due ${DateFormat('MMM d').format(task.dueDate!)}';
    }

    return GestureDetector(
      onTap: () => showTaskModal(context, ref, task),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.0),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: task.isCompleted ? Theme.of(context).colorScheme.outline : Theme.of(context).colorScheme.tertiaryContainer), // Color-coded task border
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle_outline, size: 20, color: task.isCompleted ? Theme.of(context).colorScheme.tertiaryContainer : Theme.of(context).colorScheme.outlineVariant),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                color: task.isCompleted ? Theme.of(context).colorScheme.outline : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(4)),
                            child: Text('TASK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          SizedBox(width: 28),
                          Icon(Icons.schedule, size: 14, color: Theme.of(context).colorScheme.outline),
                          SizedBox(width: 4),
                          Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventTile(Event event) {
    return GestureDetector(
      onTap: () => _showEventModal(context, ref, event),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.0),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: Theme.of(context).colorScheme.primary), // Color-coded event border
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.event, size: 20, color: Theme.of(context).colorScheme.primary),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              event.title,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          SizedBox(width: 28),
                          Icon(Icons.schedule, size: 14, color: Theme.of(context).colorScheme.primary),
                          SizedBox(width: 4),
                          Text(
                            '${DateFormat.jm().format(event.startTime)} - ${DateFormat.jm().format(event.endTime)}',
                            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
