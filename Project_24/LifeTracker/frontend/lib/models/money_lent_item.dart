class MoneyLentItem {
  MoneyLentItem({
    required this.id,
    required this.personName,
    required this.amount,
    required this.date,
    this.notes,
    this.isReceived = false,
    this.receivedAt,
  });

  final int id;
  final String personName;
  final double amount;
  final DateTime date;
  final String? notes;
  final bool isReceived;
  final DateTime? receivedAt;

  MoneyLentItem copyWith({
    int? id,
    String? personName,
    double? amount,
    DateTime? date,
    String? notes,
    bool? isReceived,
    DateTime? receivedAt,
  }) {
    return MoneyLentItem(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      isReceived: isReceived ?? this.isReceived,
      receivedAt: receivedAt ?? this.receivedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'personName': personName,
        'amount': amount,
        'date': date.toIso8601String(),
        'notes': notes,
        'isReceived': isReceived,
        'receivedAt': receivedAt?.toIso8601String(),
      };

  factory MoneyLentItem.fromJson(Map<String, dynamic> json) => MoneyLentItem(
        id: json['id'] as int? ?? 0,
        personName: json['personName'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
        notes: json['notes'] as String?,
        isReceived: json['isReceived'] as bool? ?? false,
        receivedAt: DateTime.tryParse(json['receivedAt']?.toString() ?? ''),
      );
}
