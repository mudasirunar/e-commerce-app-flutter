import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../utils/app_config.dart';
import '../auth/auth_service.dart';
import 'api_exception.dart';

/// Shared HTTPS client communicating with the remote Vercel serverless backend.
class ApiClient {
  final http.Client _client;
  final AuthService? _authService;
  final String _baseUrl;

  ApiClient({
    http.Client? client,
    this._authService,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.backendBaseUrl;

  /// Executes an authenticated or unauthenticated POST request.
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth && _authService != null) {
      final token = await _authService.getIdToken();
      if (token == null) {
        throw const ApiException(
          message: 'User session has expired. Please log in again.',
          statusCode: 401,
        );
      }
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await _client
          .post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));

      return _processResponse(response);
    } on SocketException catch (_) {
      throw const ApiException(
        message: 'Network error. Please check your internet connection.',
        statusCode: 0,
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        message: 'Connection failed: ${e.message}',
        statusCode: 0,
      );
    }
  }

  /// Executes an authenticated or unauthenticated GET request.
  Future<Map<String, dynamic>> get(
    String endpoint, {
    bool requiresAuth = false,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (requiresAuth && _authService != null) {
      final token = await _authService.getIdToken();
      if (token == null) {
        throw const ApiException(
          message: 'User session has expired. Please log in again.',
          statusCode: 401,
        );
      }
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      return _processResponse(response);
    } on SocketException catch (_) {
      throw const ApiException(
        message: 'Network error. Please check your internet connection.',
        statusCode: 0,
      );
    }
  }

  Map<String, dynamic> _processResponse(http.Response response) {
    Map<String, dynamic> data = {};
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (_) {
        // Fallback for non-JSON responses
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    final errorMessage = data['error'] as String? ??
        data['message'] as String? ??
        'Request failed with status ${response.statusCode}.';

    throw ApiException(
      message: errorMessage,
      statusCode: response.statusCode,
      data: data,
    );
  }
}
