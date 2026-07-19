import 'package:http/http.dart' as http;
import 'dart:convert';

const String baseUrl = 'https://campride-production.up.railway.app/api/v1';

class ApiResponse<T> {
  final bool success;
  final String? error;
  final T? data;

  ApiResponse({required this.success, this.error, this.data});
}

class DriverService {
  /// End the driver's current trip and remove them from live tracking
  /// Calls POST /api/v1/driver/offline
  Future<ApiResponse<Map<String, dynamic>>> endTrip({
    required String accessToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/driver/offline'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: data,
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          error: 'Failed to end trip: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: 'Error ending trip: $e',
      );
    }
  }
}
