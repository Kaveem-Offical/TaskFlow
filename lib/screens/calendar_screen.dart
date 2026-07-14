import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'widgets/weekly_strip_calendar.dart';
import 'widgets/timeline_view.dart';
import '../providers/providers.dart';
import '../models/task_model.dart';
import '../models/event_model.dart';
import '../models/focus_session_model.dart';
import 'tasks_screen.dart'; // Import to use showTaskModal
import 'package:intl/intl.dart';
import '../widgets/premium/premium_button.dart';
import '../widgets/premium/premium_text_field.dart';
import '../widgets/premium/premium_card.dart';

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
      return DateUtils.isSameDay(e.startTime, day) ||
          DateUtils.isSameDay(e.endTime, day) ||
          (e.startTime.isBefore(day) && e.endTime.isAfter(day));
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: false,
        title: Text('Calendar', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.plusSquare, color: theme.colorScheme.primary),
            onPressed: () {
              HapticFeedback.lightImpact();
              _showEventModal(context, ref, null);
            },
          ),
          IconButton(
            icon: Icon(LucideIcons.search, color: theme.colorScheme.onSurface),
            onPressed: () {
              HapticFeedback.lightImpact();
            },
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
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedDay = day;
                        _focusedDay = day;
                      });
                    },
                  ),
                  const SizedBox(height: 16.0),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOutQuart,
                      switchOutCurve: Curves.easeIn,
                      child: selectedDayItems.isEmpty
                          ? Center(
                              key: ValueKey('empty_${_selectedDay?.toIso8601String()}'),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.calendarX, size: 48, color: theme.colorScheme.outlineVariant)
                                      .animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No events or tasks.',
                                    style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.outline),
                                  ).animate().fadeIn(delay: 100.ms),
                                ],
                              ),
                            )
                          : TimelineViewWidget(
                              key: ValueKey('timeline_${_selectedDay?.toIso8601String()}'),
                              items: selectedDayItems,
                              selectedDay: _selectedDay ?? _focusedDay,
                              onItemTap: (item) {
                                HapticFeedback.lightImpact();
                                if (item is Task) {
                                  showTaskModal(context, ref, item);
                                } else if (item is Event) {
                                  _showEventModal(context, ref, item);
                                }
                              },
                            ).animate().fadeIn(duration: 300.ms),
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
    );
  }

  void _showEventModal(BuildContext context, WidgetRef ref, Event? existingEvent) {
    String title = existingEvent?.title ?? '';
    String description = existingEvent?.description ?? '';
    DateTime eventDate = existingEvent?.startTime ?? (_selectedDay ?? DateTime.now());
    TimeOfDay startTime = existingEvent != null ? TimeOfDay.fromDateTime(existingEvent.startTime) : TimeOfDay.now();
    TimeOfDay endTime = existingEvent != null
        ? TimeOfDay.fromDateTime(existingEvent.endTime)
        : TimeOfDay.now().replacing(hour: (TimeOfDay.now().hour + 1) % 24);
    String? selectedColorHex = existingEvent?.colorHex ?? '#3f51b5';
    int? selectedReminderMinutes = existingEvent?.notificationMinutesBefore;

    final List<Map<String, dynamic>> colorBlocks = [
      {'label': 'Indigo', 'hex': '#3f51b5', 'color': const Color(0xFF3f51b5)},
      {'label': 'Emerald', 'hex': '#33b679', 'color': const Color(0xFF33b679)},
      {'label': 'Ocean', 'hex': '#039be5', 'color': const Color(0xFF039be5)},
      {'label': 'Crimson', 'hex': '#d50000', 'color': const Color(0xFFd50000)},
      {'label': 'Royal Blue', 'hex': '#4285f4', 'color': const Color(0xFF4285f4)},
      {'label': 'Coral', 'hex': '#e67c73', 'color': const Color(0xFFe67c73)},
      {'label': 'Purple', 'hex': '#8e24aa', 'color': const Color(0xFF8e24aa)},
      {'label': 'Amber', 'hex': '#f4511e', 'color': const Color(0xFFf4511e)},
      {'label': 'Lavender', 'hex': '#b39ddb', 'color': const Color(0xFFb39ddb)},
      {'label': 'Teal', 'hex': '#00897b', 'color': const Color(0xFF00897b)},
    ];

    final List<Map<String, dynamic>> reminderOptions = [
      {'label': 'None', 'minutes': null},
      {'label': 'At event time', 'minutes': 0},
      {'label': '5 min before', 'minutes': 5},
      {'label': '10 min before', 'minutes': 10},
      {'label': '15 min before', 'minutes': 15},
      {'label': '30 min before', 'minutes': 30},
      {'label': '1 hr before', 'minutes': 60},
      {'label': '1 day before', 'minutes': 1440},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final theme = Theme.of(context);
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24, right: 24, top: 24
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          existingEvent == null ? 'Create Event' : 'Edit Event',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    PremiumTextField(
                      hintText: 'Event Title',
                      controller: TextEditingController(text: title)
                        ..selection = TextSelection.fromPosition(TextPosition(offset: title.length)),
                      onChanged: (val) => title = val,
                    ),
                    const SizedBox(height: 12),
                    PremiumTextField(
                      hintText: 'Event Description (optional)',
                      controller: TextEditingController(text: description)
                        ..selection = TextSelection.fromPosition(TextPosition(offset: description.length)),
                      onChanged: (val) => description = val,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Date & Time',
                      style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    PremiumCard(
                      padding: const EdgeInsets.all(0),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(LucideIcons.calendar, color: theme.colorScheme.primary, size: 20),
                            title: Text(
                              DateFormat('E, MMM d, yyyy').format(eventDate),
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            trailing: Icon(LucideIcons.chevronRight, size: 18, color: theme.colorScheme.outline),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: eventDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                setModalState(() => eventDate = picked);
                              }
                            },
                          ),
                          Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                          Row(
                            children: [
                              Expanded(
                                child: ListTile(
                                  title: Text('Start: ${startTime.format(context)}', style: theme.textTheme.bodyMedium),
                                  trailing: Icon(LucideIcons.clock, size: 20, color: theme.colorScheme.outline),
                                  onTap: () async {
                                    final picked = await showTimePicker(context: context, initialTime: startTime);
                                    if (picked != null) {
                                      setModalState(() => startTime = picked);
                                    }
                                  },
                                ),
                              ),
                              Container(height: 30, width: 1, color: theme.colorScheme.outlineVariant),
                              Expanded(
                                child: ListTile(
                                  title: Text('End: ${endTime.format(context)}', style: theme.textTheme.bodyMedium),
                                  trailing: Icon(LucideIcons.clock, size: 20, color: theme.colorScheme.outline),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Color Block',
                      style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 48,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: colorBlocks.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, idx) {
                          final block = colorBlocks[idx];
                          final bool isSelected = selectedColorHex == block['hex'];
                          final Color color = block['color'] as Color;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setModalState(() => selectedColorHex = block['hex'] as String);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: isSelected ? 44 : 38,
                              height: isSelected ? 44 : 38,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? theme.colorScheme.onSurface : Colors.transparent,
                                  width: 2.5,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        )
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(LucideIcons.check, color: Colors.white, size: 18)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(LucideIcons.bellRing, size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Reminder Notification',
                          style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: reminderOptions.map((opt) {
                        final bool isSelected = selectedReminderMinutes == opt['minutes'];
                        return ChoiceChip(
                          label: Text(
                            opt['label'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: theme.colorScheme.primary,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          onSelected: (selected) {
                            HapticFeedback.selectionClick();
                            setModalState(() {
                              selectedReminderMinutes = opt['minutes'] as int?;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),
                    PremiumButton(
                      onPressed: () {
                        if (title.trim().isNotEmpty) {
                          final startDateTime = DateTime(
                            eventDate.year, eventDate.month, eventDate.day, startTime.hour, startTime.minute
                          );
                          DateTime endDateTime = DateTime(
                            eventDate.year, eventDate.month, eventDate.day, endTime.hour, endTime.minute
                          );
                          if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
                            endDateTime = startDateTime.add(const Duration(hours: 1));
                          }

                          final event = Event(
                            id: existingEvent?.id != null && existingEvent!.id.isNotEmpty
                                ? existingEvent.id
                                : DateTime.now().millisecondsSinceEpoch.toString(),
                            title: title.trim(),
                            description: description.trim().isEmpty ? null : description.trim(),
                            startTime: startDateTime,
                            endTime: endDateTime,
                            colorHex: selectedColorHex,
                            notificationMinutesBefore: selectedReminderMinutes,
                          );

                          if (existingEvent == null) {
                            ref.read(eventRepositoryProvider).addEvent(event);
                            setState(() {
                              _selectedDay = eventDate;
                              _focusedDay = eventDate;
                            });
                          } else {
                            ref.read(eventRepositoryProvider).updateEvent(event);
                          }
                          Navigator.pop(context);

                          if (selectedReminderMinutes != null && selectedReminderMinutes != -1) {
                            final String reminderLabel = selectedReminderMinutes == 0
                                ? 'at event time'
                                : '$selectedReminderMinutes minutes before';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(LucideIcons.bellRing, color: Colors.white, size: 18),
                                    const SizedBox(width: 8),
                                    Text('Reminder notification set ($reminderLabel)'),
                                  ],
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      label: existingEvent == null ? 'Add Event' : 'Save Changes',
                    ),
                    if (existingEvent != null) ...[
                      const SizedBox(height: 14),
                      PremiumButton(
                        isPrimary: false,
                        onPressed: () {
                          ref.read(eventRepositoryProvider).deleteEvent(existingEvent.id);
                          Navigator.pop(context);
                        },
                        label: 'Delete Event',
                        icon: LucideIcons.trash2,
                      ),
                    ],
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
