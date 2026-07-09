import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/providers.dart';
import '../models/task_model.dart';
import '../widgets/premium/premium_card.dart';

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);
    final tasksAsync = ref.watch(tasksStreamProvider);
    final theme = Theme.of(context);

    final minutes = (timerState.remainingSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (timerState.remainingSeconds % 60).toString().padLeft(2, '0');
    final progress = 1 - (timerState.remainingSeconds / (timerState.initialDurationMinutes * 60));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Header
              Text(
                'Focus',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0, curve: Curves.easeOutQuart),
              const SizedBox(height: 48),
              
              // Task Selector
              tasksAsync.when(
                data: (tasks) {
                  final activeTasks = tasks.where((t) => !t.isCompleted).toList();
                  Task? selectedTask;
                  try {
                    selectedTask = activeTasks.firstWhere((t) => t.id == timerState.selectedTaskId);
                  } catch (_) {}

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showTaskSelector(context, activeTasks, timerState.selectedTaskId);
                    },
                    child: PremiumCard(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          Icon(LucideIcons.target, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              selectedTask?.title ?? 'Select a task to focus on',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: selectedTask == null ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface,
                                fontWeight: selectedTask == null ? FontWeight.w400 : FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(LucideIcons.chevronDown, color: theme.colorScheme.onSurfaceVariant, size: 20),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart);
                },
                loading: () => const SizedBox(height: 56),
                error: (_, _) => const SizedBox(height: 56),
              ),

              const Spacer(flex: 2),

              // Timer
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 280,
                    height: 280,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: progress, end: progress),
                      duration: const Duration(milliseconds: 250),
                      builder: (context, value, _) => CircularProgressIndicator(
                        value: value,
                        strokeWidth: 4,
                        strokeCap: StrokeCap.round,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        color: theme.colorScheme.primary,
                      ),
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
                              icon: Icon(LucideIcons.minusCircle, color: theme.colorScheme.onSurfaceVariant),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                ref.read(timerProvider.notifier).subtractTime(5);
                              },
                            ).animate().fadeIn(),
                          Text(
                            '$minutes:$seconds',
                            style: theme.textTheme.displayLarge?.copyWith(
                              fontSize: 72,
                              fontWeight: FontWeight.w300,
                              letterSpacing: -2,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          if (timerState.isRunning)
                            IconButton(
                              icon: Icon(LucideIcons.plusCircle, color: theme.colorScheme.onSurfaceVariant),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                ref.read(timerProvider.notifier).addTime(5);
                              },
                            ).animate().fadeIn(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        timerState.isRunning ? 'Focusing...' : 'Ready to focus',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ).animate(target: timerState.isRunning ? 1 : 0).fade(duration: 200.ms),
                    ],
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms).scaleXY(begin: 0.95, end: 1.0, curve: Curves.easeOutBack),

              const Spacer(flex: 2),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!timerState.isRunning)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        ref.read(timerProvider.notifier).start();
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: Icon(LucideIcons.play, color: theme.colorScheme.onPrimary, size: 36),
                      ),
                    ).animate().fadeIn(delay: 300.ms).scaleXY(begin: 0.8, end: 1.0, curve: Curves.easeOutBack)
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ref.read(timerProvider.notifier).pause();
                          },
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(LucideIcons.pause, color: theme.colorScheme.onSurface, size: 36),
                          ),
                        ),
                        const SizedBox(width: 24),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            ref.read(timerProvider.notifier).endEarly();
                          },
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(LucideIcons.square, color: theme.colorScheme.error, size: 24),
                          ),
                        ),
                      ],
                    ).animate().fadeIn().scaleXY(begin: 0.9, end: 1.0, curve: Curves.easeOutBack),
                ],
              ),
              const SizedBox(height: 48),

              // Duration Presets
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDurationPreset(15, timerState.initialDurationMinutes),
                  _buildDurationPreset(25, timerState.initialDurationMinutes),
                  _buildDurationPreset(50, timerState.initialDurationMinutes),
                ],
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuart),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationPreset(int minutes, int currentDuration) {
    final isSelected = minutes == currentDuration;
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(timerProvider.notifier).setDuration(minutes);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
            width: 1,
          ),
        ),
        child: Text(
          '$minutes m',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  void _showTaskSelector(BuildContext context, List<Task> tasks, String? selectedTaskId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Select a task',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: tasks.length + 1,
                itemBuilder: (ctx, index) {
                  if (index == 0) {
                    final isSelected = selectedTaskId == null;
                    return ListTile(
                      title: const Text('No specific task'),
                      trailing: isSelected ? Icon(LucideIcons.check, color: Theme.of(context).colorScheme.primary) : null,
                      onTap: () {
                        ref.read(timerProvider.notifier).selectTask(null);
                        Navigator.pop(ctx);
                      },
                    );
                  }
                  final task = tasks[index - 1];
                  final isSelected = selectedTaskId == task.id;
                  return ListTile(
                    title: Text(task.title),
                    subtitle: task.category.isNotEmpty ? Text(task.category) : null,
                    trailing: isSelected ? Icon(LucideIcons.check, color: Theme.of(context).colorScheme.primary) : null,
                    onTap: () {
                      ref.read(timerProvider.notifier).selectTask(task.id);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
