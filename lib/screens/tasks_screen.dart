import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../models/task_model.dart';
import 'package:intl/intl.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final tasksAsyncValue = ref.watch(tasksStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        title: const Text('Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF9F9FF),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text('Good morning, User.', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: ['Today', 'Next 7 Days', 'All', 'Work', 'Personal'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    selectedColor: const Color(0xFF3525CD),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: tasksAsyncValue.when(
              data: (tasks) {
                List<Task> filteredTasks = tasks.where((t) {
                  if (_selectedFilter == 'Work') return t.category == 'Work';
                  if (_selectedFilter == 'Personal') return t.category == 'Personal';
                  if (_selectedFilter == 'Today') {
                    if (t.dueDate == null) return false;
                    final now = DateTime.now();
                    return t.dueDate!.year == now.year && t.dueDate!.month == now.month && t.dueDate!.day == now.day;
                  }
                  return true;
                }).toList();

                if (filteredTasks.isEmpty) {
                  return const Center(child: Text('No tasks found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    return TaskCard(task: filteredTasks[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskModal(context, ref),
        backgroundColor: const Color(0xFF3525CD),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddTaskModal(BuildContext context, WidgetRef ref) {
    String title = '';
    String category = 'Work';
    String priority = 'Low';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, 
            left: 16, right: 16, top: 24
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Task Title'),
                onChanged: (val) => title = val,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: category,
                items: ['Work', 'Personal', 'General'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => category = val!,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: priority,
                items: ['Low', 'Med', 'High'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (val) => priority = val!,
                decoration: const InputDecoration(labelText: 'Priority'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (title.isNotEmpty) {
                    ref.read(taskRepositoryProvider).addTask(Task(
                      id: '',
                      title: title,
                      category: category,
                      priority: priority,
                      dueDate: DateTime.now(),
                    ));
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add Task'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }
    );
  }
}

class TaskCard extends ConsumerWidget {
  final Task task;
  
  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
        border: task.priority == 'High' ? const Border(left: BorderSide(color: Colors.red, width: 4)) : null,
      ),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (val) {
            ref.read(taskRepositoryProvider).updateTask(task.copyWith(isCompleted: val));
          },
          activeColor: const Color(0xFF3525CD),
        ),
        title: Text(
          task.title, 
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : Colors.black87,
          )
        ),
        subtitle: Wrap(
          spacing: 8.0,
          children: [
            if (task.priority == 'High')
              Chip(label: Text(task.priority, style: const TextStyle(fontSize: 10, color: Colors.red)), backgroundColor: Colors.red.shade100, padding: EdgeInsets.zero),
            Chip(label: Text(task.category, style: const TextStyle(fontSize: 10)), padding: EdgeInsets.zero),
            if (task.dueDate != null)
              Chip(label: Text(DateFormat('MMM d').format(task.dueDate!), style: const TextStyle(fontSize: 10)), padding: EdgeInsets.zero),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.grey),
          onPressed: () {
            ref.read(taskRepositoryProvider).deleteTask(task.id);
          },
        ),
      ),
    );
  }
}
