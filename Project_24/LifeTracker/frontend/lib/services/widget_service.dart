import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WidgetService {
  static const MethodChannel _channel = MethodChannel('com.frontend/widget');

  /// Saves current quest, workout, and nutrition data to SharedPreferences and notifies the Android widget.
  static Future<void> updateWidgetData({
    required String houseKey,
    required int completedQuests,
    required int totalQuests,
    required int streakDays,
    required String workoutName,
    required String nutritionText,
  }) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString('widget_house_key', houseKey);
      await sp.setInt('widget_completed_quests', completedQuests);
      await sp.setInt('widget_total_quests', totalQuests);
      await sp.setInt('widget_current_streak', streakDays);
      await sp.setString('widget_workout_name', workoutName);
      await sp.setString('widget_calories_text', nutritionText);

      await _channel.invokeMethod('updateWidget');
    } catch (_) {}
  }
}
