import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class EventRepository {
  final CollectionReference _eventsCollection = FirebaseFirestore.instance.collection('events');

  EventRepository();

  Stream<List<Event>> getEvents() {
    return _eventsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
    });
  }

  Future<void> addEvent(Event event) async {
    await _eventsCollection.doc(event.id).set(event.toFirestore());
  }

  Future<void> updateEvent(Event event) async {
    await _eventsCollection.doc(event.id).update(event.toFirestore());
  }

  Future<void> deleteEvent(String id) async {
    await _eventsCollection.doc(id).delete();
  }
}
