enum ServingUnit {
  gram('GRAM', 'Gram'),
  kilogram('KILOGRAM', 'Kilogram'),
  ml('ML', 'Milliliter'),
  liter('LITER', 'Liter'),
  piece('PIECE', 'Piece'),
  tablespoon('TABLESPOON', 'Tablespoon'),
  teaspoon('TEASPOON', 'Teaspoon'),
  cup('CUP', 'Cup'),
  scoop('SCOOP', 'Scoop'),
  serving('SERVING', 'Serving');

  const ServingUnit(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static ServingUnit fromApiValue(String? value) {
    return ServingUnit.values.firstWhere(
      (item) => item.apiValue == value,
      orElse: () => ServingUnit.gram,
    );
  }

  static ServingUnit? tryFromApiValue(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final item in ServingUnit.values) {
      if (item.apiValue == value) return item;
    }
    return null;
  }
}
