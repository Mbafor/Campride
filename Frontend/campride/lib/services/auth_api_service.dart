import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/user_model.dart';
import '../config/api_config.dart';

String _guessImageContentType(String filename) {
  final ext = filename.split('.').last.toLowerCase();
  switch (ext) {
    case 'png':
      return 'image/png';
    case 'heic':
      return 'image/heic';
    case 'webp':
      return 'image/webp';
    case 'jpg':
    case 'jpeg':
    default:
      return 'image/jpeg';
  }
}

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
        Uri.parse('${ApiConfig.baseHttpUrl}/auth/register'),
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
          phoneNumber: json['phone_number'],
          gender: json['gender'],
          photoUrl: json['photo_url'],
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
        Uri.parse('${ApiConfig.baseHttpUrl}/auth/verify-email'),
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
        Uri.parse('${ApiConfig.baseHttpUrl}/auth/resend-verification'),
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

  // Request a password reset code be sent to the given email
  Future<AuthApiResponse<void>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseHttpUrl}/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        return AuthApiResponse(success: true);
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final error = _extractErrorDetail(json);
        return AuthApiResponse(
          success: false,
          message: error['message'] ?? 'Failed to send reset code',
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

  // Verify a password reset code; on success returns a short-lived reset token
  Future<AuthApiResponse<String>> verifyResetCode({
    required String email,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseHttpUrl}/auth/verify-reset-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return AuthApiResponse(success: true, data: json['reset_token'] as String);
      } else {
        final error = _extractErrorDetail(json);
        return AuthApiResponse(
          success: false,
          message: error['message'] ?? 'Invalid or expired code',
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

  // Set a new password using the reset token from verifyResetCode
  Future<AuthApiResponse<void>> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseHttpUrl}/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'reset_token': resetToken, 'new_password': newPassword}),
      );

      if (response.statusCode == 200) {
        return AuthApiResponse(success: true);
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final error = _extractErrorDetail(json);
        return AuthApiResponse(
          success: false,
          message: error['message'] ?? 'Failed to reset password',
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
        Uri.parse('${ApiConfig.baseHttpUrl}/auth/login'),
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
        Uri.parse('${ApiConfig.baseHttpUrl}/auth/refresh'),
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
        Uri.parse('${ApiConfig.baseHttpUrl}/auth/me'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final user = UserModel(
          id: json['id'] ?? '',
          name: json['name'] ?? '',
          email: json['email'] ?? '',
          role: json['role'] ?? 'student',
          phoneNumber: json['phone_number'],
          gender: json['gender'],
          photoUrl: json['photo_url'],
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

  // Update the current user's profile (name, gender, phone, email)
  Future<AuthApiResponse<UserModel>> updateProfile({
    required String accessToken,
    String? name,
    String? gender,
    String? phoneNumber,
    String? email,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (gender != null) body['gender'] = gender;
      if (phoneNumber != null) body['phone_number'] = phoneNumber;
      if (email != null) body['email'] = email;

      if (body.isEmpty) {
        return AuthApiResponse(success: false, message: 'Nothing to update');
      }

      final response = await http.put(
        Uri.parse('${ApiConfig.baseHttpUrl}/users/me'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final user = UserModel(
          id: json['id'] ?? '',
          name: json['name'] ?? '',
          email: json['email'] ?? '',
          role: json['role'] ?? 'student',
          phoneNumber: json['phone_number'],
          gender: json['gender'],
          photoUrl: json['photo_url'],
        );
        return AuthApiResponse(success: true, data: user);
      } else {
        final error = _extractErrorDetail(json);
        return AuthApiResponse(
          success: false,
          message: error['message'] ?? 'Failed to update profile',
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

  // Upload/replace the current user's profile photo
  Future<AuthApiResponse<UserModel>> updateProfilePhoto({
    required String accessToken,
    required List<int> bytes,
    required String filename,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseHttpUrl}/users/me/photo'),
      )
        ..headers['Authorization'] = 'Bearer $accessToken'
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: MediaType.parse(_guessImageContentType(filename)),
        ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final user = UserModel(
          id: json['id'] ?? '',
          name: json['name'] ?? '',
          email: json['email'] ?? '',
          role: json['role'] ?? 'student',
          photoUrl: json['photo_url'],
        );
        return AuthApiResponse(success: true, data: user);
      } else {
        final error = _extractErrorDetail(json);
        return AuthApiResponse(
          success: false,
          message: error['message'] ?? 'Failed to update photo',
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
        Uri.parse('${ApiConfig.baseHttpUrl}/auth/google'),
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
