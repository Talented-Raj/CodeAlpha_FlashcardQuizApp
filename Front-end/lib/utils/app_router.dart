import 'package:flutter/material.dart';
import '../animations/custom_page_route.dart';
import '../models/flashcard_model.dart';
import '../screens/splash_screen.dart';
import '../screens/home_screen.dart';
import '../screens/study_screen.dart';
import '../screens/add_edit_card_screen.dart';
import '../screens/search_screen.dart';
import '../screens/statistics_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/live_quiz_setup_screen.dart';
import '../screens/live_quiz_lobby_screen.dart';
import '../screens/live_quiz_play_screen.dart';

class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String home = '/home';
  static const String study = '/study';
  static const String addEditCard = '/add-edit-card';
  static const String search = '/search';
  static const String statistics = '/statistics';
  static const String settingsRoute = '/settings';
  static const String liveQuizSetup = '/live-quiz-setup';
  static const String liveQuizLobby = '/live-quiz-lobby';
  static const String liveQuizPlay = '/live-quiz-play';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case home:
        return CustomPageRoute(child: const HomeScreen());
      case study:
        final category = settings.arguments as String? ?? 'All Decks';
        return CustomPageRoute(child: StudyScreen(category: category));
      case addEditCard:
        final card = settings.arguments as FlashcardModel?;
        return CustomPageRoute(child: AddEditCardScreen(card: card));
      case search:
        return CustomPageRoute(child: const SearchScreen());
      case statistics:
        return CustomPageRoute(child: const StatisticsScreen());
      case settingsRoute:
        return CustomPageRoute(child: const SettingsScreen());
      case liveQuizSetup:
        return CustomPageRoute(child: const LiveQuizSetupScreen());
      case liveQuizLobby:
        return CustomPageRoute(child: const LiveQuizLobbyScreen());
      case liveQuizPlay:
        return CustomPageRoute(child: const LiveQuizPlayScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
