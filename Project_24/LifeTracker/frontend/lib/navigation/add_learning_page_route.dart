import '../models/learning_session_response.dart';
import '../navigation/fade_slide_page_route.dart';
import '../screens/add_learning_screen.dart';

class AddLearningPageRoute extends FadeSlidePageRoute<void> {
  AddLearningPageRoute({
    required super.settings,
    this.session,
  }) : super(page: AddLearningScreen(session: session));

  final LearningSessionResponse? session;
}
