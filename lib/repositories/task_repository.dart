import 'dart:async';
import '../models/task_model.dart';

class TaskRepository {
  final List<Task> _tasks = [
    Task(id: '1', title: 'Buy flip flops', isCompleted: false, category: 'Personal', dueDate: DateTime.now().subtract(const Duration(days: 1)), priority: 'High'),
    Task(id: '2', title: 'Design review', isCompleted: false, category: 'Work', dueDate: DateTime.now(), priority: 'High'),
    Task(id: '3', title: 'Gym session', isCompleted: false, category: 'Personal', dueDate: DateTime.now(), priority: 'Low'),
    Task(id: '4', title: 'Submit report', isCompleted: true, category: 'Work', dueDate: DateTime.now().subtract(const Duration(days: 2)), priority: 'Medium'),
  ];
  final _controller = StreamController<List<Task>>.broadcast();

  TaskRepository() {
    Future.microtask(() {
      _controller.add(List.unmodifiable(_tasks));
    });
  }

  Stream<List<Task>> getTasks() {
    return _controller.stream;
  }

  Future<void> addTask(Task task) async {
    _tasks.add(task);
    _controller.add(List.unmodifiable(_tasks));
  }

  Future<void> updateTask(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      _controller.add(List.unmodifiable(_tasks));
    }
  }

  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    _controller.add(List.unmodifiable(_tasks));
  }
}
