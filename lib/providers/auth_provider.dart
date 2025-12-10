import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = true;
  bool _isAuthenticated = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;

  AuthProvider() {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final token = await ApiService.getToken();
      debugPrint('[Auth] Token found: ${token != null}');
      
      if (token != null && token.isNotEmpty) {
        try {
          final data = await ApiService.getProfile();
          if (data['user'] != null) {
            _user = User.fromJson(data['user']);
            _isAuthenticated = true;
            debugPrint('[Auth] User restored: ${_user?.name}');
          } else {
            // Token invalid, clear it
            debugPrint('[Auth] Invalid user data, clearing tokens');
            await ApiService.clearTokens();
            _isAuthenticated = false;
          }
        } catch (e) {
          // Profile fetch failed, but don't clear token immediately
          // Could be network issue
          debugPrint('[Auth] Profile fetch failed: $e');
          // Keep token, mark as not authenticated for now
          _isAuthenticated = false;
          _error = 'Gagal memuat profil. Coba lagi.';
        }
      } else {
        _isAuthenticated = false;
      }
    } catch (e) {
      debugPrint('[Auth] Check auth error: $e');
      _isAuthenticated = false;
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> retryAuth() async {
    _error = null;
    await _checkAuth();
  }

  Future<bool> login(String email, String password) async {
    _error = null;
    try {
      final data = await ApiService.login(email, password);
      
      // Save tokens
      final accessToken = data['tokens']?['access_token'];
      final refreshToken = data['tokens']?['refresh_token'];
      
      if (accessToken == null) {
        throw Exception('Token tidak ditemukan');
      }
      
      await ApiService.setTokens(accessToken, refreshToken ?? '');
      debugPrint('[Auth] Tokens saved');
      
      // Get user
      if (data['user'] != null) {
        _user = User.fromJson(data['user']);
      } else {
        // Fetch profile if not in response
        final profile = await ApiService.getProfile();
        _user = User.fromJson(profile['user']);
      }
      
      _isAuthenticated = true;
      notifyListeners();
      debugPrint('[Auth] Login success: ${_user?.name}');
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      debugPrint('[Auth] Login failed: $e');
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _error = null;
    try {
      await ApiService.register(name, email, password);
      return await login(email, password);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await ApiService.clearTokens();
    _user = null;
    _isAuthenticated = false;
    _error = null;
    notifyListeners();
    debugPrint('[Auth] Logged out');
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
