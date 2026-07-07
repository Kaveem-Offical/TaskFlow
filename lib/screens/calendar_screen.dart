import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../models/task_model.dart';
import '../models/event_model.dart';

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
    
    // Add tasks due on this day
    dayItems.addAll(tasks.where((t) {
      if (t.dueDate == null) return false;
      return isSameDay(t.dueDate, day);
    }));

    // Add events on this day
    dayItems.addAll(events.where((e) {
      return isSameDay(e.startTime, day);
    }));

    return dayItems;
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksStreamProvider);
    final eventsAsync = ref.watch(eventsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        title: const Text('Calendar', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF9F9FF),
        elevation: 0,
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
                        color: Color(0xFFC3C0FF),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Color(0xFF3525CD),
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: BoxDecoration(
                        color: Color(0xFF3525CD),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Expanded(
                    child: selectedDayItems.isEmpty
                        ? const Center(child: Text('No events or tasks for this day.'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16.0),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateEventModal(context, ref),
        backgroundColor: const Color(0xFF3525CD),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTaskTile(Task task) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: Icon(Icons.check_circle_outline, color: task.isCompleted ? Colors.green : Colors.grey),
        title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: const Text('Task'),
      ),
    );
  }

  Widget _buildEventTile(Event event) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: const Icon(Icons.event, color: Color(0xFF3525CD)),
        title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text('${DateFormat.jm().format(event.startTime)} - ${DateFormat.jm().format(event.endTime)}'),
      ),
    );
  }

  void _showCreateEventModal(BuildContext context, WidgetRef ref) {
    String title = '';
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay.now().replacing(hour: (TimeOfDay.now().hour + 1) % 24);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16, right: 16, top: 24
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Create Event', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Event Title'),
                    onChanged: (val) => title = val,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text('Start Time: ${startTime.format(context)}'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: startTime);
                      if (picked != null) {
                        setModalState(() {
                          startTime = picked;
                        });
                      }
                    },
                  ),
                  ListTile(
                    title: Text('End Time: ${endTime.format(context)}'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: endTime);
                      if (picked != null) {
                        setModalState(() {
                          endTime = picked;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (title.isNotEmpty) {
                        final now = _selectedDay ?? DateTime.now();
                        final startDateTime = DateTime(now.year, now.month, now.day, startTime.hour, startTime.minute);
                        final endDateTime = DateTime(now.year, now.month, now.day, endTime.hour, endTime.minute);
                        
                        ref.read(eventRepositoryProvider).addEvent(Event(
                          id: '',
                          title: title,
                          startTime: startDateTime,
                          endTime: endDateTime,
                        ));
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Add Event'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      }
    );
  }
}
