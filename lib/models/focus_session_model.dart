import 'package:cloud_firestore/cloud_firestore.dart';

class FocusSession {
  final String id;
  final int durationMinutes;
  final DateTime timestamp;
  final String? linkedTaskId;

  FocusSession({
    required this.id,
    required this.durationMinutes,
    required this.timestamp,
    this.linkedTaskId,
  });

  factory FocusSession.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return FocusSession(
      id: doc.id,
      durationMinutes: data['durationMinutes'] ?? 0,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      linkedTaskId: data['linkedTaskId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'durationMinutes': durationMinutes,
      'timestamp': Timestamp.fromDate(timestamp),
      if (linkedTaskId != null) 'linkedTaskId': linkedTaskId,
    };
  }
}
