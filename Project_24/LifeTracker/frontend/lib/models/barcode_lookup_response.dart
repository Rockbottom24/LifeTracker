import 'scanned_food.dart';

class BarcodeLookupResponse {
  final String barcode;
  final bool found;
  final ScannedFood? food;

  const BarcodeLookupResponse({
    required this.barcode,
    required this.found,
    this.food,
  });

  factory BarcodeLookupResponse.fromJson(Map<String, dynamic> json) {
    final foodJson = json['food'];
    return BarcodeLookupResponse(
      barcode: json['barcode']?.toString() ?? '',
      found: json['found'] == true,
      food: foodJson is Map<String, dynamic>
          ? ScannedFood.fromJson(foodJson)
          : null,
    );
  }
}
