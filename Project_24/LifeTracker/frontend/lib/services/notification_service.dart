import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/habit_frequency.dart';
import 'habit_reminder_schedule.dart';
import '../utils/app_logger.dart';

class NotificationService {
  NotificationService._internal();

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const String _channelId = 'life_tracker_habit_reminders';
  static const String _channelName = 'Habit Reminders';
  static const String _channelDescription = 'Daily and recurring reminders for your habits.';

  static const String _learningChannelId = 'life_tracker_learning_reminders';
  static const String _learningChannelName = 'Learning Reminders';
  static const String _learningChannelDescription = 'Reminders for learning sessions.';

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    await _configureLocalTimeZone();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const macosSettings = DarwinInitializationSettings();

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: macosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
    );

    await _createAndroidChannels();
    _initialized = true;

    AppLogger.debug('NotificationService initialized (timezone: ${tz.local.name})');
  }

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();

    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final locationName = timezoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(locationName));
      AppLogger.debug('Local timezone set to device timezone: $locationName');
    } catch (error) {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      AppLogger.debug(
        'Could not read device timezone ($error). Falling back to Asia/Kolkata.',
      );
    }
  }

  Future<void> _createAndroidChannels() async {
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        playSound: true,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _learningChannelId,
        _learningChannelName,
        description: _learningChannelDescription,
        importance: Importance.high,
        playSound: true,
      ),
    );
  }

  Future<bool> requestPermissions() async {
    await initialize();

    var granted = true;

    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final notificationGranted = await androidPlugin.requestNotificationsPermission();
      granted = notificationGranted ?? false;

      final exactAlarmGranted = await androidPlugin.requestExactAlarmsPermission();
      AppLogger.debug(
        'Android notification permission: $notificationGranted, exact alarms: $exactAlarmGranted',
      );

      if (notificationGranted != true) {
        AppLogger.debug('POST_NOTIFICATIONS permission was not granted.');
      }
    }

    final iosPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final macosPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();

    final iosStatus = iosPlugin?.requestPermissions(alert: true, badge: true, sound: true) ??
        Future.value(true);
    final macosStatus =
        macosPlugin?.requestPermissions(alert: true, badge: true, sound: true) ?? Future.value(true);

    final grantedIos = await iosStatus ?? true;
    final grantedMacos = await macosStatus ?? true;

    return granted && grantedIos && grantedMacos;
  }

  Future<bool> arePermissionsGranted() async {
    await initialize();

    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final notificationsEnabled = await androidPlugin.areNotificationsEnabled() ?? false;
      final exactAlarmsEnabled = await androidPlugin.canScheduleExactNotifications() ?? true;
      return notificationsEnabled && exactAlarmsEnabled;
    }

    return true;
  }

  Future<void> showTestNotification() async {
    await initialize();
    await _localNotifications.show(
      0,
      HabitReminderSchedule.habitNotificationTitle,
      'Track your habits and stay consistent today.',
      await _habitNotificationDetails(),
    );
  }

  int habitNotificationId(int habitId) => habitId;

  Future<void> cancelHabitReminder(int habitId) async {
    await initialize();
    final notificationId = habitNotificationId(habitId);
    await _localNotifications.cancel(notificationId);
    AppLogger.debug('Cancelled habit notification (habitId: $habitId, notificationId: $notificationId)');
    await _logPendingNotifications();
  }

  Future<void> scheduleHabitReminder({
    required int habitId,
    required String name,
    String? description,
    required int hour,
    required int minute,
    required HabitFrequency frequency,
    DateTime? anchorDate,
  }) async {
    await initialize();

    final permissionsGranted = await arePermissionsGranted();
    if (!permissionsGranted) {
      AppLogger.debug('Notification permissions missing. Requesting before scheduling habit $habitId.');
      await requestPermissions();
    }

    final notificationId = habitNotificationId(habitId);
    final scheduled = HabitReminderSchedule.firstFireTime(
      frequency: frequency,
      hour: hour,
      minute: minute,
      anchorDate: anchorDate,
    );
    final body = HabitReminderSchedule.notificationBody(name: name, description: description);
    final repeatComponents = HabitReminderSchedule.repeatComponents(frequency);

    AppLogger.debug('Scheduling notification:');
    AppLogger.debug('  Habit ID: $habitId');
    AppLogger.debug('  Habit Name: $name');
    AppLogger.debug('  Reminder Time: ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
    AppLogger.debug('  Frequency: ${frequency.apiValue}');
    AppLogger.debug('  Scheduled DateTime: $scheduled (${tz.local.name})');
    AppLogger.debug('  Notification ID: $notificationId');

    try {
      await _localNotifications.zonedSchedule(
        notificationId,
        HabitReminderSchedule.habitNotificationTitle,
        body,
        scheduled,
        await _habitNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: repeatComponents,
      );
    } catch (error, stackTrace) {
      AppLogger.debug('Failed to schedule habit notification for habitId=$habitId: $error');
      AppLogger.debug('$stackTrace');
      rethrow;
    }

    await _logPendingNotifications();
  }

  Future<void> scheduleLearningReminder({
    required int sessionId,
    required String title,
    required int hour,
    required int minute,
  }) async {
    await initialize();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _localNotifications.zonedSchedule(
      2000 + sessionId,
      'Learning reminder',
      'Time to learn "$title".',
      scheduled,
      await _learningNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelLearningReminder(int sessionId) async {
    await initialize();
    await _localNotifications.cancel(2000 + sessionId);
  }

  Future<void> scheduleDailyReminder({int hour = 8, int minute = 0}) async {
    await initialize();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _localNotifications.zonedSchedule(
      1,
      'Daily habits reminder',
      'Open LifeTracker and check your progress.',
      scheduled,
      await _habitNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelAllNotifications() async {
    await initialize();
    await _localNotifications.cancelAll();
    await _logPendingNotifications();
  }

  Future<void> _logPendingNotifications() async {
    final pending = await _localNotifications.pendingNotificationRequests();
    AppLogger.debug('Pending notifications count: ${pending.length}');
    AppLogger.debug('Pending notification IDs: ${pending.map((item) => item.id).join(', ')}');
  }

  Future<NotificationDetails> _habitNotificationDetails() async {
    const androidChannel = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const iosChannel = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return const NotificationDetails(
      android: androidChannel,
      iOS: iosChannel,
      macOS: iosChannel,
    );
  }

  Future<NotificationDetails> _learningNotificationDetails() async {
    const androidChannel = AndroidNotificationDetails(
      _learningChannelId,
      _learningChannelName,
      channelDescription: _learningChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const iosChannel = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return const NotificationDetails(
      android: androidChannel,
      iOS: iosChannel,
      macOS: iosChannel,
    );
  }

  void _onNotificationResponse(NotificationResponse response) {}

  static void _onBackgroundNotificationResponse(NotificationResponse response) {}
}
