import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/dashboard_response.dart';
import '../models/habit_response.dart';

class DashboardViewData {
  const DashboardViewData({
    required this.greeting,
    required this.userName,
    required this.currentDate,
    required this.currentStreak,
    required this.motivationalMessage,
    required this.summary,
    required this.todayHabits,
    required this.weeklyProgress,
    this.upcomingReminder,
  });

  final String greeting;
  final String userName;
  final DateTime currentDate;
  final int currentStreak;
  final String motivationalMessage;
  final DashboardSummary summary;
  final List<TodayHabitViewItem> todayHabits;
  final List<WeeklyDayProgress> weeklyProgress;
  final UpcomingReminder? upcomingReminder;
}

class TodayHabitViewItem {
  const TodayHabitViewItem({
    required this.habitId,
    required this.name,
    required this.iconName,
    required this.colorHex,
    required this.completed,
    required this.frequencyLabel,
    this.reminderLabel,
  });

  final int habitId;
  final String name;
  final String? iconName;
  final String? colorHex;
  final bool completed;
  final String frequencyLabel;
  final String? reminderLabel;
}

class UpcomingReminder {
  const UpcomingReminder({
    required this.habitName,
    required this.reminderLabel,
    required this.iconName,
  });

  final String habitName;
  final String reminderLabel;
  final String? iconName;
}

class WeeklyDayProgress {
  const WeeklyDayProgress({
    required this.label,
    required this.value,
    required this.isToday,
  });

  final String label;
  final double value;
  final bool isToday;
}

class DashboardViewDataMapper {
  static DashboardViewData from({
    required DashboardResponse response,
    List<HabitResponse> habits = const [],
  }) {
    final summary = response.summary ?? DashboardSummary();
    final currentDate = response.currentDate ?? DateTime.now();
    final todayItems = _mapTodayHabits(response.todayHabits ?? [], habits);
    final mergedSummary = _mergeSummary(summary, habits, todayItems);

    return DashboardViewData(
      greeting: response.greeting ?? _defaultGreeting(),
      userName: response.userName ?? 'there',
      currentDate: currentDate,
      currentStreak: mergedSummary.currentStreak,
      motivationalMessage: _motivationalMessage(mergedSummary),
      summary: mergedSummary,
      todayHabits: todayItems,
      weeklyProgress: _weeklyProgress(mergedSummary, currentDate),
      upcomingReminder: _upcomingReminder(todayItems, habits),
    );
  }

  static DashboardSummary _mergeSummary(
    DashboardSummary summary,
    List<HabitResponse> habits,
    List<TodayHabitViewItem> todayItems,
  ) {
    if (habits.isEmpty) return summary;

    final total = habits.length;
    final completed = todayItems.where((item) => item.completed).length;
    final pending = (total - completed).clamp(0, total);
    final completionPercentage = total == 0 ? 0.0 : (completed / total) * 100;

    return DashboardSummary(
      totalHabits: total,
      completedHabits: completed,
      pendingHabits: pending,
      completionPercentage: completionPercentage,
      currentStreak: summary.currentStreak,
      longestStreak: summary.longestStreak,
    );
  }

  static List<TodayHabitViewItem> _mapTodayHabits(
    List<TodayHabit> todayHabits,
    List<HabitResponse> habits,
  ) {
    if (todayHabits.isEmpty && habits.isNotEmpty) {
      return habits
          .where((habit) => habit.isActive)
          .map(
            (habit) => TodayHabitViewItem(
              habitId: habit.id,
              name: habit.name,
              iconName: habit.iconName,
              colorHex: habit.colorHex,
              completed: false,
              frequencyLabel: habit.frequencyLabel,
              reminderLabel: habit.formattedReminderTime,
            ),
          )
          .toList();
    }

    return todayHabits.map((item) {
      HabitResponse? habit;
      if (item.habitId != null) {
        for (final candidate in habits) {
          if (candidate.id == item.habitId) {
            habit = candidate;
            break;
          }
        }
      }

      return TodayHabitViewItem(
        habitId: item.habitId ?? 0,
        name: item.habitName ?? habit?.name ?? 'Habit',
        iconName: item.icon ?? habit?.iconName,
        colorHex: item.color ?? habit?.colorHex,
        completed: item.completed,
        frequencyLabel: habit?.frequencyLabel ?? 'Daily',
        reminderLabel: habit?.formattedReminderTime,
      );
    }).where((item) => item.habitId != 0).toList();
  }

  static UpcomingReminder? _upcomingReminder(
    List<TodayHabitViewItem> todayHabits,
    List<HabitResponse> habits,
  ) {
    final now = TimeOfDay.now();
    final pending = todayHabits.where((item) => !item.completed).toList();
    if (pending.isEmpty) return null;

    UpcomingReminder? nearest;
    int? nearestMinutes;

    for (final item in pending) {
      HabitResponse? habit;
      for (final candidate in habits) {
        if (candidate.id == item.habitId) {
          habit = candidate;
          break;
        }
      }

      if (habit?.reminderTime == null || habit?.notificationsEnabled != true) {
        continue;
      }

      final reminderTime = habit!.reminderTime!;
      final minutes = reminderTime.hour * 60 + reminderTime.minute;
      final nowMinutes = now.hour * 60 + now.minute;
      final delta = minutes >= nowMinutes ? minutes - nowMinutes : minutes + (24 * 60 - nowMinutes);

      if (nearestMinutes == null || delta < nearestMinutes) {
        nearestMinutes = delta;
        nearest = UpcomingReminder(
          habitName: item.name,
          reminderLabel: habit.formattedReminderTime ?? '',
          iconName: item.iconName,
        );
      }
    }

    if (nearest != null) return nearest;

    final fallback = pending.firstWhere(
      (item) => item.reminderLabel != null,
      orElse: () => pending.first,
    );

    final reminderLabel = fallback.reminderLabel;
    if (reminderLabel == null) return null;

    return UpcomingReminder(
      habitName: fallback.name,
      reminderLabel: reminderLabel,
      iconName: fallback.iconName,
    );
  }

  static List<WeeklyDayProgress> _weeklyProgress(DashboardSummary summary, DateTime currentDate) {
    final labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final todayIndex = currentDate.weekday - 1;

    return List.generate(7, (index) {
      final daysAgo = todayIndex - index;
      double value;

      if (daysAgo == 0) {
        value = summary.completionPercentage / 100;
      } else if (daysAgo > 0 && summary.currentStreak > daysAgo) {
        value = 1;
      } else {
        value = 0.15;
      }

      return WeeklyDayProgress(
        label: labels[index],
        value: value.clamp(0, 1),
        isToday: daysAgo == 0,
      );
    });
  }

  static String _motivationalMessage(DashboardSummary summary) {
    if (summary.totalHabits == 0) {
      return 'Start small. Stay consistent.';
    }
    if (summary.currentStreak >= 7) {
      return 'Incredible momentum. Keep going.';
    }
    if (summary.currentStreak > 0) {
      return "You're on a ${summary.currentStreak} day streak.";
    }
    if (summary.completionPercentage >= 100) {
      return 'Perfect day. You crushed it.';
    }
    if (summary.pendingHabits > 0) {
      return 'Keep the momentum going.';
    }
    return 'Every habit counts toward a better you.';
  }

  static String _defaultGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 18) return 'Good Afternoon';
    return 'Good Evening';
  }
}

class DashboardFormatters {
  static String formatDate(DateTime date) => DateFormat('EEEE, MMMM d').format(date);
}
