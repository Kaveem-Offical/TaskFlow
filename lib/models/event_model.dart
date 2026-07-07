import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String? recurrenceRule;

  Event({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.recurrenceRule,
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      recurrenceRule: data['recurrenceRule'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      if (recurrenceRule != null) 'recurrenceRule': recurrenceRule,
    };
  }
}
