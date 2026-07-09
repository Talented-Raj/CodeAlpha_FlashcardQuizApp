import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // Theme Mode Settings
  String getThemeMode() {
    return _prefs.getString(AppConstants.keyThemeMode) ?? 'system';
  }

  Future<bool> setThemeMode(String value) async {
    return await _prefs.setString(AppConstants.keyThemeMode, value);
  }

  // Onboarding Settings
  bool isOnboarded() {
    return _prefs.getBool(AppConstants.keyIsOnboarded) ?? false;
  }

  Future<bool> setOnboarded(bool value) async {
    return await _prefs.setBool(AppConstants.keyIsOnboarded, value);
  }

  // User Currency Settings
  String getCurrency() {
    return _prefs.getString(AppConstants.keyUserCurrency) ?? AppConstants.defaultCurrency;
  }

  Future<bool> setCurrency(String value) async {
    return await _prefs.setString(AppConstants.keyUserCurrency, value);
  }

  // User Profile Name
  String getUserName() {
    return _prefs.getString(AppConstants.keyUserName) ?? '';
  }

  Future<bool> setUserName(String value) async {
    return await _prefs.setString(AppConstants.keyUserName, value);
  }

  // User Profile Email
  String getUserEmail() {
    return _prefs.getString(AppConstants.keyUserEmail) ?? '';
  }

  Future<bool> setUserEmail(String value) async {
    return await _prefs.setString(AppConstants.keyUserEmail, value);
  }

  // Monthly Budget Limit Setting
  double getMonthlyBudget() {
    return _prefs.getDouble(AppConstants.keyMonthlyBudget) ?? AppConstants.defaultBudget;
  }

  Future<bool> setMonthlyBudget(double value) async {
    return await _prefs.setDouble(AppConstants.keyMonthlyBudget, value);
  }

  // Flashcard Deck Position Memory
  int getLastStudiedIndex(String category) {
    return _prefs.getInt('deck_pos_$category') ?? 0;
  }

  Future<bool> setLastStudiedIndex(String category, int index) async {
    return await _prefs.setInt('deck_pos_$category', index);
  }

  // Clear All Settings
  Future<bool> clearAll() async {
    return await _prefs.clear();
  }

  // Clear specific flashcard position caches
  Future<void> clearStudyPositions() async {
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('deck_pos_')) {
        await _prefs.remove(key);
      }
    }
  }
}
