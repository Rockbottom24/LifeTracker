import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  static const int _habitNamespace = 1;
  static const int _learningNamespace = 2;
  static const int _dailyNamespace = 3;

  bool _initialized = false;
  SharedPreferences? _prefs;

  Future<void> initialize() async {
    if (_initialized) return;
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    _prefs ??= await SharedPreferences.getInstance();
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
    if (kIsWeb) return;
    tz.initializeTimeZones();

    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final locationName = timezoneInfo?.identifier ?? 'Asia/Kolkata';
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

  /// Deterministic, collision-safe notification ID scoped to a user.
  int notificationIdFor({
    required int userId,
    required int namespace,
    required int entityId,
  }) {
    final mixed = Object.hash(userId, namespace, entityId);
    return mixed & 0x7fffffff;
  }

  int habitNotificationId({required int userId, required int habitId}) =>
      notificationIdFor(userId: userId, namespace: _habitNamespace, entityId: habitId);

  int learningNotificationId({required int userId, required int sessionId}) =>
      notificationIdFor(userId: userId, namespace: _learningNamespace, entityId: sessionId);

  int dailyReminderNotificationId({required int userId}) =>
      notificationIdFor(userId: userId, namespace: _dailyNamespace, entityId: 1);

  String _payloadFor({required int userId, required String kind, required int entityId}) {
    return jsonEncode({
      'userId': userId,
      'kind': kind,
      'entityId': entityId,
    });
  }

  Future<void> showTestNotification({required int userId}) async {
    if (kIsWeb) return;
    await initialize();
    final id = notificationIdFor(userId: userId, namespace: _dailyNamespace, entityId: 0);
    await _localNotifications.show(
      id,
      HabitReminderSchedule.habitNotificationTitle,
      'Track your habits and stay consistent today.',
      await _habitNotificationDetails(),
      payload: _payloadFor(userId: userId, kind: 'test', entityId: 0),
    );
  }

  Future<void> cancelHabitReminder({required int userId, required int habitId}) async {
    if (kIsWeb) return;
    await initialize();
    final notificationId = habitNotificationId(userId: userId, habitId: habitId);
    await _localNotifications.cancel(notificationId);
    await _unregisterId(userId, notificationId);
    // Also cancel legacy non-user-scoped IDs from older builds.
    await _localNotifications.cancel(habitId);
    AppLogger.debug('Cancelled habit notification (userId: $userId, habitId: $habitId, notificationId: $notificationId)');
  }

  Future<void> scheduleHabitReminder({
    required int userId,
    required int habitId,
    required String name,
    String? description,
    required int hour,
    required int minute,
    required HabitFrequency frequency,
    DateTime? anchorDate,
  }) async {
    if (kIsWeb) return;
    await initialize();

    final permissionsGranted = await arePermissionsGranted();
    if (!permissionsGranted) {
      await requestPermissions();
    }

    final notificationId = habitNotificationId(userId: userId, habitId: habitId);
    final scheduled = HabitReminderSchedule.firstFireTime(
      frequency: frequency,
      hour: hour,
      minute: minute,
      anchorDate: anchorDate,
    );
    final body = HabitReminderSchedule.notificationBody(name: name, description: description);
    final repeatComponents = HabitReminderSchedule.repeatComponents(frequency);

    try {
      await _localNotifications.cancel(notificationId);
      await _localNotifications.zonedSchedule(
        notificationId,
        HabitReminderSchedule.habitNotificationTitle,
        body,
        scheduled,
        await _habitNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: repeatComponents,
        payload: _payloadFor(userId: userId, kind: 'habit', entityId: habitId),
      );
      await _registerId(userId, notificationId);
    } catch (error, stackTrace) {
      AppLogger.debug('Failed to schedule habit notification for habitId=$habitId: $error');
      AppLogger.debug('$stackTrace');
      rethrow;
    }

    await _logPendingNotifications();
  }

  Future<void> scheduleLearningReminder({
    required int userId,
    required int sessionId,
    required String title,
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb) return;
    await initialize();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final notificationId = learningNotificationId(userId: userId, sessionId: sessionId);
    await _localNotifications.cancel(notificationId);
    // Cancel legacy learning IDs from older builds.
    await _localNotifications.cancel(2000 + sessionId);

    await _localNotifications.zonedSchedule(
      notificationId,
      'Learning reminder',
      'Time to learn "$title".',
      scheduled,
      await _learningNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: _payloadFor(userId: userId, kind: 'learning', entityId: sessionId),
    );
    await _registerId(userId, notificationId);
  }

  Future<void> cancelLearningReminder({required int userId, required int sessionId}) async {
    if (kIsWeb) return;
    await initialize();
    final notificationId = learningNotificationId(userId: userId, sessionId: sessionId);
    await _localNotifications.cancel(notificationId);
    await _localNotifications.cancel(2000 + sessionId);
    await _unregisterId(userId, notificationId);
  }

  Future<void> scheduleDailyReminder({
    required int userId,
    int hour = 8,
    int minute = 0,
  }) async {
    if (kIsWeb) return;
    await initialize();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final notificationId = dailyReminderNotificationId(userId: userId);
    await _localNotifications.cancel(notificationId);
    await _localNotifications.cancel(1); // legacy fixed id

    await _localNotifications.zonedSchedule(
      notificationId,
      'Daily habits reminder',
      'Open LifeTracker and check your progress.',
      scheduled,
      await _habitNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: _payloadFor(userId: userId, kind: 'daily', entityId: 1),
    );
    await _registerId(userId, notificationId);
  }

  /// Cancels all scheduled notifications owned by [userId], then clears that user's registry.
  /// Also cancels any leftover legacy device-global schedules that cannot be attributed.
  Future<void> cancelNotificationsForUser(int userId) async {
    if (kIsWeb) return;
    await initialize();
    final ids = await _registeredIds(userId);
    for (final id in ids) {
      await _localNotifications.cancel(id);
    }
    await _clearRegistry(userId);

    // Legacy schedules (pre-ownership) are device-global and unsafe after logout.
    await _localNotifications.cancelAll();
    await _logPendingNotifications();
  }

  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    await initialize();
    await _localNotifications.cancelAll();
    final prefs = await _preferences();
    final keys = prefs.getKeys().where((key) => key.startsWith('notification_ids_user_')).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
    await _logPendingNotifications();
  }

  Future<void> _registerId(int userId, int notificationId) async {
    final prefs = await _preferences();
    final ids = await _registeredIds(userId);
    if (!ids.contains(notificationId)) {
      ids.add(notificationId);
      await prefs.setString(_registryKey(userId), jsonEncode(ids));
    }
  }

  Future<void> _unregisterId(int userId, int notificationId) async {
    final prefs = await _preferences();
    final ids = await _registeredIds(userId);
    ids.remove(notificationId);
    await prefs.setString(_registryKey(userId), jsonEncode(ids));
  }

  Future<List<int>> _registeredIds(int userId) async {
    final prefs = await _preferences();
    final raw = prefs.getString(_registryKey(userId));
    if (raw == null || raw.isEmpty) return <int>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((item) => int.tryParse(item.toString()) ?? -1).where((id) => id >= 0).toList();
      }
    } catch (_) {}
    return <int>[];
  }

  Future<void> _clearRegistry(int userId) async {
    final prefs = await _preferences();
    await prefs.remove(_registryKey(userId));
  }

  String _registryKey(int userId) => 'notification_ids_user_$userId';

  Future<SharedPreferences> _preferences() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
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

  void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map && decoded['userId'] != null) {
        AppLogger.debug('Notification tapped for userId=${decoded['userId']} kind=${decoded['kind']}');
      }
    } catch (_) {}
  }

  static void _onBackgroundNotificationResponse(NotificationResponse response) {}
}
