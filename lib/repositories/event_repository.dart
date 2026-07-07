import 'dart:async';
import '../models/event_model.dart';

class EventRepository {
  final List<Event> _events = [];
  final _controller = StreamController<List<Event>>.broadcast();

  EventRepository() {
    Future.microtask(() => _controller.add(List.unmodifiable(_events)));
  }

  Stream<List<Event>> getEvents() {
    return _controller.stream;
  }

  Future<void> addEvent(Event event) async {
    _events.add(event);
    _controller.add(List.unmodifiable(_events));
  }

  Future<void> updateEvent(Event event) async {
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _events[index] = event;
      _controller.add(List.unmodifiable(_events));
    }
  }

  Future<void> deleteEvent(String id) async {
    _events.removeWhere((e) => e.id == id);
    _controller.add(List.unmodifiable(_events));
  }
}
