import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../providers/authentication_provider.dart';
import '../../theme/app_colors.dart';

class LiveShuttlesScreen extends StatefulWidget {
  const LiveShuttlesScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    print('[LiveMap] ===== SCREEN INITSTATE CALLED =====');
    print('[LiveMap] Screen is mounting, about to connect to WebSocket');
    _loadShuttleLookup();
    _connectToLiveMap();
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

        setState(() {
          _shuttleLookup = lookup;
        });
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
    super.dispose();
  }

  Future<void> _connectToLiveMap() async {
    final auth = context.read<AuthenticationProvider>();
    if (auth.accessToken == null) {
      setState(() => _errorMessage = 'Authentication token not found');
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
          setState(() {
            _isConnected = false;
            _errorMessage = 'Connection error: $error';
          });
          // Attempt reconnection after 3 seconds
          Future.delayed(const Duration(seconds: 3), _connectToLiveMap);
        },
        onDone: () {
          print('[LiveMap] WebSocket closed');
          setState(() => _isConnected = false);
          // Attempt reconnection after 3 seconds
          Future.delayed(const Duration(seconds: 3), _connectToLiveMap);
        },
      );

      setState(() => _isConnected = true);
    } catch (e) {
      print('[LiveMap] Connection error: $e');
      setState(() => _errorMessage = 'Failed to connect: $e');
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
      setState(() {
        _shuttles = newShuttles;
        _errorMessage = null;
      });
    } else if (type == 'driver_location_update') {
      // Real-time location update for a specific driver
      print('[LiveMap] Processing driver_location_update');
      print('[LiveMap] Update data: $data');
      final updateData = data['data'] as Map<String, dynamic>?;
      final driverId = updateData?['driver_id'] as String?;
      print('[LiveMap] Driver ID from update: $driverId');

      if (driverId != null && updateData != null) {
        final updatedData = ShuttleData.fromJson(updateData);

        setState(() {
          _shuttles[driverId] = updatedData;
          print('[LiveMap] Updated shuttle for driver: $driverId');
          // Trigger pulse animation on this shuttle
          _pulsingShuttles.add(driverId);
        });

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

    if (_shuttles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_bus_filled,
              size: 64,
              color: AppColors.primaryGreen.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No Shuttles Currently Active',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back when a driver starts their trip',
              style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondaryLight),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _connectToLiveMap();
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!_isConnected)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
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
          ..._shuttles.entries.map((entry) {
            final driverId = entry.key;
            final shuttle = entry.value;
            final isPulsing = _pulsingShuttles.contains(driverId);
            final shuttleInfo = _shuttleLookup[driverId];

            return _ShuttleCard(
              shuttle: shuttle,
              isPulsing: isPulsing,
              shuttleName: shuttleInfo?['name'] ?? 'Unknown Shuttle',
              plateNumber: shuttleInfo?['plate'] ?? 'N/A',
            );
          }),
        ],
      ),
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

class _ShuttleCard extends StatelessWidget {
  final ShuttleData shuttle;
  final bool isPulsing;
  final String shuttleName;
  final String plateNumber;

  const _ShuttleCard({
    required this.shuttle,
    required this.isPulsing,
    required this.shuttleName,
    required this.plateNumber,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isPulsing ? AppColors.success.withValues(alpha: 0.1) : Colors.white,
        border: Border.all(
          color: isPulsing ? AppColors.success : AppColors.dividerLight,
          width: isPulsing ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_bus, color: AppColors.primaryGreen, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shuttleName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'Plate: $plateNumber',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isPulsing)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Live',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    Text(
                      shuttle.lastUpdatedText,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: AppColors.primaryGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Latitude: ${shuttle.latitude.toStringAsFixed(6)}',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: AppColors.primaryGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Longitude: ${shuttle.longitude.toStringAsFixed(6)}',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                  if (shuttle.heading != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.navigation, size: 16, color: AppColors.primaryGreen),
                        const SizedBox(width: 8),
                        Text(
                          'Heading: ${shuttle.heading!.toStringAsFixed(1)}°',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
