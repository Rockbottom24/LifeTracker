import '../models/meal_response.dart';
import '../models/meal_type.dart';
import '../navigation/fade_slide_page_route.dart';
import '../screens/add_meal_screen.dart';

class AddMealPageRoute extends FadeSlidePageRoute<void> {
  AddMealPageRoute({
    required super.settings,
    this.meal,
    this.initialMealType,
  }) : super(page: AddMealScreen(meal: meal, initialMealType: initialMealType));

  final MealResponse? meal;
  final MealType? initialMealType;
}
