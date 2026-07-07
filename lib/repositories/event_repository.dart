import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class EventRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference _eventsRef = _firestore.collection('events');

  Stream<List<Event>> getEvents() {
    return _eventsRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
    });
  }

  Future<void> addEvent(Event event) {
    return _eventsRef.add(event.toFirestore());
  }
}
