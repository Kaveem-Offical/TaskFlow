import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/focus_session_model.dart';

class FocusSessionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference _sessionsRef = _firestore.collection('focus_sessions');

  Stream<List<FocusSession>> getFocusSessions() {
    return _sessionsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => FocusSession.fromFirestore(doc)).toList();
    });
  }

  Future<void> addFocusSession(FocusSession session) {
    return _sessionsRef.add(session.toFirestore());
  }
}
