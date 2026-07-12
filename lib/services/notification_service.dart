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
      await requestPermissions();
    } catch (e) {
      print('NotificationService init error: $e');
    }
  }

  Future<bool> requestPermissions() async {
    bool granted = false;

    try {
      final androidImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final notifGranted = await androidImplementation.requestNotificationsPermission();
        await androidImplementation.requestExactAlarmsPermission();
        granted = notifGranted ?? true;
      }

      final iosImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosImplementation != null) {
        final iosGranted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        granted = iosGranted ?? true;
      }
    } catch (e) {
      print('NotificationService requestPermissions error: $e');
    }

    return granted;
  }

  Future<void> scheduleTaskNotification(Task task) async {
    // If completed or reminder disabled (-1 or null), cancel any scheduled notification
    if (task.isCompleted || task.notificationMinutesBefore == null || task.notificationMinutesBefore == -1) {
      await cancelNotification(task.id.hashCode);
      return;
    }

    // Determine target time: use startTime if set, otherwise dueDate
    final DateTime? targetTime = task.startTime ?? task.dueDate;
    if (targetTime == null) return;

    final int minutesBefore = task.notificationMinutesBefore ?? 0;
    final DateTime scheduledDateTime = targetTime.subtract(Duration(minutes: minutesBefore));

    // Only schedule if the calculated notification time is in the future
    if (scheduledDateTime.isBefore(DateTime.now())) return;

    // Ensure permissions are granted
    await requestPermissions();

    final androidDetails = const AndroidNotificationDetails(
      'taskflow_task_channel',
      'Task Reminders',
      channelDescription: 'Notifications for task start times and reminders',
      importance: Importance.max,
      priority: Priority.high,
    );
    final iosDetails = const DarwinNotificationDetails();
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    // Cancel any existing notification for this task to avoid duplicates
    await cancelNotification(task.id.hashCode);

    String title;
    String body;
    if (minutesBefore > 0) {
      String timeLabel;
      if (minutesBefore < 60) {
        timeLabel = '$minutesBefore minutes';
      } else if (minutesBefore == 60) {
        timeLabel = '1 hour';
      } else if (minutesBefore == 1440) {
        timeLabel = '1 day';
      } else {
        timeLabel = '$minutesBefore minutes';
      }
      title = 'Upcoming Task Reminder ⏰';
      body = 'Your task "${task.title}" starts in $timeLabel.';
    } else {
      title = 'Time to Focus! 🚀';
      body = 'Your task "${task.title}" is scheduled to start now.';
    }

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: task.id.hashCode,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledDateTime, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      print('NotificationService schedule error: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id: id);
  }
}

