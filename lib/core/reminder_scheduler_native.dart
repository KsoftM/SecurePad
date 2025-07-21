import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class ReminderScheduler {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit);
    await _notifications.initialize(initSettings);
  }

  static Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String repeat = 'None',
  }) async {
    final tz.TZDateTime tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
    final details = NotificationDetails(
      android: AndroidNotificationDetails('reminders', 'Reminders',
          importance: Importance.max, priority: Priority.high),
    );
    if (repeat == 'None') {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        details,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } else {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        details,
        androidAllowWhileIdle: true,
        matchDateTimeComponents: repeat == 'Daily'
            ? DateTimeComponents.time
            : repeat == 'Weekly'
                ? DateTimeComponents.dayOfWeekAndTime
                : repeat == 'Monthly'
                    ? DateTimeComponents.dayOfMonthAndTime
                    : repeat == 'Yearly'
                        ? DateTimeComponents.dateAndTime
                        : null,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static Future<void> cancelReminder(int id) async {
    await _notifications.cancel(id);
  }
}
