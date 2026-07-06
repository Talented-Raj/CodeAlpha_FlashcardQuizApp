class AppConstants {
  AppConstants._();

  // App Name
  static const String appName = 'Flashcard Quiz App';

  // Database Configurations
  static const String dbName = 'flashcard_quiz.db';
  static const int dbVersion = 3;

  // Shared Preferences Keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyIsOnboarded = 'is_onboarded';
  static const String keyUserCurrency = 'user_currency';
  static const String keyUserName = 'user_name';
  static const String keyUserEmail = 'user_email';
  static const String keyMonthlyBudget = 'monthly_budget';

  // Default Values
  static const String defaultCurrency = '$';
  static const double defaultBudget = 1000.0;

  // Design Guidelines
  static const double paddingNone = 0.0;
  static const double paddingXS = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXL = 32.0;

  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusCircular = 99.0;

  static const int animationDurationMs = 300;
  static const int splashDelaySec = 3;
}
