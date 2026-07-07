import 'dart:async';
import '../models/focus_session_model.dart';

class FocusSessionRepository {
  final List<FocusSession> _sessions = [];
  final _controller = StreamController<List<FocusSession>>.broadcast();

  FocusSessionRepository() {
    Future.microtask(() => _controller.add(List.unmodifiable(_sessions)));
  }

  Stream<List<FocusSession>> getFocusSessions() {
    return _controller.stream;
  }

  Future<void> addFocusSession(FocusSession session) async {
    _sessions.add(session);
    _controller.add(List.unmodifiable(_sessions));
  }

  Future<void> deleteFocusSession(String id) async {
    _sessions.removeWhere((s) => s.id == id);
    _controller.add(List.unmodifiable(_sessions));
  }
}
