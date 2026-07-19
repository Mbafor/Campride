/// Centralized API configuration for the CampRide app
class ApiConfig {
  /// Base HTTP URL for REST API endpoints
  static const String baseHttpUrl = 'https://campride-production.up.railway.app/api/v1';

  /// Base WebSocket URL for real-time connections
  /// Note: Must use wss:// (secure WebSocket) for HTTPS connections
  static const String baseWsUrl = 'wss://campride-production.up.railway.app/api/v1';

  // Individual endpoint URLs can be constructed using these constants
  // Example: '$baseHttpUrl/auth/login'
}
