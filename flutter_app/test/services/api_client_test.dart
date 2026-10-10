import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ecommerceapp/services/api/api_client.dart';
import 'package:ecommerceapp/services/api/api_exception.dart';
import 'package:ecommerceapp/services/auth/auth_service.dart';

class MockAuthService extends AuthService {
  final String? mockToken;
  MockAuthService([this.mockToken = 'test-token-123']);

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async => mockToken;
}

void main() {
  group('ApiClient', () {
    test('attaches Authorization header for authenticated requests', () async {
      String? recordedAuthHeader;

      final mockClient = MockClient((request) async {
        recordedAuthHeader = request.headers['Authorization'];
        return http.Response(jsonEncode({'success': true}), 200);
      });

      final authService = MockAuthService('my-firebase-id-token');
      final apiClient = ApiClient(
        client: mockClient,
        authService: authService,
        baseUrl: 'https://example.com',
      );

      final result = await apiClient.post('/api/test', body: {'foo': 'bar'});
      expect(result['success'], isTrue);
      expect(recordedAuthHeader, 'Bearer my-firebase-id-token');
    });

    test('throws structured ApiException on 400 Bad Request', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': 'Invalid verification code.',
            'attemptsLeft': 3,
          }),
          400,
        );
      });

      final apiClient = ApiClient(
        client: mockClient,
        baseUrl: 'https://example.com',
      );

      try {
        await apiClient.post('/api/auth/verify-otp', body: {'otp': '000000'}, requiresAuth: false);
        fail('Should throw ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 400);
        expect(e.message, 'Invalid verification code.');
        expect(e.attemptsLeft, 3);
        expect(e.isBadRequest, isTrue);
      }
    });

    test('throws 401 when user session token is missing', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{}', 200);
      });

      final authService = MockAuthService(null); // No token (logged out)
      final apiClient = ApiClient(
        client: mockClient,
        authService: authService,
        baseUrl: 'https://example.com',
      );

      expect(
        () => apiClient.post('/api/orders/checkout', requiresAuth: true),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );
    });
  });
}
