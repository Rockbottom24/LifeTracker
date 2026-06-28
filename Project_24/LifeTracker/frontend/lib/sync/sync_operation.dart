import 'sync_status.dart';

enum SyncOperationType {
  habitCreate,
  habitUpdate,
  habitDelete,
  habitComplete,
  habitUndo,
  learningCreate,
  learningUpdate,
  learningDelete,
  learningStart,
  learningComplete,
}

class SyncOperation {
  const SyncOperation({
    required this.id,
    required this.type,
    required this.localKey,
    this.entityId,
    required this.payload,
    required this.createdAt,
    this.status = SyncStatus.pendingCreate,
  });

  final String id;
  final SyncOperationType type;
  final String localKey;
  final int? entityId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final SyncStatus status;

  bool get isPending => status.isPending;

  SyncOperation copyWith({
    SyncStatus? status,
    int? entityId,
    Map<String, dynamic>? payload,
  }) {
    return SyncOperation(
      id: id,
      type: type,
      localKey: localKey,
      entityId: entityId ?? this.entityId,
      payload: payload ?? this.payload,
      createdAt: createdAt,
      status: status ?? this.status,
    );
  }

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      id: json['id'] as String? ?? '',
      type: SyncOperationType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => SyncOperationType.habitCreate,
      ),
      localKey: json['localKey'] as String? ?? '',
      entityId: _toInt(json['entityId']),
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? {}),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      status: SyncStatus.fromName(json['status'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'localKey': localKey,
      'entityId': entityId,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
    };
  }

  static int? _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
