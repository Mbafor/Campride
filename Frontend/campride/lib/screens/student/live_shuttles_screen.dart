import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../providers/authentication_provider.dart';
import '../../theme/app_colors.dart';

class LiveShuttlesScreen extends StatefulWidget {
  final String? matchedShuttleId;
  final int? etaMinutes;

  const LiveShuttlesScreen({super.key, this.matchedShuttleId, this.etaMinutes});

  @override
  State<LiveShuttlesScreen> createState() => _LiveShuttlesScreenState();
}

class _LiveShuttlesScreenState extends State<LiveShuttlesScreen> {
  WebSocketChannel? _channel;
  Map<String, ShuttleData> _shuttles = {};
  bool _isConnected = false;
  String? _errorMessage;

  // Shuttle lookup: driver_id -> (shuttle_name, plate_number)
  Map<String, Map<String, String>> _shuttleLookup = {};

  // Track which shuttle was just updated for pulse animation
  final Set<String> _pulsingShuttles = {};

  // Google Maps controller
  GoogleMapController? _mapController;

  // Markers on map: driver_id -> Marker
  Map<String, Marker> _markers = {};

// Matched shuttle info for floating card
  String? _matchedShuttleName;
  String? _matchedShuttleEta;

  // User's current location (for the blue blip on the map)
  LatLng? _userLocation;
  bool _isGettingLocation = false;
  String? _locationError;

  // Custom user-location blip marker
  Marker? _userLocationMarker;

  // KNUST campus center coordinates
  static const LatLng _knustCenter = LatLng(6.7041, -1.5637);

  @override
  void initState() {
    super.initState();
    print('[LiveMap] ===== SCREEN INITSTATE CALLED =====');
    print('[LiveMap] matchedShuttleId: ${widget.matchedShuttleId}');
    print('[LiveMap] etaMinutes: ${widget.etaMinutes}');
    print('[LiveMap] Screen is mounting, about to connect to WebSocket');
    _loadShuttleLookup();
    _connectToLiveMap();
    _getUserLocation();
  }

  // ── User location (blip) ──────────────────────────────────────────────────
  Future<void> _getUserLocation() async {
    if (_isGettingLocation) return;
    setState(() {
      _isGettingLocation = true;
      _locationError = null;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('[LiveMap] Location services are disabled');
        if (mounted) {
          setState(() {
            _isGettingLocation = false;
            _locationError = 'Location services are disabled';
          });
        }
        return;
      }

      // Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print('[LiveMap] Location permission denied');
        if (mounted) {
          setState(() {
            _isGettingLocation = false;
            _locationError = 'Location permission denied';
          });
        }
        return;
      }

// Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      print('[LiveMap] Got user location: ${position.latitude}, ${position.longitude}');
      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
          _isGettingLocation = false;
          _locationError = null;
          _userLocationMarker = null;
        });
        _buildUserLocationMarker();
      }
    } catch (e) {
      print('[LiveMap] Error getting user location: $e');
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
          _locationError = 'Could not determine your location';
        });
      }
    }
  }

  Future<void> _buildUserLocationMarker() async {
    final location = _userLocation;
    if (location == null) return;

    try {
      final icon = await _createUserLocationIcon();
      if (!mounted || _userLocation == null) return;
      setState(() {
        _userLocationMarker = Marker(
          markerId: const MarkerId('user_location'),
          position: location,
          icon: icon,
          infoWindow: const InfoWindow(title: 'You are here'),
          zIndex: 100,
        );
      });
    } catch (e) {
      print('[LiveMap] Error building user location marker: $e');
    }
  }

Future<BitmapDescriptor> _createUserLocationIcon() async {
    const size = 60.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);

    // Outer translucent glow
    final glowPaint = Paint()..color = const Color(0x282196F3);
    canvas.drawCircle(center, size / 2 - 4, glowPaint);

    // White ring
    final ringPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(center, size / 2 - 14, ringPaint);

    // Solid blue dot
    final dotPaint = Paint()..color = const Color(0xFF2196F3);
    canvas.drawCircle(center, size / 2 - 14, dotPaint);

    final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  Future<void> _recenterToUserLocation() async {
    if (_userLocation != null && _mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _userLocation!, zoom: 17),
        ),
      );
      print('[LiveMap] Recentered to user location');
    } else {
      // No location yet, try to fetch it
      await _getUserLocation();
      if (_userLocation != null && _mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _userLocation!, zoom: 17),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not determine your location. Check permissions.'),
          ),
        );
      }
    }
  }

  Future<void> _loadShuttleLookup() async {
    final auth = context.read<AuthenticationProvider>();
    if (auth.accessToken == null) {
      print('[LiveMap] No auth token for shuttle lookup');
      return;
    }

    try {
      print('[LiveMap] Fetching shuttles for driver lookup...');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseHttpUrl}/shuttles'),
        headers: {'Authorization': 'Bearer ${auth.accessToken}'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final shuttles = jsonDecode(response.body) as List;
        final lookup = <String, Map<String, String>>{};

        for (final shuttle in shuttles) {
          final driverId = shuttle['driver_id'] as String?;
          final name = shuttle['name'] as String? ?? 'Unknown';
          final plate = shuttle['plate_number'] as String? ?? 'N/A';

          if (driverId != null && driverId.isNotEmpty) {
            lookup[driverId] = {'name': name, 'plate': plate};
            print('[LiveMap] Mapped driver $driverId -> $name ($plate)');
          }
        }

        if (mounted) {
          setState(() {
            _shuttleLookup = lookup;
          });
        }
        print('[LiveMap] Loaded ${lookup.length} shuttle mappings');
      } else {
        print('[LiveMap] Failed to fetch shuttles: ${response.statusCode}');
      }
    } catch (e) {
      print('[LiveMap] Error loading shuttle lookup: $e');
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _connectToLiveMap() async {
    final auth = context.read<AuthenticationProvider>();
    if (auth.accessToken == null) {
      if (mounted) {
        setState(() => _errorMessage = 'Authentication token not found');
      }
      return;
    }

    try {
      final wsUrl = Uri.parse('${ApiConfig.baseWsUrl}/ws/live-map?token=${auth.accessToken}');
      _channel = WebSocketChannel.connect(wsUrl);

      _channel!.stream.listen(
        (message) {
          try {
            // LOG: Raw message as received from WebSocket
            print('[LiveMap] RAW MESSAGE RECEIVED: $message');

            final data = jsonDecode(message);
            print('[LiveMap] DECODED JSON: $data');
            print('[LiveMap] Message type: ${data['type']}');

            _handleLiveMapMessage(data);
          } catch (e) {
            print('[LiveMap] ERROR decoding message: $e');
            print('[LiveMap] Failed message was: $message');
          }
        },
        onError: (error) {
          print('[LiveMap] WebSocket error: $error');
          if (mounted) {
            setState(() {
              _isConnected = false;
              _errorMessage = 'Connection error: $error';
            });
          }
          // Attempt reconnection after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              _connectToLiveMap();
            }
          });
        },
        onDone: () {
          print('[LiveMap] WebSocket closed');
          if (mounted) {
            setState(() => _isConnected = false);
          }
          // Attempt reconnection after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              _connectToLiveMap();
            }
          });
        },
      );

      if (mounted) {
        setState(() => _isConnected = true);
      }
    } catch (e) {
      print('[LiveMap] Connection error: $e');
      if (mounted) {
        setState(() => _errorMessage = 'Failed to connect: $e');
      }
    }
  }

  void _handleLiveMapMessage(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    print('[LiveMap] Handling message type: $type');
    print('[LiveMap] Full data keys: ${data.keys.toList()}');

    if (type == 'initial_snapshot') {
      // Initial snapshot of all active shuttles
      print('[LiveMap] Processing initial_snapshot');
      final snapshotData = data['data'] as Map<String, dynamic>? ?? {};
      print('[LiveMap] Number of drivers in snapshot: ${snapshotData.length}');

      final newShuttles = <String, ShuttleData>{};

      snapshotData.forEach((driverId, driverData) {
        print('[LiveMap] Processing driver: $driverId -> $driverData');
        if (driverId.isNotEmpty && driverData is Map<String, dynamic>) {
          // Add driver_id to the data object for ShuttleData.fromJson
          final driverWithId = {...driverData, 'driver_id': driverId};
          newShuttles[driverId] = ShuttleData.fromJson(driverWithId);
          print('[LiveMap] Added shuttle for driver: $driverId');
        } else {
          print('[LiveMap] WARNING: Invalid driver data for $driverId: $driverData');
        }
      });

      print('[LiveMap] Total shuttles loaded: ${newShuttles.length}');
      if (mounted) {
        setState(() {
          _shuttles = newShuttles;
          _errorMessage = null;
        });
        _updateMapMarkers();
        _animateCameraToShuttles();
      }
    } else if (type == 'driver_location_update') {
      // Real-time location update for a specific driver
      print('[LiveMap] Processing driver_location_update');
      print('[LiveMap] Update data: $data');
      final updateData = data['data'] as Map<String, dynamic>?;
      final driverId = updateData?['driver_id'] as String?;
      print('[LiveMap] Driver ID from update: $driverId');

      if (driverId != null && updateData != null) {
        final updatedData = ShuttleData.fromJson(updateData);

        if (mounted) {
          setState(() {
            _shuttles[driverId] = updatedData;
            print('[LiveMap] Updated shuttle for driver: $driverId');
            // Trigger pulse animation on this shuttle
            _pulsingShuttles.add(driverId);
          });
          _updateMarkerPosition(driverId, updatedData);
        }

        // Remove pulse after 600ms
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            setState(() => _pulsingShuttles.remove(driverId));
          }
        });
      } else {
        print('[LiveMap] WARNING: driver_id is null in update');
      }
    } else {
      print('[LiveMap] WARNING: Unknown message type: $type');
      print('[LiveMap] Message data: $data');
    }
  }

  void _updateMapMarkers() {
    final newMarkers = <String, Marker>{};
    String? matchedShuttleName;

    _shuttles.forEach((driverId, shuttle) {
      final shuttleInfo = _shuttleLookup[driverId];
      final title = shuttleInfo?['name'] ?? 'Unknown Shuttle';
      final plate = shuttleInfo?['plate'] ?? 'N/A';
      final isMatched = widget.matchedShuttleId == driverId;

      // Use different hue for matched shuttles (bright green vs blue)
      final markerHue = isMatched ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueBlue;

      newMarkers[driverId] = Marker(
        markerId: MarkerId(driverId),
        position: LatLng(shuttle.latitude, shuttle.longitude),
        infoWindow: InfoWindow(
          title: title,
          snippet: 'Plate: $plate',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(markerHue),
      );

      // Track matched shuttle info for floating card
      if (isMatched) {
        matchedShuttleName = title;
      }
    });

    setState(() {
      _markers = newMarkers;
      if (widget.matchedShuttleId != null && widget.etaMinutes != null) {
        _matchedShuttleName = matchedShuttleName;
        final etaText = widget.etaMinutes == 1 ? '1 min away' : '${widget.etaMinutes} mins away';
        _matchedShuttleEta = etaText;
      }
    });
  }

  void _updateMarkerPosition(String driverId, ShuttleData shuttle) {
    final shuttleInfo = _shuttleLookup[driverId];
    final title = shuttleInfo?['name'] ?? 'Unknown Shuttle';
    final plate = shuttleInfo?['plate'] ?? 'N/A';
    final isMatched = widget.matchedShuttleId == driverId;

    // Use different hue for matched vs regular shuttles
    final markerHue = isMatched ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueBlue;

    final updatedMarker = Marker(
      markerId: MarkerId(driverId),
      position: LatLng(shuttle.latitude, shuttle.longitude),
      infoWindow: InfoWindow(
        title: title,
        snippet: 'Plate: $plate',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(markerHue),
    );

    setState(() => _markers[driverId] = updatedMarker);

    // If this is the matched shuttle, animate camera to follow it
    if (isMatched) {
      _animateCameraToShuttles();
    }
  }

  Future<void> _animateCameraToShuttles() async {
    if (_mapController == null) return;

    // If there's a matched shuttle, center on it
    if (widget.matchedShuttleId != null) {
      final matchedShuttle = _shuttles[widget.matchedShuttleId];
      if (matchedShuttle != null) {
        final position = CameraPosition(
          target: LatLng(matchedShuttle.latitude, matchedShuttle.longitude),
          zoom: 17,
        );
        _mapController!.animateCamera(CameraUpdate.newCameraPosition(position));
        print('[LiveMap] Animated camera to matched shuttle at (${matchedShuttle.latitude}, ${matchedShuttle.longitude})');
        return;
      }
    }

    // Otherwise, if there are shuttles, fit all in view
    if (_shuttles.isNotEmpty) {
      final positions = _shuttles.values.map((s) => LatLng(s.latitude, s.longitude)).toList();
      if (positions.length == 1) {
        // Single shuttle: zoom in on it
        final position = CameraPosition(
          target: positions.first,
          zoom: 16,
        );
        _mapController!.animateCamera(CameraUpdate.newCameraPosition(position));
      } else {
        // Multiple shuttles: fit bounds
        final bounds = _calculateBounds(positions);
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100),
        );
        print('[LiveMap] Animated camera to fit ${positions.length} shuttles');
      }
      return;
    }

    // Fallback: show KNUST campus if no shuttles
    final defaultPosition = CameraPosition(
      target: _knustCenter,
      zoom: 15,
    );
    _mapController!.animateCamera(CameraUpdate.newCameraPosition(defaultPosition));
    print('[LiveMap] No shuttles found, showing default KNUST campus');
  }

  LatLngBounds _calculateBounds(List<LatLng> positions) {
    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (final pos in positions) {
      minLat = minLat > pos.latitude ? pos.latitude : minLat;
      maxLat = maxLat < pos.latitude ? pos.latitude : maxLat;
      minLng = minLng > pos.longitude ? pos.longitude : minLng;
      maxLng = maxLng < pos.longitude ? pos.longitude : maxLng;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Live Shuttles',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_isConnected && _errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Connection Error',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondaryLight),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _connectToLiveMap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
              ),
              child: Text(
                'Retry Connection',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
// Google Map
        GoogleMap(
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
          },
          initialCameraPosition: CameraPosition(
            target: _knustCenter,
            zoom: 15,
          ),
          markers: Set<Marker>.of([..._markers.values, if (_userLocationMarker != null) _userLocationMarker!]),
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
          mapType: MapType.normal,
        ),
        // My Location button (recenter to user)
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            mini: true,
            heroTag: 'recenter_location',
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF2196F3),
            elevation: 4,
            onPressed: _recenterToUserLocation,
            child: const Icon(Icons.my_location, size: 22),
          ),
        ),
        // Connection warning banner
        if (!_isConnected)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Reconnecting to live updates...',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange[900]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Matched shuttle info card (bottom when available)
        if (_matchedShuttleName != null && _matchedShuttleEta != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _matchedShuttleName!,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _matchedShuttleEta ?? 'Loading...',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          )
        // Shuttle count info (show when no matched shuttle)
        else if (_shuttles.isNotEmpty)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.dividerLight),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                '${_shuttles.length} shuttle${_shuttles.length == 1 ? '' : 's'} active',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ShuttleData {
  final String driverId;
  final String shuttleName;
  final double latitude;
  final double longitude;
  final double? heading;
  final DateTime lastUpdated;

  ShuttleData({
    required this.driverId,
    required this.shuttleName,
    required this.latitude,
    required this.longitude,
    this.heading,
    required this.lastUpdated,
  });

  factory ShuttleData.fromJson(Map<String, dynamic> json) {
    final timestamp = json['timestamp'] as String?;
    final lastUpdated = timestamp != null ? DateTime.parse(timestamp) : DateTime.now();

    return ShuttleData(
      driverId: json['driver_id'] as String? ?? 'unknown',
      shuttleName: json['shuttle_name'] as String? ?? 'Unknown Shuttle',
      latitude: (json['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['lng'] as num?)?.toDouble() ?? 0.0,
      heading: (json['heading'] as num?)?.toDouble(),
      lastUpdated: lastUpdated,
    );
  }

  String get lastUpdatedText {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);

    if (difference.inSeconds < 60) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
}

