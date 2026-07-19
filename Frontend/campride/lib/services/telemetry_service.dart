import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_config.dart';

class TelemetryService {
  WebSocketChannel? _channel;
  Timer? _locationUpdateTimer;
  bool _isConnected = false;

  // Callbacks for UI updates
  Function(String)? onError;
  Function()? onConnected;
  Function()? onDisconnected;

  /// Request location permission and check if enabled
  Future<bool> requestLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        final result = await Geolocator.requestPermission();
        return result == LocationPermission.whileInUse || result == LocationPermission.always;
      } else if (permission == LocationPermission.deniedForever) {
        onError?.call('Location permission denied permanently. Please enable it in app settings.');
        return false;
      }

      return permission == LocationPermission.whileInUse || permission == LocationPermission.always;
    } catch (e) {
      onError?.call('Failed to request location permission: $e');
      return false;
    }
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Connect to telemetry WebSocket and start sending location updates
  Future<bool> startTelemetry(String accessToken) async {
    try {
      // Check location services
      if (!await isLocationServiceEnabled()) {
        onError?.call('Location services are disabled. Please enable them.');
        return false;
      }

      // Request permission
      if (!await requestLocationPermission()) {
        onError?.call('Location permission is required to share your position.');
        return false;
      }

      // Connect to WebSocket
      final wsUrl = Uri.parse('${ApiConfig.baseWsUrl}/api/v1/ws/driver/telemetry?token=$accessToken');
      _channel = WebSocketChannel.connect(wsUrl);

      // Listen for connection messages
      _channel!.stream.listen(
        (message) {
          final data = jsonDecode(message);
          print('[Telemetry] Received: ${data['status']}');
        },
        onError: (error) {
          print('[Telemetry] WebSocket error: $error');
          onError?.call('Connection error: $error');
          _isConnected = false;
          onDisconnected?.call();
        },
        onDone: () {
          print('[Telemetry] WebSocket closed');
          _isConnected = false;
          onDisconnected?.call();
        },
      );

      _isConnected = true;
      onConnected?.call();

      // Start sending location updates every 5 seconds
      _startLocationUpdateTimer();

      return true;
    } catch (e) {
      onError?.call('Failed to connect: $e');
      return false;
    }
  }

  /// Stop sending telemetry and close WebSocket
  void stopTelemetry() {
    _locationUpdateTimer?.cancel();
    _channel?.sink.close();
    _isConnected = false;
    onDisconnected?.call();
  }

  /// Send current location to backend
  Future<void> _sendLocationUpdate() async {
    if (!_isConnected || _channel == null) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 10),
      );

      final timestamp = DateTime.now().toUtc().toIso8601String();

      final locationData = {
        'lat': position.latitude,
        'lng': position.longitude,
        'heading': position.heading,
        'accuracy': position.accuracy,
        'timestamp': timestamp,
      };

      _channel!.sink.add(jsonEncode(locationData));

      print('[Telemetry] Sent location: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('[Telemetry] Error sending location: $e');
      onError?.call('Failed to get location: $e');
    }
  }

  /// Start periodic location updates
  void _startLocationUpdateTimer() {
    _locationUpdateTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _sendLocationUpdate(),
    );

    // Send first update immediately
    _sendLocationUpdate();
  }

  bool get isConnected => _isConnected;
}
