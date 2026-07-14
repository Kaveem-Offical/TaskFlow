import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../models/event_model.dart';
import '../services/widget_service.dart';

class _CountdownItem {
  final String id;
  final String title;
  final DateTime targetDate;
  final String label;

  _CountdownItem({
    required this.id,
    required this.title,
    required this.targetDate,
    required this.label,
  });
}

class TaskDeadlineCountdownWidget extends StatefulWidget {
  final List<Task> tasks;
  final List<Event> events;
  final VoidCallback? onTap;

  const TaskDeadlineCountdownWidget({
    super.key,
    required this.tasks,
    this.events = const [],
    this.onTap,
  });

  @override
  State<TaskDeadlineCountdownWidget> createState() => _TaskDeadlineCountdownWidgetState();
}

class _TaskDeadlineCountdownWidgetState extends State<TaskDeadlineCountdownWidget> {
  String? _pinnedId;
  bool _hideTaskName = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final pinned = await WidgetService.getPinnedCountdownId();
    final hidden = await WidgetService.getHideCountdownTaskName();
    if (mounted) {
      setState(() {
        _pinnedId = pinned;
        _hideTaskName = hidden;
      });
    }
  }

  Future<void> _toggleHideTaskName() async {
    HapticFeedback.lightImpact();
    final newVal = !_hideTaskName;
    setState(() {
      _hideTaskName = newVal;
    });
    await WidgetService.setHideCountdownTaskName(newVal);
    await WidgetService.updateWidget(widget.tasks, []);
  }

  String _getEmojiForTitle(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('birth') || lower.contains('bday')) return '🎂';
    if (lower.contains('party') || lower.contains('celebrat')) return '🎉';
    if (lower.contains('exam') || lower.contains('test') || lower.contains('study')) return '📚';
    if (lower.contains('flight') || lower.contains('trip') || lower.contains('travel') || lower.contains('vacation')) return '✈️';
    if (lower.contains('gym') || lower.contains('workout') || lower.contains('fit')) return '💪';
    if (lower.contains('meet') || lower.contains('call')) return '💼';
    if (lower.contains('launch') || lower.contains('release') || lower.contains('deploy')) return '🚀';
    if (lower.contains('doctor') || lower.contains('health')) return '🏥';
    return '🎯';
  }

  void _showPinPicker(List<_CountdownItem> items) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '1x2 Countdown Widget Settings',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Hide Task Name Toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.visibility_off_outlined, color: Color(0xFF60A5FA), size: 20),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hide Task Name on 1x2 Widget',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Show only countdown number & icon',
                                  style: TextStyle(
                                    color: Color(0xFFA1A1AA),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _hideTaskName,
                            activeColor: const Color(0xFF60A5FA),
                            onChanged: (val) async {
                              await _toggleHideTaskName();
                              setModalState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Choose which scheduled task or event appears on your widget:',
                      style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No scheduled tasks with deadlines found.',
                          style: TextStyle(color: Colors.white60),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final isSelected = item.id == _pinnedId;
                            final formattedDate = DateFormat('MMM d, yyyy').format(item.targetDate);
                            final emoji = _getEmojiForTitle(item.title);
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Text(emoji, style: const TextStyle(fontSize: 24)),
                              title: Text(
                                item.title,
                                style: TextStyle(
                                  color: isSelected ? const Color(0xFF60A5FA) : Colors.white,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                formattedDate,
                                style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle, color: Color(0xFF60A5FA))
                                  : const Icon(Icons.radio_button_unchecked, color: Colors.white24),
                              onTap: () async {
                                HapticFeedback.mediumImpact();
                                await WidgetService.pinToCountdownWidget(item.id);
                                await WidgetService.updateWidget(widget.tasks, []);
                                setState(() {
                                  _pinnedId = item.id;
                                });
                                if (ctx.mounted) Navigator.pop(ctx);
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final List<_CountdownItem> items = [];

    for (final t in widget.tasks) {
      if (!t.isCompleted && t.dueDate != null) {
        items.add(_CountdownItem(
          id: t.id,
          title: t.title,
          targetDate: t.dueDate!,
          label: t.category.isNotEmpty ? t.category.toUpperCase() : 'TASK DEADLINE',
        ));
      }
    }

    for (final e in widget.events) {
      if (!e.endTime.isBefore(today)) {
        items.add(_CountdownItem(
          id: e.id,
          title: e.title,
          targetDate: e.startTime,
          label: 'CALENDAR EVENT',
        ));
      }
    }

    _CountdownItem? selected;

    if (_pinnedId != null) {
      for (final item in items) {
        if (item.id == _pinnedId) {
          selected = item;
          break;
        }
      }
    }

    if (selected == null) {
      for (final item in items) {
        if (item.targetDate.month == 8 && item.targetDate.day == 31) {
          selected = item;
          break;
        }
      }
    }

    if (selected == null) {
      for (final item in items) {
        if (item.targetDate.month == 8) {
          selected = item;
          break;
        }
      }
    }

    if (selected == null && items.isNotEmpty) {
      items.sort((a, b) => a.targetDate.compareTo(b.targetDate));
      selected = items.first;
    }

    String badgeNum = '--';
    String badgeUnit = 'days left';
    String title = 'Scheduled Task';
    String emoji = '🎯';

    if (selected != null) {
      final dueDay = DateTime(
        selected.targetDate.year,
        selected.targetDate.month,
        selected.targetDate.day,
      );
      final daysLeft = dueDay.difference(today).inDays;

      title = selected.title;
      emoji = _getEmojiForTitle(title);

      if (daysLeft < 0) {
        badgeNum = '${-daysLeft}';
        badgeUnit = (-daysLeft == 1) ? 'day overdue' : 'days overdue';
      } else if (daysLeft == 0) {
        badgeNum = '0';
        badgeUnit = 'due today';
      } else if (daysLeft == 1) {
        badgeNum = '1';
        badgeUnit = 'day left';
      } else {
        badgeNum = '$daysLeft';
        badgeUnit = 'days left';
      }
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showPinPicker(items);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: Title (hidden when _hideTaskName is true) + Emoji & Eye toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!_hideTaskName)
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  const Spacer(),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _toggleHideTaskName,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          _hideTaskName ? Icons.visibility_off : Icons.visibility,
                          size: 16,
                          color: _hideTaskName ? const Color(0xFF60A5FA) : Colors.white38,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Bottom Row: Large Number + 'days left' beside it
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  badgeNum,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  badgeUnit,
                  style: const TextStyle(
                    color: Color(0xFFA1A1AA),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
