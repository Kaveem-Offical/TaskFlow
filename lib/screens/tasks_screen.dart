import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../models/task_model.dart';
import '../theme/app_theme.dart';
import 'dart:ui';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String _selectedTab = 'Today';
  final List<String> _tabs = ['Today', 'Next 7 Days', 'All', 'Work', 'Personal'];

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksStreamProvider);

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
                  // Basic filtering
                  var filtered = tasks;
                  if (_selectedTab == 'Work' || _selectedTab == 'Personal') {
                    filtered = tasks.where((t) => t.category == _selectedTab).toList();
                  }

                  final overdue = filtered.where((t) => !t.isCompleted && t.dueDate != null && t.dueDate!.isBefore(DateTime.now().subtract(const Duration(days: 1)))).toList();
                  final today = filtered.where((t) => !t.isCompleted && !overdue.contains(t)).toList();
                  final completed = filtered.where((t) => t.isCompleted).toList();

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    children: [
                      if (overdue.isNotEmpty) _buildSectionHeader('Overdue', overdue.length, AppTheme.error),
                      ...overdue.map((t) => _buildTaskCard(t, isOverdue: true)),
                      
                      if (today.isNotEmpty) const SizedBox(height: 16),
                      if (today.isNotEmpty) _buildSectionHeader('Today', today.length, AppTheme.primary),
                      ...today.map((t) => _buildTaskCard(t)),
                      
                      if (completed.isNotEmpty) const SizedBox(height: 16),
                      if (completed.isNotEmpty) _buildSectionHeader('Completed', completed.length, AppTheme.outline),
                      ...completed.map((t) => _buildTaskCard(t)),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskModal(context, ref),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: AppTheme.onPrimary),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: AppTheme.outline,
                ),
              ),
              const Text(
                'Good morning, User.',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                  fontFamily: 'Geist',
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
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : AppTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tab,
                  style: TextStyle(
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

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(Icons.expand_more, color: color, size: 20),
          const SizedBox(width: 4),
          Text(
            '$title ($count)'.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task, {bool isOverdue = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000), // 5% opacity
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
                        child: Container(
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
                          child: task.isCompleted
                              ? const Icon(Icons.check, size: 16, color: AppTheme.onTertiary)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                color: task.isCompleted ? AppTheme.outline : AppTheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (task.priority == 'High')
                                  _buildBadge('High Priority', AppTheme.error, AppTheme.errorContainer.withOpacity(0.3)),
                                if (task.priority == 'Medium')
                                  _buildBadge('Medium Priority', AppTheme.secondary, AppTheme.secondaryContainer.withOpacity(0.2)),
                                if (task.priority == 'Low')
                                  _buildBadge('Low Priority', AppTheme.tertiaryContainer, AppTheme.tertiaryContainer.withOpacity(0.1)),
                                const SizedBox(width: 4),
                                _buildBadge(task.category, AppTheme.onSurfaceVariant, AppTheme.surfaceContainerHigh),
                                const SizedBox(width: 4),
                                if (task.dueDate != null)
                                  Row(
                                    children: [
                                      Icon(Icons.schedule, size: 12, color: isOverdue ? AppTheme.error : AppTheme.primary),
                                      const SizedBox(width: 2),
                                      Text(
                                        DateFormat.jm().format(task.dueDate!),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isOverdue ? AppTheme.error : AppTheme.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  )
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (!task.isCompleted)
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.surfaceContainer,
                          ),
                          child: const Icon(Icons.play_arrow, color: AppTheme.primary),
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

  Widget _buildBadge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showAddTaskModal(BuildContext context, WidgetRef ref) {
    String title = '';
    String category = 'Work';
    String priority = 'Medium';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16, right: 16, top: 24
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Create Task', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Task Title'),
                    onChanged: (val) => title = val,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: ['Work', 'Personal'].map((c) {
                      return DropdownMenuItem(value: c, child: Text(c));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => category = val);
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: priority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: ['Low', 'Medium', 'High'].map((p) {
                      return DropdownMenuItem(value: p, child: Text(p));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => priority = val);
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (title.isNotEmpty) {
                        ref.read(taskRepositoryProvider).addTask(Task(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: title,
                          isCompleted: false,
                          category: category,
                          priority: priority,
                          dueDate: DateTime.now().add(const Duration(hours: 2)),
                        ));
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: AppTheme.onPrimary,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Add Task'),
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
