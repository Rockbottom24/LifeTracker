class ScannedFood {
  final int? foodId;
  final bool local;
  final String barcode;
  final String name;
  final String brand;
  final String imageUrl;
  final String source;

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;

  const ScannedFood({
    this.foodId,
    this.local = false,
    required this.barcode,
    required this.name,
    required this.brand,
    required this.imageUrl,
    this.source = '',
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  });

  factory ScannedFood.fromJson(Map<String, dynamic> json) {
    return ScannedFood(
      foodId: _toInt(json['foodId']),
      local: json['local'] == true,
      barcode: json['barcode']?.toString() ?? '',
      name: json['productName']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      calories: _toDouble(json['calories']),
      protein: _toDouble(json['protein']),
      carbs: _toDouble(json['carbs']),
      fat: _toDouble(json['fat']),
      fiber: _toDouble(json['fiber']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static int? _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
