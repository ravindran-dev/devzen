import 'dart:io';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// AuthProvider — No hardcoded data. All from backend API.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String _errorMessage = '';

  // User data from backend — all real
  int _userId = 0;
  String _email = '';
  String _fullName = '';
  String _githubUsername = '';
  bool _isActive = true;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  int get userId => _userId;
  String get email => _email;
  String get fullName => _fullName;
  String get githubUsername => _githubUsername;
  bool get isActive => _isActive;

  /// Called on app startup — restores auth session from stored token
  Future<void> initializeAuth() async {
    final token = await _authService.getStoredToken();
    if (token != null) {
      try {
        final userData = await _authService.getCurrentUser();
        _setUserFromData(userData);
        _isAuthenticated = true;
      } catch (_) {
        await _authService.clearToken();
        _isAuthenticated = false;
      }
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final data = await _authService.login(email, password);
      final token = data['access_token'] as String;
      await _authService.saveToken(token);

      final userData = await _authService.getCurrentUser();
      _setUserFromData(userData);
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    required String githubUsername,
    required File resumeFile,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final data = await _authService.register(
        fullName: fullName,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        githubUsername: githubUsername,
        resumeFile: resumeFile,
      );
      final token = data['access_token'] as String;
      await _authService.saveToken(token);

      final user = data['user'] as Map<String, dynamic>;
      _setUserFromData(user);
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isAuthenticated = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.clearToken();
    _isAuthenticated = false;
    _userId = 0;
    _email = '';
    _fullName = '';
    _githubUsername = '';
    notifyListeners();
  }

  void _setUserFromData(Map<String, dynamic> data) {
    _userId = data['id'] ?? 0;
    _email = data['email'] ?? '';
    _fullName = data['full_name'] ?? data['email']?.toString().split('@').first ?? '';
    _githubUsername = data['github_username'] ?? '';
    _isActive = data['is_active'] ?? true;
  }
}
