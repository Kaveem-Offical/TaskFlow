import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import 'package:google_fonts/google_fonts.dart';

class FocusScreen extends ConsumerWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerProvider);
    final tasksAsync = ref.watch(tasksStreamProvider);

    final minutes = (timerState.remainingSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (timerState.remainingSeconds % 60).toString().padLeft(2, '0');
    final progress = 1 - (timerState.remainingSeconds / (timerState.initialDurationMinutes * 60));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Focus', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 160),
        child: Column(
          children: [
            // Task Selector
            tasksAsync.when(
              data: (tasks) {
                final activeTasks = tasks.where((t) => !t.isCompleted).toList();
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: Text('Select a task to focus on...'),
                      value: timerState.selectedTaskId,
                      icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.primary),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('No specific task'),
                        ),
                        ...activeTasks.map((t) => DropdownMenuItem<String>(
                          value: t.id,
                          child: Text(t.title, overflow: TextOverflow.ellipsis),
                        )),
                      ],
                      onChanged: (taskId) {
                        ref.read(timerProvider.notifier).selectTask(taskId);
                      },
                    ),
                  ),
                );
              },
              loading: () => LinearProgressIndicator(),
              error: (e, st) => Text('Error loading tasks: $e'),
            ),
            SizedBox(height: 48),
            
            // Timer Circle
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 250,
                  height: 250,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (timerState.isRunning)
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline, color: Theme.of(context).colorScheme.outline),
                            onPressed: () => ref.read(timerProvider.notifier).subtractTime(5),
                          ),
                        Text(
                          '$minutes:$seconds',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (timerState.isRunning)
                          IconButton(
                            icon: Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.outline),
                            onPressed: () => ref.read(timerProvider.notifier).addTime(5),
                          ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      timerState.isRunning ? 'Focusing...' : 'Ready to focus',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant, // Darkened for contrast
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 48),
            
            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!timerState.isRunning)
                  ElevatedButton(
                    onPressed: () {
                      ref.read(timerProvider.notifier).start();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text('Start', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      ref.read(timerProvider.notifier).pause();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                      foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                      padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text('Pause', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                SizedBox(width: 16),
                if (timerState.isRunning)
                  ElevatedButton(
                    onPressed: () {
                      ref.read(timerProvider.notifier).endEarly();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                      foregroundColor: Theme.of(context).colorScheme.error,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text('End', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  )
                else
                  IconButton(
                    onPressed: () {
                      ref.read(timerProvider.notifier).reset();
                    },
                    icon: Icon(Icons.refresh),
                    iconSize: 32,
                    color: Theme.of(context).colorScheme.outline,
                  ),
              ],
            ),
            SizedBox(height: 48),
            
            // Duration Presets
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDurationPreset(context, ref, 15, timerState.initialDurationMinutes),
                _buildDurationPreset(context, ref, 25, timerState.initialDurationMinutes),
                _buildDurationPreset(context, ref, 50, timerState.initialDurationMinutes),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationPreset(BuildContext context, WidgetRef ref, int minutes, int currentDuration) {
    final isSelected = minutes == currentDuration;
    return GestureDetector(
      onTap: () {
        ref.read(timerProvider.notifier).setDuration(minutes);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent),
        ),
        child: Text(
          '$minutes min',
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
