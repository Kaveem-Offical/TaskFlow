import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/task_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Initialize TimeZones
      tz.initializeTimeZones();
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timeZoneInfo.toString();
      tz.setLocalLocation(tz.getLocation(timeZoneName));

      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      await flutterLocalNotificationsPlugin.initialize(
        settings: const InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
          macOS: initializationSettingsIOS,
        ),
      );
      _isInitialized = true;
    } catch (e) {
      print('NotificationService init error: $e');
    }
  }

  Future<void> scheduleTaskNotification(Task task) async {
    if (task.startTime == null) return;
    
    // Only schedule if the start time is in the future
    if (task.startTime!.isBefore(DateTime.now())) return;

    final androidDetails = const AndroidNotificationDetails(
      'taskflow_task_channel',
      'Task Reminders',
      channelDescription: 'Notifications for task start times',
      importance: Importance.max,
      priority: Priority.high,
    );
    final iosDetails = const DarwinNotificationDetails();
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    // Cancel any existing notification for this task to avoid duplicates
    await cancelNotification(task.id.hashCode);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: task.id.hashCode,
      title: 'Time to Focus!',
      body: 'Your task "${task.title}" is scheduled to start now.',
      scheduledDate: tz.TZDateTime.from(task.startTime!, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id: id);
  }
}
