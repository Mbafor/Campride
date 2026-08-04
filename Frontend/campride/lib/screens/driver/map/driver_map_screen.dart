import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../config/api_config.dart';
import '../../../providers/authentication_provider.dart';
import '../../../services/shuttle_service.dart';
import '../../../theme/app_theme.dart';

/// Driver's own live map: shows the driver's current position (as broadcast
/// on the same /ws/live-map feed the student app uses) plus their assigned
/// route's stops. Scoped to the driver's own trip — not other drivers.
class DriverMapScreen extends StatefulWidget {
  const DriverMapScreen({super.key});

  @override
  State<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends State<DriverMapScreen> {
  void _debugLog(String message) {
    if (kDebugMode) print('[DriverMap] $message');
  }

  final _shuttleService = ShuttleService();

  WebSocketChannel? _channel;
  bool _isConnected = false;
  String? _errorMessage;

  GoogleMapController? _mapController;
  BitmapDescriptor? _busIcon;
  bool _hasAutoFocused = false;

  DriverRoute? _route;
  List<Stop> _stops = [];
  bool _loadingRoute = true;

  LatLng? _myPosition;
  DateTime? _lastUpdate;

  static const LatLng _knustCenter = LatLng(6.7041, -1.5637);

  @override
  void initState() {
    super.initState();
    _initIcon();
    _loadRoute();
    _connect();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initIcon() async {
    try {
      final icon = await _createBusIcon();
      if (mounted) setState(() => _busIcon = icon);
    } catch (e) {
      _debugLog('Error creating bus icon: $e');
    }
  }

  Future<BitmapDescriptor> _createBusIcon() async {
    const size = 96.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(ui.BlurStyle.normal, 2);
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2 - 2, shadowPaint);

    final bgPaint = Paint()..color = AppColors.primaryGreen;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2 - 2, bgPaint);

    final textPainter = TextPainter(
      text: const TextSpan(text: '🚌', style: TextStyle(fontSize: 56)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
    );

    final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) throw 'Could not convert bus icon to bytes';
    return BitmapDescriptor.bytes(bytes.buffer.asUint8List());
  }

  Future<void> _loadRoute() async {
    final auth = context.read<AuthenticationProvider>();
    if (auth.accessToken == null) {
      if (mounted) setState(() => _loadingRoute = false);
      return;
    }

    final routeResult = await _shuttleService.getDriverRoute(accessToken: auth.accessToken!);

    List<Stop> stops = [];
    if (routeResult.success && routeResult.data != null) {
      final stopsResult = await _shuttleService.getRouteStops(
        accessToken: auth.accessToken!,
        routeId: routeResult.data!.id,
      );
      stops = stopsResult.data ?? [];
    }

    if (mounted) {
      setState(() {
        _route = routeResult.data;
        _stops = stops;
        _loadingRoute = false;
      });
      _autoFocusIfNeeded();
    }
  }

  Future<void> _connect() async {
    final auth = context.read<AuthenticationProvider>();
    final myId = auth.user?.id;

    if (auth.accessToken == null || myId == null) {
      if (mounted) setState(() => _errorMessage = 'Authentication token not found');
      return;
    }

    try {
      final wsUrl = Uri.parse('${ApiConfig.baseWsUrl}/ws/live-map?token=${auth.accessToken}');
      _channel = WebSocketChannel.connect(wsUrl);

      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            _handleMessage(data, myId);
          } catch (e) {
            _debugLog('Error decoding message: $e');
          }
        },
        onError: (error) {
          _debugLog('WebSocket error: $error');
          if (mounted) {
            setState(() {
              _isConnected = false;
              _errorMessage = 'Connection error';
            });
          }
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) _connect();
          });
        },
        onDone: () {
          _debugLog('WebSocket closed');
          if (mounted) setState(() => _isConnected = false);
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) _connect();
          });
        },
      );

      if (mounted) {
        setState(() {
          _isConnected = true;
          _errorMessage = null;
        });
      }
    } catch (e) {
      _debugLog('Connection error: $e');
      if (mounted) setState(() => _errorMessage = 'Failed to connect: $e');
    }
  }

  void _handleMessage(Map<String, dynamic> data, String myId) {
    final type = data['type'] as String?;

    if (type == 'initial_snapshot') {
      final snapshot = data['data'] as Map<String, dynamic>? ?? {};
      final mine = snapshot[myId];
      if (mine is Map<String, dynamic>) _applyPosition(mine);
    } else if (type == 'driver_location_update') {
      final updateData = data['data'] as Map<String, dynamic>?;
      final driverId = updateData?['driver_id'] as String?;
      if (driverId == myId && updateData != null) {
        _applyPosition(updateData);
      }
    }
  }

  void _applyPosition(Map<String, dynamic> data) {
    final lat = (data['lat'] as num?)?.toDouble();
    final lng = (data['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return;

    final timestamp = data['timestamp'] as String?;

    if (!mounted) return;
    setState(() {
      _myPosition = LatLng(lat, lng);
      _lastUpdate = timestamp != null ? DateTime.tryParse(timestamp) ?? DateTime.now() : DateTime.now();
    });
    _autoFocusIfNeeded();
  }

  /// Centers the camera exactly once, as soon as we have something worth
  /// centering on (the driver's own position, or failing that, their route's
  /// stops). Never re-centers automatically after that, so it doesn't fight
  /// the driver's own panning/zooming.
  void _autoFocusIfNeeded() {
    if (_hasAutoFocused || _mapController == null) return;
    if (_myPosition != null || _stops.isNotEmpty) {
      _hasAutoFocused = true;
      _focusCamera();
    }
  }

  Future<void> _focusCamera() async {
    final controller = _mapController;
    if (controller == null) return;

    if (_myPosition != null) {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: _myPosition!, zoom: 16)),
      );
      return;
    }

    if (_stops.isNotEmpty) {
      final positions = _stops.map((s) => LatLng(s.lat, s.lng)).toList();
      if (positions.length == 1) {
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(CameraPosition(target: positions.first, zoom: 15)),
        );
      } else {
        await controller.animateCamera(CameraUpdate.newLatLngBounds(_bounds(positions), 80));
      }
      return;
    }

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(const CameraPosition(target: _knustCenter, zoom: 15)),
    );
  }

  LatLngBounds _bounds(List<LatLng> positions) {
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

  String get _lastUpdatedText {
    final last = _lastUpdate;
    if (last == null) return '';
    final diff = DateTime.now().difference(last);
    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    for (final stop in _stops) {
      markers.add(
        Marker(
          markerId: MarkerId('stop_${stop.id}'),
          position: LatLng(stop.lat, stop.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          infoWindow: InfoWindow(title: 'Stop ${stop.order}', snippet: stop.name),
        ),
      );
    }

    if (_myPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('me'),
          position: _myPosition!,
          icon: _busIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          zIndexInt: 100,
          infoWindow: InfoWindow(
            title: 'You',
            snippet: _lastUpdatedText.isEmpty ? null : 'Updated $_lastUpdatedText',
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null && !_isConnected && _myPosition == null) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  'Connection Error',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w600, color: context.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 14, color: context.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _connect,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                  child: Text(
                    'Retry Connection',
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        GoogleMap(
          onMapCreated: (controller) {
            _mapController = controller;
            _autoFocusIfNeeded();
          },
          initialCameraPosition: const CameraPosition(target: _knustCenter, zoom: 15),
          markers: _buildMarkers(),
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapType: MapType.normal,
        ),

        // Route summary card (top)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _RouteSummaryCard(loading: _loadingRoute, route: _route, stopCount: _stops.length),
            ),
          ),
        ),

        // Reconnecting banner
        if (!_isConnected)
          Positioned(
            top: 90,
            left: 16,
            right: 16,
            child: SafeArea(
              bottom: false,
              top: false,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Reconnecting to live map…',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange[900]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Recenter button
        Positioned(
          right: 16,
          bottom: 16,
          child: SafeArea(
            top: false,
            child: FloatingActionButton(
              mini: true,
              heroTag: 'driver_recenter_location',
              backgroundColor: context.cardBg,
              foregroundColor: AppColors.primaryGreen,
              elevation: 4,
              onPressed: _focusCamera,
              child: const Icon(Icons.my_location, size: 22),
            ),
          ),
        ),

        // Sharing status (bottom)
        Positioned(
          left: 16,
          right: 80,
          bottom: 16,
          child: SafeArea(
            top: false,
            child: _SharingStatusPill(isSharing: _myPosition != null, lastUpdatedText: _lastUpdatedText),
          ),
        ),
      ],
    );
  }
}

class _RouteSummaryCard extends StatelessWidget {
  final bool loading;
  final DriverRoute? route;
  final int stopCount;

  const _RouteSummaryCard({required this.loading, required this.route, required this.stopCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.divider),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.alt_route, size: 20, color: AppColors.primaryGreen),
          const SizedBox(width: 10),
          Expanded(
            child: loading
                ? Text('Loading route…',
                    style: GoogleFonts.poppins(fontSize: 13, color: context.textSecondary))
                : route == null
                    ? Text('No route assigned',
                        style: GoogleFonts.poppins(fontSize: 13, color: context.textSecondary))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            route!.name,
                            style: GoogleFonts.poppins(
                                fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$stopCount stop${stopCount == 1 ? '' : 's'}',
                            style: GoogleFonts.poppins(fontSize: 12, color: context.textSecondary),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _SharingStatusPill extends StatelessWidget {
  final bool isSharing;
  final String lastUpdatedText;

  const _SharingStatusPill({required this.isSharing, required this.lastUpdatedText});

  @override
  Widget build(BuildContext context) {
    final color = isSharing ? AppColors.success : context.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.divider),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              isSharing
                  ? 'Sharing your live location${lastUpdatedText.isEmpty ? '' : ' • $lastUpdatedText'}'
                  : 'Not sharing — start a trip from Home',
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: context.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
