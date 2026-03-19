import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _dailyNotificationId = 9001;

  static const AndroidNotificationChannel _dailyChannel =
      AndroidNotificationChannel(
    'idea_memo_daily',
    'Idea Memo Daily',
    description: '毎日のアイデア見返し通知',
    importance: Importance.defaultImportance,
  );

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Androidだけ使うならこれで十分
    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
    );

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Android 13+ の通知権限
    await androidPlugin?.requestNotificationsPermission();

    // 通知チャンネル作成
    await androidPlugin?.createNotificationChannel(_dailyChannel);
  }

  static Future<void> setDailyIdeaReminder(bool enabled) async {
    if (!enabled) {
      await _plugin.cancel(id: _dailyNotificationId);
      return;
    }

    final now = tz.TZDateTime.now(tz.local);

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      21,
      0,
      0,
    );

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'idea_memo_daily',
        'Idea Memo Daily',
        channelDescription: '毎日のアイデア見返し通知',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );

    await _plugin.zonedSchedule(
      id: _dailyNotificationId,
      title: 'アイデアメモ',
      body: '今日は何かひらめいた？過去のメモも見返してみよう。',
      scheduledDate: scheduled,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}