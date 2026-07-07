import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/timer_provider.dart';

class FocusScreen extends ConsumerWidget {
  const FocusScreen({super.key});

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerProvider);
    final timerNotifier = ref.read(timerProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        title: const Text('Focus', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF9F9FF),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatTime(timerState.remainingSeconds),
              style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w800, fontFamily: 'Geist'),
            ),
            const SizedBox(height: 16),
            Text(
              timerState.isRunning ? 'Focusing...' : 'Ready to focus?',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!timerState.isRunning)
                  ElevatedButton(
                    onPressed: timerNotifier.start,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3525CD),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: const Text('Start', style: TextStyle(fontSize: 18, color: Colors.white)),
                  )
                else
                  ElevatedButton(
                    onPressed: timerNotifier.pause,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: const Text('Pause', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: timerNotifier.reset,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Reset', style: TextStyle(fontSize: 18, color: Colors.black87)),
                ),
              ],
            ),
            const SizedBox(height: 48),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [15, 25, 50].map((minutes) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text('$minutes min'),
                      selected: timerState.initialDurationMinutes == minutes,
                      onSelected: timerState.isRunning ? null : (val) {
                        if (val) timerNotifier.setDuration(minutes);
                      },
                      selectedColor: const Color(0xFFC3C0FF),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
