import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../models/task_model.dart';
import '../models/event_model.dart';
import '../theme/app_theme.dart';
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Calendar', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    calendarStyle: const CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: AppTheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8.0),
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
                                  Icon(Icons.event_busy, size: 48, color: AppTheme.outlineVariant.withValues(alpha: 0.5)),
                                  const SizedBox(height: 16),
                                  const Text('No events or tasks for this day.', style: TextStyle(color: AppTheme.outline)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              key: ValueKey('list_${_selectedDay?.toIso8601String()}'),
                              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 160.0),
                              itemCount: selectedDayItems.length,
                              itemBuilder: (context, index) {
                                final item = selectedDayItems[index];
                                if (item is Task) {
                                  return _buildTaskTile(item);
                                } else if (item is Event) {
                                  return _buildEventTile(item);
                                }
                                return const SizedBox();
                              },
                            ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error loading events: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading tasks: $e')),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: FloatingActionButton(
          onPressed: () => _showEventModal(context, ref, null),
          backgroundColor: AppTheme.primary,
          child: const Icon(Icons.add, color: AppTheme.onPrimary),
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
        margin: const EdgeInsets.only(bottom: 8.0),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: task.isCompleted ? AppTheme.outline : AppTheme.tertiaryContainer), // Color-coded task border
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle_outline, size: 20, color: task.isCompleted ? AppTheme.tertiaryContainer : AppTheme.outlineVariant),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                color: task.isCompleted ? AppTheme.outline : AppTheme.onSurface,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppTheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(4)),
                            child: const Text('TASK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const SizedBox(width: 28),
                          Icon(Icons.schedule, size: 14, color: AppTheme.outline),
                          const SizedBox(width: 4),
                          Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.outline, fontWeight: FontWeight.w500)),
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
        margin: const EdgeInsets.only(bottom: 8.0),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: AppTheme.primary), // Color-coded event border
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.event, size: 20, color: AppTheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              event.title,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.onSurface),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const SizedBox(width: 28),
                          const Icon(Icons.schedule, size: 14, color: AppTheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${DateFormat.jm().format(event.startTime)} - ${DateFormat.jm().format(event.endTime)}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600),
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
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                        Text(existingEvent == null ? 'Create Event' : 'Edit Event', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
                        if (existingEvent != null)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                            onPressed: () {
                              ref.read(eventRepositoryProvider).deleteEvent(existingEvent.id);
                              Navigator.pop(context);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: title,
                      style: const TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w500, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Event Title',
                        labelStyle: const TextStyle(color: AppTheme.outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
                      ),
                      onChanged: (val) => title = val,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              title: Text('Start: ${startTime.format(context)}', style: const TextStyle(fontSize: 14, color: AppTheme.onSurface, fontWeight: FontWeight.w500)),
                              trailing: const Icon(Icons.access_time, size: 20, color: AppTheme.outline),
                              onTap: () async {
                                final picked = await showTimePicker(context: context, initialTime: startTime);
                                if (picked != null) {
                                  setModalState(() => startTime = picked);
                                }
                              },
                            ),
                          ),
                          Container(height: 30, width: 1, color: AppTheme.outlineVariant),
                          Expanded(
                            child: ListTile(
                              title: Text('End: ${endTime.format(context)}', style: const TextStyle(fontSize: 14, color: AppTheme.onSurface, fontWeight: FontWeight.w500)),
                              trailing: const Icon(Icons.access_time, size: 20, color: AppTheme.outline),
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
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.onPrimary,
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
                      child: Text(existingEvent == null ? 'Add Event' : 'Save Changes', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
