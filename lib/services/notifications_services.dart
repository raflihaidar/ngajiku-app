import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../models/user_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();

    // Android settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);

    // Request permissions
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Request notification permission
    final status = await Permission.notification.request();
    if (status.isDenied) {
      print('Notification permission denied');
    }

    // For Android 13+ (API level 33+), request POST_NOTIFICATIONS permission
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
  }

  Future<void> scheduleDailyParentReminder(UserModel user) async {
    // Hanya untuk orang tua
    if (user.role != UserRole.parent) return;

    // Cancel existing notification first
    await cancelDailyReminder();

    // Schedule untuk jam 15:00 (3 sore) setiap hari
    await _notifications.zonedSchedule(
      0, // notification id
      'Pengingat Ngaji', // title
      'Sudahkah anak Anda mengaji hari ini?', // body
      _nextInstanceOfThreePM(), // scheduled time
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Pengingat Harian',
          channelDescription: 'Pengingat harian untuk mengaji',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          sound: 'default.caf',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );

    print('Daily reminder scheduled for 3 PM');
  }

  tz.TZDateTime _nextInstanceOfThreePM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      15, // 3 PM
      0, // 0 minutes
    );

    // Jika waktu sudah lewat hari ini, jadwalkan untuk besok
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  Future<void> cancelDailyReminder() async {
    await _notifications.cancel(0);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Method untuk menampilkan notifikasi langsung (testing)
  Future<void> showTestNotification() async {
    await _notifications.show(
      999,
      'Test Notifikasi',
      'Ini adalah test notifikasi',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test Channel',
          channelDescription: 'Channel untuk testing notifikasi',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  // Method untuk cek apakah sudah ada notifikasi terjadwal
  Future<bool> hasScheduledNotifications() async {
    final pendingNotifications =
        await _notifications.pendingNotificationRequests();
    return pendingNotifications.isNotEmpty;
  }
}
