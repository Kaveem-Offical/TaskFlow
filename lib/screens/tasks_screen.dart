import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/providers.dart';
import '../models/task_model.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String _selectedTab = 'Today';
  
  // Track expansion states
  bool _isOverdueExpanded = true;
  bool _isTodayExpanded = true;
  bool _isCompletedExpanded = false;

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksStreamProvider);
    final categories = ref.watch(categoriesProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildTabs(categories),
            Expanded(
              child: tasksAsync.when(
                data: (tasks) {
                  var filtered = tasks;
                  final now = DateTime.now();

                  // Filter logic based on tabs
                  if (_selectedTab == 'Today') {
                    filtered = tasks.where((t) {
                      if (t.dueDate == null) return true;
                      return t.dueDate!.year == now.year &&
                          t.dueDate!.month == now.month &&
                          t.dueDate!.day == now.day;
                    }).toList();
                  } else if (_selectedTab == 'Next 7 Days') {
                    final nextWeek = now.add(Duration(days: 7));
                    filtered = tasks.where((t) {
                      if (t.dueDate == null) return true;
                      return t.dueDate!.isAfter(now.subtract(Duration(days: 1))) &&
                          t.dueDate!.isBefore(nextWeek);
                    }).toList();
                  } else if (_selectedTab != 'All') {
                    filtered = tasks.where((t) => t.category == _selectedTab).toList();
                  }
                  final overdue = tasks.where((t) {
                    if (t.isCompleted) return false;
                    if (t.dueDate == null) return false;
                    
                    final dueDay = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
                    final today = DateTime(now.year, now.month, now.day);
                    
                    if (dueDay.isBefore(today)) {
                      return true;
                    } else if (dueDay.isAtSameMomentAs(today)) {
                      final targetTime = t.endTime ?? t.startTime;
                      if (targetTime != null && targetTime.isBefore(now)) {
                        return true;
                      }
                    }
                    return false;
                  }).toList();

                  final active = filtered.where((t) => !t.isCompleted && !overdue.contains(t)).toList();
                  final completed = filtered.where((t) => t.isCompleted).toList();

                  return ListView(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 160), // Increased bottom padding for footer
                    children: [
                      if (overdue.isNotEmpty)
                        _buildExpandableSection(
                          title: 'Overdue',
                          count: overdue.length,
                          color: Theme.of(context).colorScheme.error,
                          isExpanded: _isOverdueExpanded,
                          onToggle: () => setState(() => _isOverdueExpanded = !_isOverdueExpanded),
                          children: overdue.map((t) => _buildTaskCard(t, isOverdue: true)).toList(),
                        ),
                      
                      if (active.isNotEmpty) SizedBox(height: 16),
                      if (active.isNotEmpty)
                        _buildExpandableSection(
                          title: _selectedTab == 'All' ? 'Tasks' : _selectedTab,
                          count: active.length,
                          color: Theme.of(context).colorScheme.primary,
                          isExpanded: _isTodayExpanded,
                          onToggle: () => setState(() => _isTodayExpanded = !_isTodayExpanded),
                          children: active.map((t) => _buildTaskCard(t)).toList(),
                        ),

                      if (completed.isNotEmpty) SizedBox(height: 16),
                      if (completed.isNotEmpty)
                        _buildExpandableSection(
                          title: 'Completed',
                          count: completed.length,
                          color: Theme.of(context).colorScheme.outline,
                          isExpanded: _isCompletedExpanded,
                          onToggle: () => setState(() => _isCompletedExpanded = !_isCompletedExpanded),
                          children: completed.map((t) => _buildTaskCard(t)).toList(),
                        ),
                    ],
                  );
                },
                loading: () => Center(child: CircularProgressIndicator()),
                error: (err, st) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),

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
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: isExpanded ? 0 : -0.25,
                  duration: Duration(milliseconds: 200),
                  child: Icon(Icons.expand_more, color: color, size: 20),
                ),
                SizedBox(width: 4),
                Text(
                  '$title ($count)'.toUpperCase(),
                  style: GoogleFonts.inter(
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
          secondChild: SizedBox(width: double.infinity, height: 0),
          crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: Duration(milliseconds: 250),
          alignment: Alignment.topCenter,
        ),
      ],
    );
  }

  Widget _buildMobileFAB() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondaryContainer],
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
        onPressed: () => showTaskModal(context, ref, null),
        backgroundColor: Colors.transparent,
        elevation: 0,
        highlightElevation: 0,
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary, size: 28),
      ),
    );
  }

  Widget _buildDesktopQuickAdd() {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 600,
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  margin: EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  ),
                  child: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    readOnly: true,
                    onTap: () => showTaskModal(context, ref, null),
                    decoration: InputDecoration(
                      hintText: 'Add a task... #Work tomorrow at 10am',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: Icon(Icons.send, color: Theme.of(context).colorScheme.onPrimary, size: 20),
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
      padding: EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: Icon(Icons.person, color: Theme.of(context).colorScheme.outline),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TODAY, ${DateFormat('MMM d').format(DateTime.now()).toUpperCase()}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: Theme.of(context).colorScheme.onSurfaceVariant, // Darker contrast
                ),
              ),
              Text(
                'Good morning, Kaveem.',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(List<String> categories) {
    final tabs = ['Today', 'Next 7 Days', 'All', ...categories];
    
    // Ensure selected tab is valid
    if (!tabs.contains(_selectedTab)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _selectedTab = 'Today');
      });
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _selectedTab == tab;
          return Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = tab),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tab,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurfaceVariant,
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
      onTap: () => showTaskModal(context, ref, task),
      child: Dismissible(
        key: Key(task.id),
        direction: DismissDirection.endToStart,
        background: Container(
          margin: EdgeInsets.only(bottom: 8),
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 20.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onError),
        ),
        onDismissed: (direction) {
          ref.read(taskRepositoryProvider).deleteTask(task.id);
        },
        child: Container(
          margin: EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
          boxShadow: [
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
                  Container(width: 4, color: Theme.of(context).colorScheme.error),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            ref.read(taskRepositoryProvider).updateTask(task.copyWith(isCompleted: !task.isCompleted));
                          },
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: task.isCompleted ? Theme.of(context).colorScheme.tertiaryContainer : Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                              color: task.isCompleted ? Theme.of(context).colorScheme.tertiaryContainer : Colors.transparent,
                            ),
                            child: AnimatedOpacity(
                              duration: Duration(milliseconds: 200),
                              opacity: task.isCompleted ? 1.0 : 0.0,
                              child: Icon(Icons.check, size: 16, color: Theme.of(context).colorScheme.onTertiary),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedDefaultTextStyle(
                                duration: Duration(milliseconds: 200),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                  color: task.isCompleted ? Theme.of(context).colorScheme.outline : Theme.of(context).colorScheme.onSurface,
                                ),
                                child: Text(task.title),
                              ),
                              if (task.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  task.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    if (task.priority == 'High')
                                      _buildBadge('High Priority', Theme.of(context).colorScheme.error, Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.5)),
                                    if (task.priority == 'Medium')
                                      _buildBadge('Medium Priority', Theme.of(context).colorScheme.secondary, Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.2)),
                                    if (task.priority == 'Low')
                                      _buildBadge('Low Priority', Theme.of(context).colorScheme.tertiaryContainer, Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.1)),
                                    if (task.priority != 'None') SizedBox(width: 4),
                                    _buildBadge(task.category, Theme.of(context).colorScheme.onSurfaceVariant, Theme.of(context).colorScheme.surfaceContainerHigh),
                                    SizedBox(width: 4),
                                    if (task.startTime != null && task.endTime != null)
                                      Row(
                                        children: [
                                          Icon(Icons.schedule, size: 12, color: Theme.of(context).colorScheme.primary),
                                          SizedBox(width: 2),
                                          Text(
                                            '${DateFormat.jm().format(task.startTime!)} - ${DateFormat.jm().format(task.endTime!)}',
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              color: Theme.of(context).colorScheme.primary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      )
                                    else if (task.dueDate != null)
                                      Row(
                                        children: [
                                          Icon(Icons.event, size: 12, color: isOverdue ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary),
                                          SizedBox(width: 2),
                                          Text(
                                            DateFormat('MMM d').format(task.dueDate!),
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              color: isOverdue ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
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
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.surfaceContainer,
                              ),
                              child: Icon(Icons.play_arrow, color: Theme.of(context).colorScheme.primary),
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
      ),
    );
  }

  Widget _buildBadge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

void showTaskModal(BuildContext context, WidgetRef ref, Task? existingTask) {
  String title = existingTask?.title ?? '';
  String description = existingTask?.description ?? '';
    String category = existingTask?.category ?? 'Work';
    String priority = existingTask?.priority ?? 'Medium';
    
    DateTime? dueDate = existingTask?.dueDate;
    TimeOfDay? startTime = existingTask?.startTime != null ? TimeOfDay.fromDateTime(existingTask!.startTime!) : null;
    TimeOfDay? endTime = existingTask?.endTime != null ? TimeOfDay.fromDateTime(existingTask!.endTime!) : null;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final availableCategories = ref.watch(categoriesProvider);
 
            // Ensure selected category is valid
            if (!availableCategories.contains(category) && availableCategories.isNotEmpty) {
              category = availableCategories.first;
            }
 
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
                    Text(
                      existingTask == null ? 'Create Task' : 'Edit Task',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      initialValue: title,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Task Title',
                        labelStyle: TextStyle(color: Theme.of(context).colorScheme.outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
                      ),
                      onChanged: (val) => title = val,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      initialValue: description,
                      maxLines: 3,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15),
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(color: Theme.of(context).colorScheme.outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
                      ),
                      onChanged: (val) => description = val,
                    ),
                    SizedBox(height: 24),
                    Text('Category', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                        ...availableCategories.map((c) {
                          final isSelected = category == c;
                          return GestureDetector(
                            onLongPress: () {
                              if (availableCategories.length > 1) {
                                showDialog(context: context, builder: (_) => AlertDialog(
                                  backgroundColor: Theme.of(context).colorScheme.surface,
                                  title: Text('Delete Category?', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                                  content: Text('Are you sure you want to delete "$c"?', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
                                    TextButton(onPressed: () {
                                      ref.read(categoriesProvider.notifier).removeCategory(c);
                                      Navigator.pop(context);
                                    }, child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error))),
                                  ],
                                ));
                              }
                            },
                            child: ChoiceChip(
                              label: Text(c, style: TextStyle(color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                              selected: isSelected,
                              onSelected: (val) {
                                if (val) setModalState(() => category = c);
                              },
                              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                              selectedColor: Theme.of(context).colorScheme.primary,
                              showCheckmark: false,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide.none),
                            ),
                          );
                        }),
                        ActionChip(
                          label: Text('+ Add', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide.none),
                          onPressed: () {
                            String newCategory = '';
                            showDialog(context: context, builder: (_) => AlertDialog(
                              backgroundColor: Theme.of(context).colorScheme.surface,
                              title: Text('New Category', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                              content: TextField(
                                autofocus: true,
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                decoration: InputDecoration(hintText: 'Category Name', hintStyle: TextStyle(color: Theme.of(context).colorScheme.outlineVariant)),
                                onChanged: (v) => newCategory = v,
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
                                TextButton(onPressed: () {
                                  if (newCategory.isNotEmpty) {
                                    ref.read(categoriesProvider.notifier).addCategory(newCategory);
                                  }
                                  Navigator.pop(context);
                                }, child: Text('Add')),
                              ],
                            ));
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      initialValue: priority,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500),
                      dropdownColor: Theme.of(context).colorScheme.surfaceContainer,
                      decoration: InputDecoration(
                        labelText: 'Priority',
                        labelStyle: TextStyle(color: Theme.of(context).colorScheme.outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
                      ),
                      items: ['Low', 'Medium', 'High'].map((p) {
                        return DropdownMenuItem(value: p, child: Text(p));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => priority = val);
                      },
                    ),
                    SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(dueDate == null ? 'Set Due Date' : 'Due: ${DateFormat.yMMMd().format(dueDate!)}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500)),
                            trailing: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
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
                          Divider(height: 1, indent: 16, endIndent: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ListTile(
                                  title: Text(startTime == null ? 'Start Time' : startTime!.format(context), style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                                  trailing: Icon(Icons.access_time, size: 20, color: Theme.of(context).colorScheme.outline),
                                  onTap: () async {
                                    final picked = await showTimePicker(context: context, initialTime: startTime ?? TimeOfDay.now());
                                    if (picked != null) setModalState(() => startTime = picked);
                                  },
                                ),
                              ),
                              Container(height: 30, width: 1, color: Theme.of(context).colorScheme.outlineVariant),
                              Expanded(
                                child: ListTile(
                                  title: Text(endTime == null ? 'End Time' : endTime!.format(context), style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                                  trailing: Icon(Icons.access_time, size: 20, color: Theme.of(context).colorScheme.outline),
                                  onTap: () async {
                                    final picked = await showTimePicker(context: context, initialTime: endTime ?? TimeOfDay.now());
                                    if (picked != null) setModalState(() => endTime = picked);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32),
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
                            description: description,
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
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(existingTask == null ? 'Add Task' : 'Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    if (existingTask != null) ...[
                      SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          ref.read(taskRepositoryProvider).deleteTask(existingTask.id);
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                          minimumSize: const Size.fromHeight(56),
                        ),
                        child: Text('Delete Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
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
