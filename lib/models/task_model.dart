import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final String priority;
  final String category;
  final DateTime? dueDate;
  final DateTime? startTime;
  final DateTime? endTime;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.priority = 'Low',
    this.category = 'General',
    this.dueDate,
    this.startTime,
    this.endTime,
  });

  factory Task.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      priority: data['priority'] ?? 'Low',
      category: data['category'] ?? 'General',
      dueDate: data['dueDate'] != null ? (data['dueDate'] as Timestamp).toDate() : null,
      startTime: data['startTime'] != null ? (data['startTime'] as Timestamp).toDate() : null,
      endTime: data['endTime'] != null ? (data['endTime'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'priority': priority,
      'category': category,
      if (dueDate != null) 'dueDate': Timestamp.fromDate(dueDate!),
      if (startTime != null) 'startTime': Timestamp.fromDate(startTime!),
      if (endTime != null) 'endTime': Timestamp.fromDate(endTime!),
    };
  }
  
  Task copyWith({
    String? title,
    String? description,
    bool? isCompleted,
    String? priority,
    String? category,
    DateTime? dueDate,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}
