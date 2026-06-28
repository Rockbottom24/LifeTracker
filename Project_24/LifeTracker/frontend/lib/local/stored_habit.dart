import '../models/habit_response.dart';
import '../sync/sync_status.dart';

class StoredHabit {
  const StoredHabit({
    required this.localKey,
    required this.habit,
    required this.syncStatus,
    required this.updatedAt,
  });

  final String localKey;
  final HabitResponse habit;
  final SyncStatus syncStatus;
  final DateTime updatedAt;

  StoredHabit copyWith({
    HabitResponse? habit,
    SyncStatus? syncStatus,
    DateTime? updatedAt,
    String? localKey,
  }) {
    return StoredHabit(
      localKey: localKey ?? this.localKey,
      habit: habit ?? this.habit,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory StoredHabit.fromJson(Map<String, dynamic> json) {
    return StoredHabit(
      localKey: json['localKey'] as String? ?? '',
      habit: HabitResponse.fromJson(Map<String, dynamic>.from(json['habit'] as Map)),
      syncStatus: SyncStatus.fromName(json['syncStatus'] as String?),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'localKey': localKey,
      'habit': habit.toJson(),
      'syncStatus': syncStatus.name,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
