import 'package:flutter/material.dart';
import '../../screens/splash_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/study_screen.dart';
import '../../screens/add_edit_card_screen.dart';
import '../../screens/search_screen.dart';
import '../../screens/statistics_screen.dart';
import '../../screens/settings_screen.dart';
import '../models/flashcard_model.dart';

class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String hub = '/hub';
  static const String home = '/home';
  static const String study = '/study';
  static const String addEditCard = '/add-edit-card';
  static const String search = '/search';
  static const String statistics = '/statistics';
  static const String settingsRoute = '/settings';
  static const String onboarding = '/onboarding';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case hub:
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case study:
        final category = settings.arguments as String? ?? 'All Decks';
        return MaterialPageRoute(builder: (_) => StudyScreen(category: category));
      case addEditCard:
        final card = settings.arguments as FlashcardModel?;
        return MaterialPageRoute(builder: (_) => AddEditCardScreen(card: card));
      case search:
        return MaterialPageRoute(builder: (_) => const SearchScreen());
      case statistics:
        return MaterialPageRoute(builder: (_) => const StatisticsScreen());
      case settingsRoute:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case onboarding:
        // For Milestone 1, let's redirect to navigation hub or create a simple placeholder onboarding
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Onboarding Screen')),
          ),
        );
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
