// Stub for web and unsupported platforms
class ReminderScheduler {
  static Future<void> initialize() async {}
  static Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String repeat = 'None',
  }) async {}
  static Future<void> cancelReminder(int id) async {}
}
