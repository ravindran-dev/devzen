import 'dart:io';
import 'package:dio/dio.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  /// Login with GitHub email + password. Returns JWT token on success.
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _api.postForm('/auth/login', {
        'username': email,
        'password': password,
      });
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Login failed. Check credentials.';
      throw Exception(msg);
    }
  }

  /// Register with full_name, email, password, github_username, and resume file.
  /// Returns RegisterResponse with token + user info.
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    required String githubUsername,
    required File resumeFile,
  }) async {
    try {
      final formData = FormData.fromMap({
        'full_name': fullName,
        'email': email,
        'password': password,
        'confirm_password': confirmPassword,
        'github_username': githubUsername,
        'resume': await MultipartFile.fromFile(
          resumeFile.path,
          filename: resumeFile.path.split('/').last.split('\\').last,
        ),
      });
      final response = await _api.postMultipart('/auth/register', formData);
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? 'Registration failed.';
      throw Exception(msg);
    }
  }

  /// Get current authenticated user info
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _api.get('/auth/me');
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to get user info');
    }
  }

  Future<void> saveToken(String token) => _api.saveToken(token);
  Future<String?> getStoredToken() => _api.getToken();
  Future<void> clearToken() => _api.clearToken();
}
