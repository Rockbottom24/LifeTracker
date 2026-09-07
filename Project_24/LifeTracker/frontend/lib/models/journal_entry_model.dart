class JournalEntryModel {
  const JournalEntryModel({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.mood,
    required this.category,
    this.imagePaths = const [],
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String content;
  final DateTime date;
  final String mood; // TRIUMPHANT, STEADFAST, FIERCE, CONTEMPLATIVE, TURBULENT
  final String category; // Personal Chronicle, Battle Log, Wisdom, Journey, House Matters
  final List<String> imagePaths;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  JournalEntryModel copyWith({
    String? title,
    String? content,
    DateTime? date,
    String? mood,
    String? category,
    List<String>? imagePaths,
    bool? isPinned,
    DateTime? updatedAt,
  }) {
    return JournalEntryModel(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      mood: mood ?? this.mood,
      category: category ?? this.category,
      imagePaths: imagePaths ?? this.imagePaths,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'mood': mood,
      'category': category,
      'imagePaths': imagePaths,
      'isPinned': isPinned,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory JournalEntryModel.fromJson(Map<String, dynamic> json) {
    return JournalEntryModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      mood: json['mood']?.toString() ?? 'STEADFAST',
      category: json['category']?.toString() ?? 'Personal Chronicle',
      imagePaths: (json['imagePaths'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      isPinned: json['isPinned'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
