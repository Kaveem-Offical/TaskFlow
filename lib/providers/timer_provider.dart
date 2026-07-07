import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers.dart';
import '../models/focus_session_model.dart';

class TimerState {
  final int remainingSeconds;
  final bool isRunning;
  final int initialDurationMinutes;
  final String? selectedTaskId;

  TimerState({
    required this.remainingSeconds,
    required this.isRunning,
    required this.initialDurationMinutes,
    this.selectedTaskId,
  });

  TimerState copyWith({
    int? remainingSeconds,
    bool? isRunning,
    int? initialDurationMinutes,
    String? selectedTaskId,
  }) {
    return TimerState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      initialDurationMinutes: initialDurationMinutes ?? this.initialDurationMinutes,
      selectedTaskId: selectedTaskId ?? this.selectedTaskId,
    );
  }
}

class TimerNotifier extends Notifier<TimerState> {
  Timer? _timer;

  @override
  TimerState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    _loadState();
    return TimerState(remainingSeconds: 25 * 60, isRunning: false, initialDurationMinutes: 25);
  }

  void selectTask(String? taskId) {
    state = state.copyWith(selectedTaskId: taskId);
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final endTime = prefs.getInt('timer_end_time');
    final duration = prefs.getInt('timer_duration') ?? 25;
    
    if (endTime != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (endTime > now) {
        final remaining = ((endTime - now) / 1000).round();
        state = TimerState(remainingSeconds: remaining, isRunning: true, initialDurationMinutes: duration, selectedTaskId: state.selectedTaskId);
        _startTimerTick();
      } else {
        prefs.remove('timer_end_time');
        state = TimerState(remainingSeconds: duration * 60, isRunning: false, initialDurationMinutes: duration, selectedTaskId: state.selectedTaskId);
      }
    } else {
      state = state.copyWith(initialDurationMinutes: duration, remainingSeconds: duration * 60);
    }
  }

  void setDuration(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('timer_duration', minutes);
    state = TimerState(remainingSeconds: minutes * 60, isRunning: false, initialDurationMinutes: minutes, selectedTaskId: state.selectedTaskId);
    _timer?.cancel();
  }

  void start() async {
    if (state.isRunning || state.remainingSeconds <= 0) return;
    
    final prefs = await SharedPreferences.getInstance();
    final endTime = DateTime.now().millisecondsSinceEpoch + (state.remainingSeconds * 1000);
    prefs.setInt('timer_end_time', endTime);
    prefs.setInt('timer_duration', state.initialDurationMinutes);
    
    state = state.copyWith(isRunning: true);
    _startTimerTick();
  }

  void _startTimerTick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 0) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        _timer?.cancel();
        state = state.copyWith(isRunning: false);
        _onComplete();
      }
    });
  }

  void pause() async {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('timer_end_time'); 
  }

  void reset() async {
    _timer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('timer_end_time');
    state = TimerState(remainingSeconds: state.initialDurationMinutes * 60, isRunning: false, initialDurationMinutes: state.initialDurationMinutes, selectedTaskId: state.selectedTaskId);
  }

  void _onComplete() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('timer_end_time');
    
    ref.read(focusSessionRepositoryProvider).addFocusSession(FocusSession(
      id: '',
      durationMinutes: state.initialDurationMinutes,
      timestamp: DateTime.now(),
      linkedTaskId: state.selectedTaskId,
    ));
    
    reset();
  }
}

final timerProvider = NotifierProvider<TimerNotifier, TimerState>(TimerNotifier.new);
