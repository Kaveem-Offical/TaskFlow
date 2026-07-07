import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/providers.dart';
import '../models/task_model.dart';
import '../theme/app_theme.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String _selectedTab = 'Today';
  final List<String> _tabs = ['Today', 'Next 7 Days', 'All', 'Work', 'Personal'];

  // Track expansion states
  bool _isOverdueExpanded = true;
  bool _isTodayExpanded = true;
  bool _isCompletedExpanded = false;

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksStreamProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildTabs(),
            Expanded(
              child: tasksAsync.when(
                data: (tasks) {
                  var filtered = tasks;
                  final now = DateTime.now();

                  // Filter logic based on tabs
                  if (_selectedTab == 'Work' || _selectedTab == 'Personal') {
                    filtered = tasks.where((t) => t.category == _selectedTab).toList();
                  } else if (_selectedTab == 'Today') {
                    filtered = tasks.where((t) {
                      if (t.dueDate == null) return true;
                      return t.dueDate!.year == now.year &&
                          t.dueDate!.month == now.month &&
                          t.dueDate!.day == now.day;
                    }).toList();
                  } else if (_selectedTab == 'Next 7 Days') {
                    final nextWeek = now.add(const Duration(days: 7));
                    filtered = tasks.where((t) {
                      if (t.dueDate == null) return true;
                      return t.dueDate!.isAfter(now.subtract(const Duration(days: 1))) &&
                          t.dueDate!.isBefore(nextWeek);
                    }).toList();
                  }

                  final overdue = tasks.where((t) => 
                      !t.isCompleted && 
                      t.dueDate != null && 
                      t.dueDate!.isBefore(DateTime(now.year, now.month, now.day))).toList();

                  final active = filtered.where((t) => !t.isCompleted && !overdue.contains(t)).toList();
                  final completed = filtered.where((t) => t.isCompleted).toList();

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 160), // Increased bottom padding for footer
                    children: [
                      if (overdue.isNotEmpty)
                        _buildExpandableSection(
                          title: 'Overdue',
                          count: overdue.length,
                          color: AppTheme.error,
                          isExpanded: _isOverdueExpanded,
                          onToggle: () => setState(() => _isOverdueExpanded = !_isOverdueExpanded),
                          children: overdue.map((t) => _buildTaskCard(t, isOverdue: true)).toList(),
                        ),
                      
                      if (active.isNotEmpty) const SizedBox(height: 16),
                      if (active.isNotEmpty)
                        _buildExpandableSection(
                          title: _selectedTab == 'All' ? 'Tasks' : _selectedTab,
                          count: active.length,
                          color: AppTheme.primary,
                          isExpanded: _isTodayExpanded,
                          onToggle: () => setState(() => _isTodayExpanded = !_isTodayExpanded),
                          children: active.map((t) => _buildTaskCard(t)).toList(),
                        ),

                      if (completed.isNotEmpty) const SizedBox(height: 16),
                      if (completed.isNotEmpty)
                        _buildExpandableSection(
                          title: 'Completed',
                          count: completed.length,
                          color: AppTheme.outline,
                          isExpanded: _isCompletedExpanded,
                          onToggle: () => setState(() => _isCompletedExpanded = !_isCompletedExpanded),
                          children: completed.map((t) => _buildTaskCard(t)).toList(),
                        ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isDesktop ? null : _buildMobileFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomSheet: isDesktop ? _buildDesktopQuickAdd() : null,
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required int count,
    required Color color,
    required bool isExpanded,
    required VoidCallback onToggle,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: isExpanded ? 0 : -0.25,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.expand_more, color: color, size: 20),
                ),
                const SizedBox(width: 4),
                Text(
                  '$title ($count)'.toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: Column(children: children),
          secondChild: const SizedBox(width: double.infinity, height: 0),
          crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 250),
          alignment: Alignment.topCenter,
        ),
      ],
    );
  }

  Widget _buildMobileFAB() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppTheme.primary, AppTheme.secondaryContainer],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => _showTaskModal(context, ref, null),
        backgroundColor: Colors.transparent,
        elevation: 0,
        highlightElevation: 0,
        child: const Icon(Icons.add, color: AppTheme.onPrimary, size: 28),
      ),
    );
  }

  Widget _buildDesktopQuickAdd() {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 600,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surface.withOpacity(0.95),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.3)),
              boxShadow: const [
                BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withOpacity(0.1),
                  ),
                  child: const Icon(Icons.add, color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    readOnly: true,
                    onTap: () => _showTaskModal(context, ref, null),
                    decoration: const InputDecoration(
                      hintText: 'Add a task... #Work tomorrow at 10am',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: AppTheme.outlineVariant),
                    ),
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary,
                  ),
                  child: const Icon(Icons.send, color: AppTheme.onPrimary, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.outlineVariant),
            ),
            child: const Icon(Icons.person, color: AppTheme.outline),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TODAY, ${DateFormat('MMM d').format(DateTime.now()).toUpperCase()}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: AppTheme.onSurfaceVariant, // Darker contrast
                ),
              ),
              const Text(
                'Good morning, User.',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: _tabs.map((tab) {
          final isSelected = _selectedTab == tab;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : AppTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tab,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? AppTheme.onPrimary : AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTaskCard(Task task, {bool isOverdue = false}) {
    return GestureDetector(
      onTap: () => _showTaskModal(context, ref, task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.3)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C000000), 
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isOverdue)
                  Container(width: 4, color: AppTheme.error),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            ref.read(taskRepositoryProvider).updateTask(task.copyWith(isCompleted: !task.isCompleted));
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: task.isCompleted ? AppTheme.tertiaryContainer : AppTheme.primary,
                                width: 2,
                              ),
                              color: task.isCompleted ? AppTheme.tertiaryContainer : Colors.transparent,
                            ),
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: task.isCompleted ? 1.0 : 0.0,
                              child: const Icon(Icons.check, size: 16, color: AppTheme.onTertiary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                  color: task.isCompleted ? AppTheme.outline : AppTheme.onSurface,
                                ),
                                child: Text(task.title),
                              ),
                              const SizedBox(height: 4),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    if (task.priority == 'High')
                                      _buildBadge('High Priority', AppTheme.error, AppTheme.errorContainer.withOpacity(0.5)),
                                    if (task.priority == 'Medium')
                                      _buildBadge('Medium Priority', AppTheme.secondary, AppTheme.secondaryContainer.withOpacity(0.2)),
                                    if (task.priority == 'Low')
                                      _buildBadge('Low Priority', AppTheme.tertiaryContainer, AppTheme.tertiaryContainer.withOpacity(0.1)),
                                    if (task.priority != 'None') const SizedBox(width: 4),
                                    _buildBadge(task.category, AppTheme.onSurfaceVariant, AppTheme.surfaceContainerHigh),
                                    const SizedBox(width: 4),
                                    if (task.startTime != null && task.endTime != null)
                                      Row(
                                        children: [
                                          Icon(Icons.schedule, size: 12, color: AppTheme.primary),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${DateFormat.jm().format(task.startTime!)} - ${DateFormat.jm().format(task.endTime!)}',
                                            style: GoogleFonts.jetBrainsMono(
                                              fontSize: 10,
                                              color: AppTheme.primary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      )
                                    else if (task.dueDate != null)
                                      Row(
                                        children: [
                                          Icon(Icons.event, size: 12, color: isOverdue ? AppTheme.error : AppTheme.primary),
                                          const SizedBox(width: 2),
                                          Text(
                                            DateFormat('MMM d').format(task.dueDate!),
                                            style: GoogleFonts.jetBrainsMono(
                                              fontSize: 10,
                                              color: isOverdue ? AppTheme.error : AppTheme.primary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!task.isCompleted)
                          GestureDetector(
                            onTap: () {
                              ref.read(timerProvider.notifier).selectTask(task.id);
                              ref.read(navigationProvider.notifier).setIndex(2); // Jump to Focus screen
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.surfaceContainer,
                              ),
                              child: const Icon(Icons.play_arrow, color: AppTheme.primary),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 10,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showTaskModal(BuildContext context, WidgetRef ref, Task? existingTask) {
    String title = existingTask?.title ?? '';
    String category = existingTask?.category ?? 'Work';
    String priority = existingTask?.priority ?? 'Medium';
    
    DateTime? dueDate = existingTask?.dueDate;
    TimeOfDay? startTime = existingTask?.startTime != null ? TimeOfDay.fromDateTime(existingTask!.startTime!) : null;
    TimeOfDay? endTime = existingTask?.endTime != null ? TimeOfDay.fromDateTime(existingTask!.endTime!) : null;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16, right: 16, top: 24
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(existingTask == null ? 'Create Task' : 'Edit Task', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    TextFormField(
                      initialValue: title,
                      decoration: const InputDecoration(labelText: 'Task Title'),
                      onChanged: (val) => title = val,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: category,
                            decoration: const InputDecoration(labelText: 'Category'),
                            items: ['Work', 'Personal'].map((c) {
                              return DropdownMenuItem(value: c, child: Text(c));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => category = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: priority,
                            decoration: const InputDecoration(labelText: 'Priority'),
                            items: ['Low', 'Medium', 'High'].map((p) {
                              return DropdownMenuItem(value: p, child: Text(p));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => priority = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(dueDate == null ? 'Set Due Date' : 'Due: ${DateFormat.yMMMd().format(dueDate!)}'),
                      trailing: const Icon(Icons.calendar_today, color: AppTheme.primary),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dueDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setModalState(() => dueDate = picked);
                        }
                      },
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(startTime == null ? 'Start Time' : startTime!.format(context), style: const TextStyle(fontSize: 14)),
                            trailing: const Icon(Icons.access_time, size: 20),
                            onTap: () async {
                              final picked = await showTimePicker(context: context, initialTime: startTime ?? TimeOfDay.now());
                              if (picked != null) setModalState(() => startTime = picked);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(endTime == null ? 'End Time' : endTime!.format(context), style: const TextStyle(fontSize: 14)),
                            trailing: const Icon(Icons.access_time, size: 20),
                            onTap: () async {
                              final picked = await showTimePicker(context: context, initialTime: endTime ?? TimeOfDay.now());
                              if (picked != null) setModalState(() => endTime = picked);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        if (title.isNotEmpty) {
                          DateTime? fullStartTime;
                          DateTime? fullEndTime;
                          
                          if (dueDate != null) {
                            if (startTime != null) {
                              fullStartTime = DateTime(dueDate!.year, dueDate!.month, dueDate!.day, startTime!.hour, startTime!.minute);
                            }
                            if (endTime != null) {
                              fullEndTime = DateTime(dueDate!.year, dueDate!.month, dueDate!.day, endTime!.hour, endTime!.minute);
                            }
                          }

                          final task = Task(
                            id: existingTask?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                            title: title,
                            isCompleted: existingTask?.isCompleted ?? false,
                            category: category,
                            priority: priority,
                            dueDate: dueDate ?? existingTask?.dueDate ?? DateTime.now(),
                            startTime: fullStartTime,
                            endTime: fullEndTime,
                          );

                          if (existingTask == null) {
                            ref.read(taskRepositoryProvider).addTask(task);
                          } else {
                            ref.read(taskRepositoryProvider).updateTask(task);
                          }
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.onPrimary,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: Text(existingTask == null ? 'Add Task' : 'Save Changes'),
                    ),
                    const SizedBox(height: 24),
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
