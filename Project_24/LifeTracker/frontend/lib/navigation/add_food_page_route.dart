import '../models/food_response.dart';
import '../navigation/fade_slide_page_route.dart';
import '../screens/add_food_screen.dart';

class AddFoodPageRoute extends FadeSlidePageRoute<void> {
  AddFoodPageRoute({
    required super.settings,
    this.food,
    this.initialName,
  }) : super(page: AddFoodScreen(food: food, initialName: initialName));

  final FoodResponse? food;
  final String? initialName;
}
