import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/providers.dart';
import '../models/task_model.dart';
import '../widgets/premium/premium_card.dart';
import '../widgets/premium/premium_button.dart';
import '../widgets/premium/premium_text_field.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  int _selectedTabIndex = 0;
  late PageController _pageController;
  
  bool _isOverdueExpanded = true;
  bool _isTodayExpanded = true;
  bool _isCompletedExpanded = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedTabIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksStreamProvider);
    final categories = ref.watch(categoriesProvider);
    final tabs = ['Today', 'Next 7 Days', 'All', ...categories];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildTabs(tabs),
            Expanded(
              child: tasksAsync.when(
                data: (tasks) {
                  return PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _selectedTabIndex = index);
                      HapticFeedback.selectionClick();
                    },
                    itemCount: tabs.length,
                    itemBuilder: (context, index) {
                      final tabName = tabs[index];
                      return _buildTaskListForTab(tabName, tasks);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskListForTab(String tabName, List<Task> tasks) {
    var filtered = tasks;
    final now = DateTime.now();

    if (tabName == 'Today') {
      filtered = tasks.where((t) {
        if (t.dueDate == null) return true;
        return t.dueDate!.year == now.year &&
            t.dueDate!.month == now.month &&
            t.dueDate!.day == now.day;
      }).toList();
    } else if (tabName == 'Next 7 Days') {
      final nextWeek = now.add(const Duration(days: 7));
      filtered = tasks.where((t) {
        if (t.dueDate == null) return true;
        return t.dueDate!.isAfter(now.subtract(const Duration(days: 1))) &&
            t.dueDate!.isBefore(nextWeek);
      }).toList();
    } else if (tabName != 'All') {
      filtered = tasks.where((t) => t.category == tabName).toList();
    }

    final overdue = tasks.where((t) {
      if (t.isCompleted) return false;
      if (t.dueDate == null) return false;
      
      final dueDay = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      final today = DateTime(now.year, now.month, now.day);
      
      if (dueDay.isBefore(today)) return true;
      if (dueDay.isAtSameMomentAs(today)) {
        final targetTime = t.endTime ?? t.startTime;
        if (targetTime != null && targetTime.isBefore(now)) return true;
      }
      return false;
    }).toList();

    final active = filtered.where((t) => !t.isCompleted && !overdue.contains(t)).toList();
    final completed = filtered.where((t) => t.isCompleted).toList();

    if (filtered.isEmpty && overdue.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 160),
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
        
        if (active.isNotEmpty) const SizedBox(height: 16),
        if (active.isNotEmpty)
          _buildExpandableSection(
            title: tabName == 'All' ? 'Tasks' : tabName,
            count: active.length,
            color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            isExpanded: _isTodayExpanded,
            onToggle: () => setState(() => _isTodayExpanded = !_isTodayExpanded),
            children: active.map((t) => _buildTaskCard(t)).toList(),
          ),

        if (completed.isNotEmpty) const SizedBox(height: 16),
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
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.checkSquare, size: 64, color: Theme.of(context).colorScheme.outlineVariant)
              .animate()
              .scale(duration: 500.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 16),
          Text(
            "You're all caught up!",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 8),
          Text(
            "Take a break or add a new task.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 32),
          PremiumButton(
            width: 200,
            label: "Add Task",
            icon: LucideIcons.plus,
            onPressed: () => showTaskModal(context, ref, null),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuart),
        ],
      ),
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
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            onToggle();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: isExpanded ? 0 : -0.25,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(LucideIcons.chevronDown, color: color, size: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    count.toString(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: Column(
            children: List.generate(children.length, (index) {
              return children[index]
                  .animate()
                  .fadeIn(delay: (50 * index).ms, duration: 300.ms)
                  .slideY(begin: 0.1, end: 0, delay: (50 * index).ms, duration: 300.ms, curve: Curves.easeOutQuart);
            }),
          ),
          secondChild: const SizedBox(width: double.infinity, height: 0),
          crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 250),
          alignment: Alignment.topCenter,
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.user, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getGreeting()}, Kaveem.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('EEEE, MMMM d').format(DateTime.now()),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddCategoryModal() {
    String newCategory = '';
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('New Category', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          content: PremiumTextField(
            hintText: 'Category Name',
            onChanged: (val) => newCategory = val,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
            ElevatedButton(
              onPressed: () {
                if (newCategory.trim().isNotEmpty) {
                  ref.read(categoriesProvider.notifier).addCategory(newCategory.trim());
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Add'),
            ),
          ],
        );
      }
    );
  }

  Widget _buildTabs(List<String> tabs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          ...tabs.asMap().entries.map((entry) {
            final index = entry.key;
            final tab = entry.value;
            final isSelected = _selectedTabIndex == index;
            final theme = Theme.of(context);
            
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: () {
                  if (!isSelected) {
                    HapticFeedback.selectionClick();
                    _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeOutQuart);
                  }
                },
                onLongPress: () {
                  if (tab != 'Today' && tab != 'Next 7 Days' && tab != 'All') {
                    HapticFeedback.mediumImpact();
                    _showDeleteCategoryDialog(tab);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface,
                    border: Border.all(
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tab,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: ActionChip(
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide.none,
              label: Row(
                children: [
                  Icon(LucideIcons.plus, size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 4),
                  Text('New', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                ],
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                _showAddCategoryModal();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryDialog(String category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('Delete Category?', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete "$category"? Tasks in this category will not be deleted but may be orphaned.', style: Theme.of(context).textTheme.bodyMedium),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              ref.read(categoriesProvider.notifier).removeCategory(category);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _handleTaskCompletion(Task task) {
    HapticFeedback.lightImpact();
    bool completing = !task.isCompleted;

    if (completing && task.repeatMode != null && task.repeatMode != 'None') {
      DateTime nextDueDate = task.dueDate ?? DateTime.now();
      
      switch (task.repeatMode) {
        case 'Daily':
          nextDueDate = nextDueDate.add(const Duration(days: 1));
          break;
        case 'Weekly':
          nextDueDate = nextDueDate.add(const Duration(days: 7));
          break;
        case 'Monthly':
          nextDueDate = DateTime(nextDueDate.year, nextDueDate.month + 1, nextDueDate.day);
          break;
      }

      bool shouldCreate = true;
      if (task.repeatEndDate != null && nextDueDate.isAfter(task.repeatEndDate!)) {
        shouldCreate = false; // Past end date
      }

      if (shouldCreate) {
        DateTime? nextStartTime;
        DateTime? nextEndTime;
        if (task.startTime != null && task.dueDate != null) {
          nextStartTime = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day, task.startTime!.hour, task.startTime!.minute);
        }
        if (task.endTime != null && task.dueDate != null) {
          nextEndTime = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day, task.endTime!.hour, task.endTime!.minute);
        }

        final nextTask = Task(
          id: DateTime.now().millisecondsSinceEpoch.toString(), // new ID
          title: task.title,
          description: task.description,
          category: task.category,
          priority: task.priority,
          repeatMode: task.repeatMode,
          repeatEndDate: task.repeatEndDate,
          parentTaskId: task.parentTaskId ?? task.id,
          dueDate: nextDueDate,
          startTime: nextStartTime,
          endTime: nextEndTime,
          isCompleted: false,
        );
        ref.read(taskRepositoryProvider).addTask(nextTask);
      }
    }

    ref.read(taskRepositoryProvider).updateTask(task.copyWith(isCompleted: completing));
  }

  Widget _buildTaskCard(Task task, {bool isOverdue = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(task.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.error,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(LucideIcons.trash2, color: theme.colorScheme.onError),
        ),
        onDismissed: (direction) {
          ref.read(taskRepositoryProvider).deleteTask(task.id);
          HapticFeedback.mediumImpact();
        },
        child: PremiumCard(
          onTap: () => showTaskModal(context, ref, task),
          backgroundColor: isOverdue ? theme.colorScheme.error.withValues(alpha: 0.05) : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _handleTaskCompletion(task),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: task.isCompleted ? theme.colorScheme.primary : theme.colorScheme.outline,
                      width: 2,
                    ),
                    color: task.isCompleted ? theme.colorScheme.primary : Colors.transparent,
                  ),
                  child: task.isCompleted
                      ? Icon(LucideIcons.check, size: 16, color: theme.colorScheme.onPrimary)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        color: task.isCompleted ? theme.colorScheme.outline : theme.colorScheme.onSurface,
                      ),
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (isOverdue && !task.isCompleted)
                          _buildBadge('Overdue', theme.colorScheme.error, theme.colorScheme.error.withValues(alpha: 0.1)),
                        if (task.priority == 'High')
                          _buildBadge('High Priority', theme.colorScheme.error, theme.colorScheme.error.withValues(alpha: 0.1)),
                        _buildBadge(task.category, theme.colorScheme.onSurfaceVariant, theme.colorScheme.surfaceContainerHighest),
                        if (task.repeatMode != null && task.repeatMode != 'None')
                          _buildBadge('Repeats ${task.repeatMode}', theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.1)),
                        if (task.startTime != null && task.endTime != null)
                          _buildTimeBadge(
                            '${DateFormat.jm().format(task.startTime!)} - ${DateFormat.jm().format(task.endTime!)}',
                            LucideIcons.clock,
                            theme,
                          )
                        else if (task.dueDate != null)
                          _buildTimeBadge(
                            DateFormat('MMM d').format(task.dueDate!),
                            LucideIcons.calendar,
                            theme,
                            isOverdue: isOverdue && !task.isCompleted,
                          )
                      ],
                    ),
                  ],
                ),
              ),
              if (!task.isCompleted)
                IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.read(timerProvider.notifier).selectTask(task.id);
                    ref.read(navigationProvider.notifier).setIndex(2); // Jump to Focus screen
                  },
                  icon: Icon(LucideIcons.playCircle, color: theme.colorScheme.primary),
                  tooltip: 'Start Focus',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTimeBadge(String text, IconData icon, ThemeData theme, {bool isOverdue = false}) {
    final color = isOverdue ? theme.colorScheme.error : theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

void showTaskModal(BuildContext context, WidgetRef ref, Task? existingTask) {
  String title = existingTask?.title ?? '';
  String description = existingTask?.description ?? '';
  String category = existingTask?.category ?? 'Work';
  String priority = existingTask?.priority ?? 'Medium';
  String repeatMode = existingTask?.repeatMode ?? 'None';
  DateTime? repeatEndDate = existingTask?.repeatEndDate;
  
  DateTime? dueDate = existingTask?.dueDate;
  TimeOfDay? startTime = existingTask?.startTime != null ? TimeOfDay.fromDateTime(existingTask!.startTime!) : null;
  TimeOfDay? endTime = existingTask?.endTime != null ? TimeOfDay.fromDateTime(existingTask!.endTime!) : null;
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final availableCategories = ref.watch(categoriesProvider);

          if (!availableCategories.contains(category) && availableCategories.isNotEmpty) {
            category = availableCategories.first;
          }
          final theme = Theme.of(context);

          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        existingTask == null ? 'New Task' : 'Edit Task',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(LucideIcons.x, size: 20, color: theme.colorScheme.onSurface),
                        ),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PremiumTextField(
                          hintText: 'Task Title',
                          controller: TextEditingController(text: title)..selection = TextSelection.fromPosition(TextPosition(offset: title.length)),
                          onChanged: (val) => title = val,
                          autofocus: existingTask == null,
                        ),
                        const SizedBox(height: 12),
                        PremiumTextField(
                          hintText: 'Description (optional)',
                          controller: TextEditingController(text: description)..selection = TextSelection.fromPosition(TextPosition(offset: description.length)),
                          onChanged: (val) => description = val,
                        ),
                        const SizedBox(height: 24),
                        Text('Category', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: availableCategories.map((c) {
                              final isSelected = category == c;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(c, style: TextStyle(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500)),
                                  selected: isSelected,
                                  onSelected: (val) {
                                    if (val) setModalState(() => category = c);
                                  },
                                  showCheckmark: false,
                                  selectedColor: theme.colorScheme.primary,
                                  labelStyle: TextStyle(color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text('Priority', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Row(
                          children: ['Low', 'Medium', 'High'].map((p) {
                            final isSelected = priority == p;
                            Color chipColor;
                            if (p == 'Low') chipColor = Colors.green;
                            else if (p == 'Medium') chipColor = Colors.orange;
                            else chipColor = Colors.red;

                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(right: p != 'High' ? 8.0 : 0),
                                child: ChoiceChip(
                                  label: Center(child: Text(p, style: TextStyle(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500))),
                                  selected: isSelected,
                                  onSelected: (val) {
                                    if (val) setModalState(() => priority = p);
                                  },
                                  showCheckmark: false,
                                  selectedColor: chipColor.withValues(alpha: 0.2),
                                  backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                  labelStyle: TextStyle(color: isSelected ? chipColor : theme.colorScheme.onSurfaceVariant),
                                  side: BorderSide(color: isSelected ? chipColor.withValues(alpha: 0.5) : Colors.transparent),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        PremiumCard(
                          padding: const EdgeInsets.all(0),
                          child: Column(
                            children: [
                              ListTile(
                                title: Text(dueDate == null ? 'Set Due Date' : 'Due: ${DateFormat.yMMMd().format(dueDate!)}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                                trailing: Icon(LucideIcons.calendar, color: theme.colorScheme.primary),
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
                              Divider(height: 1, color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                              Row(
                                children: [
                                  Expanded(
                                    child: ListTile(
                                      title: Text(startTime == null ? 'Start' : startTime!.format(context), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                                      trailing: Icon(LucideIcons.clock, size: 20, color: theme.colorScheme.outline),
                                      onTap: () async {
                                        final picked = await showTimePicker(context: context, initialTime: startTime ?? TimeOfDay.now());
                                        if (picked != null) setModalState(() => startTime = picked);
                                      },
                                    ),
                                  ),
                                  Container(height: 30, width: 1, color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                                  Expanded(
                                    child: ListTile(
                                      title: Text(endTime == null ? 'End' : endTime!.format(context), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                                      trailing: Icon(LucideIcons.clock, size: 20, color: theme.colorScheme.outline),
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
                        const SizedBox(height: 16),
                        PremiumCard(
                          padding: const EdgeInsets.all(0),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Repeat', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                                    DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: repeatMode,
                                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                                        icon: Icon(LucideIcons.chevronDown, size: 16, color: theme.colorScheme.primary),
                                        items: const [
                                          DropdownMenuItem(value: 'None', child: Text('None')),
                                          DropdownMenuItem(value: 'Daily', child: Text('Daily')),
                                          DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                                          DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) {
                                            setModalState(() {
                                              repeatMode = val;
                                              if (val == 'None') repeatEndDate = null;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (repeatMode != 'None') ...[
                                Divider(height: 1, color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                                ListTile(
                                  title: Text(repeatEndDate == null ? 'Repeat Forever' : 'Until: ${DateFormat.yMMMd().format(repeatEndDate!)}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                                  trailing: Icon(LucideIcons.calendarOff, color: theme.colorScheme.outline),
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: repeatEndDate ?? (dueDate ?? DateTime.now()).add(const Duration(days: 30)),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime(2030),
                                    );
                                    if (picked != null) {
                                      setModalState(() => repeatEndDate = picked);
                                    }
                                  },
                                  onLongPress: () {
                                    setModalState(() => repeatEndDate = null);
                                  },
                                ),
                              ]
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        PremiumButton(
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
                                repeatMode: repeatMode,
                                repeatEndDate: repeatEndDate,
                                parentTaskId: existingTask?.parentTaskId,
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
                    label: existingTask == null ? 'Create Task' : 'Save Changes',
                  ),
                  if (existingTask != null) ...[
                    const SizedBox(height: 16),
                    PremiumButton(
                      isPrimary: false,
                      onPressed: () {
                        ref.read(taskRepositoryProvider).deleteTask(existingTask.id);
                        Navigator.pop(context);
                      },
                      label: 'Delete Task',
                      icon: LucideIcons.trash2,
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  },
      );
    },
  );
}
