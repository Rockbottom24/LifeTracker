import '../models/learning_session_response.dart';
import '../sync/sync_status.dart';

class StoredLearningSession {
  const StoredLearningSession({
    required this.localKey,
    required this.session,
    required this.syncStatus,
    required this.updatedAt,
  });

  final String localKey;
  final LearningSessionResponse session;
  final SyncStatus syncStatus;
  final DateTime updatedAt;

  StoredLearningSession copyWith({
    LearningSessionResponse? session,
    SyncStatus? syncStatus,
    DateTime? updatedAt,
    String? localKey,
  }) {
    return StoredLearningSession(
      localKey: localKey ?? this.localKey,
      session: session ?? this.session,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory StoredLearningSession.fromJson(Map<String, dynamic> json) {
    return StoredLearningSession(
      localKey: json['localKey'] as String? ?? '',
      session: LearningSessionResponse.fromJson(Map<String, dynamic>.from(json['session'] as Map)),
      syncStatus: SyncStatus.fromName(json['syncStatus'] as String?),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'localKey': localKey,
      'session': session.toJson(),
      'syncStatus': syncStatus.name,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
