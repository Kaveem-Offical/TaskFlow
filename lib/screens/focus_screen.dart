import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../providers/timer_provider.dart';
import '../models/task_model.dart';
import '../theme/app_theme.dart';
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Focus', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 160),
        child: Column(
          children: [
            // Task Selector
            tasksAsync.when(
              data: (tasks) {
                final activeTasks = tasks.where((t) => !t.isCompleted).toList();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.5)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('Select a task to focus on...'),
                      value: timerState.selectedTaskId,
                      icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primary),
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
              loading: () => const LinearProgressIndicator(),
              error: (e, st) => Text('Error loading tasks: $e'),
            ),
            const SizedBox(height: 48),
            
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
                    backgroundColor: AppTheme.surfaceContainerHigh,
                    color: AppTheme.primary,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$minutes:$seconds',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timerState.isRunning ? 'Focusing...' : 'Ready to focus',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.outline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 48),
            
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
                      backgroundColor: AppTheme.primary,
                      foregroundColor: AppTheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Start', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      ref.read(timerProvider.notifier).pause();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryContainer,
                      foregroundColor: AppTheme.onSecondaryContainer,
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Pause', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () {
                    ref.read(timerProvider.notifier).reset();
                  },
                  icon: const Icon(Icons.refresh),
                  iconSize: 32,
                  color: AppTheme.outline,
                ),
              ],
            ),
            const SizedBox(height: 48),
            
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.1) : AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.primary : Colors.transparent),
        ),
        child: Text(
          '$minutes min',
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
