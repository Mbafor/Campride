import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

// TODO: Change this to production backend URL when deploying
const String baseUrl = 'http://127.0.0.1:8000/api/v1';

Map<String, dynamic> _extractErrorDetail(Map<String, dynamic> json) {
  if (json.containsKey('detail') && json['detail'] is Map) {
    return json['detail'] as Map<String, dynamic>;
  }
  return json;
}

class AuthApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? errorCode;

  AuthApiResponse({
    required this.success,
    this.data,
    this.message,
    this.errorCode,
  });
}

class AuthApiService {
  // Register a new user with email/password
  Future<AuthApiResponse<UserModel>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': 'student',
        }),
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final user = UserModel(
          id: json['id'] ?? '',
          name: json['name'] ?? '',
          email: json['email'] ?? '',
          role: json['role'] ?? 'student',
        );
        return AuthApiResponse(success: true, data: user);
      } else {
        final error = _extractErrorDetail(json);
        return AuthApiResponse(
          success: false,
          message: error['message'] ?? 'Registration failed',
          errorCode: error['error_code'] ?? 'UNKNOWN',
        );
      }
    } catch (e) {
      return AuthApiResponse(
        success: false,
        message: 'Network error: $e',
        errorCode: 'NETWORK_ERROR',
      );
    }
  }

  // Verify email with 6-digit code
  Future<AuthApiResponse<void>> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
        }),
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return AuthApiResponse(success: true);
      } else {
        final error = _extractErrorDetail(json);
        return AuthApiResponse(
          success: false,
          message: error['message'] ?? 'Verification failed',
          errorCode: error['error_code'] ?? 'UNKNOWN',
        );
      }
    } catch (e) {
      return AuthApiResponse(
        success: false,
        message: 'Network error: $e',
        errorCode: 'NETWORK_ERROR',
      );
    }
  }

  // Resend verification email
  Future<AuthApiResponse<void>> resendVerification({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/resend-verification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return AuthApiResponse(success: true);
      } else {
        final error = _extractErrorDetail(json);
        return AuthApiResponse(
          success: false,
          message: error['message'] ?? 'Resend failed',
          errorCode: error['error_code'] ?? 'UNKNOWN',
        );
      }
    } catch (e) {
      return AuthApiResponse(
        success: false,
        message: 'Network error: $e',
        errorCode: 'NETWORK_ERROR',
      );
    }
  }

  // Login with email/password
  Future<AuthApiResponse<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return AuthApiResponse(
          success: true,
          data: {
            'access_token': json['access_token'] ?? '',
            'refresh_token': json['refresh_token'] ?? '',
            'token_type': json['token_type'] ?? 'bearer',
          },
        );
      } else {
        final error = _extractErrorDetail(json);
        return AuthApiResponse(
          success: false,
          message: error['message'] ?? 'Login failed',
          errorCode: error['error_code'] ?? 'UNKNOWN',
        );
      }
    } catch (e) {
      return AuthApiResponse(
        success: false,
        message: 'Network error: $e',
        errorCode: 'NETWORK_ERROR',
      );
    }
  }

  // Refresh access token using refresh token
  Future<AuthApiResponse<Map<String, dynamic>>> refreshToken({
    required String refreshToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return AuthApiResponse(
          success: true,
          data: {
            'access_token': json['access_token'] ?? '',
            'refresh_token': json['refresh_token'] ?? '',
            'token_type': json['token_type'] ?? 'bearer',
          },
        );
      } else {
        final error = _extractErrorDetail(json);
        return AuthApiResponse(
          success: false,
          message: error['message'] ?? 'Token refresh failed',
          errorCode: error['error_code'] ?? 'UNKNOWN',
        );
      }
    } catch (e) {
      return AuthApiResponse(
        success: false,
        message: 'Network error: $e',
        errorCode: 'NETWORK_ERROR',
      );
    }
  }

  // Get current user info
  Future<AuthApiResponse<UserModel>> getCurrentUser({
    required String accessToken,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final user = UserModel(
          id: json['id'] ?? '',
          name: json['name'] ?? '',
          email: json['email'] ?? '',
          role: json['role'] ?? 'student',
        );
        return AuthApiResponse(success: true, data: user);
      } else {
        final error = _extractErrorDetail(json);
        return AuthApiResponse(
          success: false,
          message: error['message'] ?? 'Failed to get user info',
          errorCode: error['error_code'] ?? 'UNKNOWN',
        );
      }
    } catch (e) {
      return AuthApiResponse(
        success: false,
        message: 'Network error: $e',
        errorCode: 'NETWORK_ERROR',
      );
    }
  }

  // Google Sign-In
  Future<AuthApiResponse<Map<String, dynamic>>> googleSignIn({
    required String idToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_token': idToken}),
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return AuthApiResponse(
          success: true,
          data: {
            'access_token': json['access_token'] ?? '',
            'refresh_token': json['refresh_token'] ?? '',
            'token_type': json['token_type'] ?? 'bearer',
          },
        );
      } else {
        final error = _extractErrorDetail(json);
        return AuthApiResponse(
          success: false,
          message: error['message'] ?? 'Google sign-in failed',
          errorCode: error['error_code'] ?? 'UNKNOWN',
        );
      }
    } catch (e) {
      return AuthApiResponse(
        success: false,
        message: 'Network error: $e',
        errorCode: 'NETWORK_ERROR',
      );
    }
  }
}
