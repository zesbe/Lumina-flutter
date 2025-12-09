import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = true;
  bool _isAuthenticated = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  AuthProvider() {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final token = await ApiService.getToken();
      if (token != null) {
        final data = await ApiService.getProfile();
        _user = User.fromJson(data['user']);
        _isAuthenticated = true;
      }
    } catch (e) {
      await ApiService.clearTokens();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final data = await ApiService.login(email, password);
    await ApiService.setTokens(
      data['tokens']['access_token'],
      data['tokens']['refresh_token'],
    );
    _user = User.fromJson(data['user']);
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> register(String name, String email, String password) async {
    await ApiService.register(name, email, password);
    await login(email, password);
  }

  Future<void> logout() async {
    await ApiService.clearTokens();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
