import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models.dart';

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> initialize() async {
    if (!Platform.isAndroid) return;
    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Kyiv'));
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      _ready = await _plugin.initialize(settings) ?? false;
    } catch (_) {
      _ready = false;
    }
  }

  Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<void> sync(
    ReminderSettings settings, {
    bool morningTaken = false,
    bool eveningTaken = false,
  }) async {
    if (!_ready) return;
    final now = tz.TZDateTime.now(tz.local);
    try {
      for (var offset = 0; offset < 31; offset += 1) {
        final day = now.add(Duration(days: offset));
        await _plugin.cancel(_id(day, true));
        await _plugin.cancel(_id(day, false));
      }
      for (var offset = 0; offset < 30; offset += 1) {
        final day = now.add(Duration(days: offset));
        if (settings.morningEnabled && !(offset == 0 && morningTaken)) {
          await _schedule(
            day,
            true,
            settings.morningHour,
            settings.morningMinute,
            now,
          );
        }
        if (settings.eveningEnabled && !(offset == 0 && eveningTaken)) {
          await _schedule(
            day,
            false,
            settings.eveningHour,
            settings.eveningMinute,
            now,
          );
        }
      }
    } catch (_) {
      // Нагадування не повинні заважати запуску застосунку.
    }
  }

  Future<void> _schedule(
    tz.TZDateTime day,
    bool morning,
    int hour,
    int minute,
    tz.TZDateTime now,
  ) async {
    final when = tz.TZDateTime(
      tz.local,
      day.year,
      day.month,
      day.day,
      hour,
      minute,
    );
    if (!when.isAfter(now)) return;
    await _plugin.zonedSchedule(
      _id(day, morning),
      morning ? 'Ранкові таблетки' : 'Вечірні таблетки',
      'Відміть приймання у Zrobleno — синичка нагадає без докорів.',
      when,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medicine_reminders_v2',
          'Нагадування про ліки',
          channelDescription: 'Ранкові та вечірні нагадування про таблетки',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(
            'zrobleno_notification',
          ),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: morning ? 'medicine:morning' : 'medicine:evening',
    );
  }

  Future<void> cancelToday(bool morning) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(_id(tz.TZDateTime.now(tz.local), morning));
    } catch (_) {
      // Скасування вже відсутнього сповіщення не є помилкою для користувача.
    }
  }

  Future<void> showTest() async {
    if (!_ready) return;
    await _plugin.show(
      991,
      'Синичка на зв’язку',
      'Тестове нагадування працює 🐦',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medicine_reminders_v2',
          'Нагадування про ліки',
          channelDescription: 'Ранкові та вечірні нагадування про таблетки',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(
            'zrobleno_notification',
          ),
        ),
      ),
    );
  }

  int _id(DateTime date, bool morning) {
    final datePart = date.year * 10000 + date.month * 100 + date.day;
    return (morning ? 10000000 : 40000000) + datePart;
  }
}
