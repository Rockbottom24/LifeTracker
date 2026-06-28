enum ServingUnit {
  gram('GRAM', 'Gram'),
  ml('ML', 'Milliliter'),
  piece('PIECE', 'Piece'),
  tablespoon('TABLESPOON', 'Tablespoon'),
  teaspoon('TEASPOON', 'Teaspoon'),
  cup('CUP', 'Cup'),
  scoop('SCOOP', 'Scoop');

  const ServingUnit(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static ServingUnit fromApiValue(String? value) {
    return ServingUnit.values.firstWhere(
      (item) => item.apiValue == value,
      orElse: () => ServingUnit.gram,
    );
  }
}
