import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final StorageService _storageService;
  UserModel? _user;
  bool _isOnboarded = false;

  AuthProvider(this._storageService) {
    _loadUserData();
  }

  UserModel? get user => _user;
  bool get isOnboarded => _isOnboarded;
  bool get isAuthenticated => _user != null && _isOnboarded;

  void _loadUserData() {
    _isOnboarded = _storageService.isOnboarded();
    final name = _storageService.getUserName();
    final email = _storageService.getUserEmail();
    final currency = _storageService.getCurrency();
    final budget = _storageService.getMonthlyBudget();

    if (name.isNotEmpty) {
      _user = UserModel(
        name: name,
        email: email,
        currency: currency,
        monthlyBudget: budget,
      );
    }
    notifyListeners();
  }

  Future<void> completeOnboarding({
    required String name,
    required String email,
    required String currency,
    required double monthlyBudget,
  }) async {
    await _storageService.setOnboarded(true);
    await _storageService.setUserName(name);
    await _storageService.setUserEmail(email);
    await _storageService.setCurrency(currency);
    await _storageService.setMonthlyBudget(monthlyBudget);

    _isOnboarded = true;
    _user = UserModel(
      name: name,
      email: email,
      currency: currency,
      monthlyBudget: monthlyBudget,
    );
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? currency,
    double? monthlyBudget,
  }) async {
    if (_user == null) return;

    if (name != null) await _storageService.setUserName(name);
    if (email != null) await _storageService.setUserEmail(email);
    if (currency != null) await _storageService.setCurrency(currency);
    if (monthlyBudget != null) await _storageService.setMonthlyBudget(monthlyBudget);

    _user = _user!.copyWith(
      name: name,
      email: email,
      currency: currency,
      monthlyBudget: monthlyBudget,
    );
    notifyListeners();
  }

  Future<void> resetUser() async {
    await _storageService.clearAll();
    _user = null;
    _isOnboarded = false;
    notifyListeners();
  }
}
