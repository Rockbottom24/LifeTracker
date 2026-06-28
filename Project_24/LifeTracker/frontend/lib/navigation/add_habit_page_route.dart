import '../models/habit_response.dart';
import '../navigation/fade_slide_page_route.dart';
import '../screens/add_habit_screen.dart';

class AddHabitPageRoute extends FadeSlidePageRoute<void> {
  AddHabitPageRoute({
    required super.settings,
    this.habit,
  }) : super(page: AddHabitScreen(habit: habit));

  final HabitResponse? habit;
}
