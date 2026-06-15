import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Central HTTP client for all DevZen API calls.
/// Automatically injects JWT Bearer token on every authenticated request.
class ApiService {
  static final String _baseUrl = _determineBaseUrl();

  static String _determineBaseUrl() {
    // Use localhost:8000 for all platforms. 
    // Note: For Android (emulator or physical device), run `adb reverse tcp:8000 tcp:8000`
    // to forward the device's port 8000 requests to your local host machine.
    return 'http://localhost:8000/api/v1';
  }

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    // Interceptor: inject token on every request
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        // Log errors but don't throw — callers handle their own errors
        return handler.next(e);
      },
    ));
  }

  // ─── Token Management ────────────────────────────────────────────────────

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'auth_token');
  }

  // ─── HTTP Methods ─────────────────────────────────────────────────────────

  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) async {
    return await _dio.get(path, queryParameters: queryParams);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }

  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }

  /// Multipart form data — for file uploads (resume registration, profile update)
  Future<Response> postMultipart(String path, FormData formData) async {
    return await _dio.post(
      path,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  /// Login with form encoding (OAuth2PasswordRequestForm format)
  Future<Response> postForm(String path, Map<String, String> fields) async {
    return await _dio.post(
      path,
      data: fields,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }
}
