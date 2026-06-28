enum FoodCategory {
  grains('GRAINS', 'Grains'),
  vegetables('VEGETABLES', 'Vegetables'),
  fruits('FRUITS', 'Fruits'),
  meat('MEAT', 'Meat'),
  seafood('SEAFOOD', 'Seafood'),
  eggs('EGGS', 'Eggs'),
  dairy('DAIRY', 'Dairy'),
  legumes('LEGUMES', 'Legumes'),
  nuts('NUTS', 'Nuts'),
  seeds('SEEDS', 'Seeds'),
  oils('OILS', 'Oils'),
  beverages('BEVERAGES', 'Beverages'),
  supplements('SUPPLEMENTS', 'Supplements'),
  snacks('SNACKS', 'Snacks'),
  other('OTHER', 'Other');

  const FoodCategory(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static FoodCategory fromApiValue(String? value) {
    return FoodCategory.values.firstWhere(
      (item) => item.apiValue == value,
      orElse: () => FoodCategory.other,
    );
  }
}
