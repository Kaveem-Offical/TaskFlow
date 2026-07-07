import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class TaskRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference _tasksRef = _firestore.collection('tasks');

  Stream<List<Task>> getTasks() {
    return _tasksRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    });
  }

  Future<void> addTask(Task task) {
    return _tasksRef.add(task.toFirestore());
  }

  Future<void> updateTask(Task task) {
    return _tasksRef.doc(task.id).update(task.toFirestore());
  }

  Future<void> deleteTask(String id) {
    return _tasksRef.doc(id).delete();
  }
}
