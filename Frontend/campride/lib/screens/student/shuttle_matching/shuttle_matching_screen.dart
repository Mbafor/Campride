import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../../providers/authentication_provider.dart';
import '../../../services/shuttle_service.dart';
import '../../../theme/app_colors.dart';

class ShuttleMatchingScreen extends StatefulWidget {
  const ShuttleMatchingScreen({super.key});

  @override
  State<ShuttleMatchingScreen> createState() => _ShuttleMatchingScreenState();
}

class _StopData {
  final String id;
  final String name;
  final String routeName;
  final double lat;
  final double lng;

  _StopData({
    required this.id,
    required this.name,
    required this.routeName,
    required this.lat,
    required this.lng,
  });

  String get displayLabel => '$name ($routeName)';
}

class _ShuttleMatchingScreenState extends State<ShuttleMatchingScreen> {
  late ShuttleService _shuttleService;
  String? _pickupStop;
  String? _destinationStop;
  bool _isLoading = false;
  bool _isLoadingStops = false;
  List<_StopData> _allStops = [];
  Map<String, dynamic>? _matchingResult;
  String? _errorMessage;
  String? _activeRequestId;

  @override
  void initState() {
    super.initState();
    _shuttleService = ShuttleService();
    _loadRoutesAndStops();
  }

  Future<void> _loadRoutesAndStops() async {
    setState(() => _isLoadingStops = true);
    try {
      final auth = context.read<AuthenticationProvider>();
      if (auth.accessToken == null) {
        setState(() {
          _isLoadingStops = false;
          _errorMessage = 'Authentication failed';
        });
        return;
      }

      final routesUrl = '${ApiConfig.baseHttpUrl}/routes';

      final routesResponse = await http.get(
        Uri.parse(routesUrl),
        headers: {
          'Authorization': 'Bearer ${auth.accessToken}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (routesResponse.statusCode == 200) {
        final routes = jsonDecode(routesResponse.body) as List;
        final stops = <_StopData>[];

        for (var route in routes) {
          final routeId = route['id'];
          final routeName = route['name'] ?? 'Unknown';

          final stopsUrl = '${ApiConfig.baseHttpUrl}/routes/$routeId/stops';
          final stopsResponse = await http.get(
            Uri.parse(stopsUrl),
            headers: {
              'Authorization': 'Bearer ${auth.accessToken}',
              'Content-Type': 'application/json',
            },
          ).timeout(const Duration(seconds: 10));

          if (stopsResponse.statusCode == 200) {
            final stopsData = jsonDecode(stopsResponse.body) as List;
            for (var stop in stopsData) {
              stops.add(_StopData(
                id: stop['id'],
                name: stop['name'] ?? 'Unknown',
                routeName: routeName,
                lat: (stop['lat'] as num).toDouble(),
                lng: (stop['lng'] as num).toDouble(),
              ));
            }
          }
        }

        setState(() {
          _allStops = stops;
          _isLoadingStops = false;
          if (stops.isEmpty) {
            _errorMessage = 'No stops available';
          }
        });
      } else {
        setState(() {
          _isLoadingStops = false;
          _errorMessage = 'Failed to load routes: ${routesResponse.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingStops = false;
        _errorMessage = 'Error loading routes: $e';
      });
    }
  }

  Future<void> _performMatching() async {
    if (_pickupStop == null || _destinationStop == null) {
      setState(() => _errorMessage = 'Please select both pickup and destination');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _matchingResult = null;
    });

    final auth = context.read<AuthenticationProvider>();
    if (auth.accessToken == null) {
      setState(() => _errorMessage = 'Authentication failed');
      return;
    }

    final pickupStop = _allStops.firstWhere(
      (s) => s.displayLabel == _pickupStop,
      orElse: () => _allStops[0],
    );
    final destStop = _allStops.firstWhere(
      (s) => s.displayLabel == _destinationStop,
      orElse: () => _allStops[1],
    );

    final response = await _shuttleService.matchShuttles(
      accessToken: auth.accessToken!,
      pickupLat: pickupStop.lat,
      pickupLng: pickupStop.lng,
      destLat: destStop.lat,
      destLng: destStop.lng,
    );

    setState(() {
      _isLoading = false;
      if (response.success && response.data != null) {
        _matchingResult = response.data;
        if (response.data!['shuttle_request_id'] != null) {
          _activeRequestId = response.data!['shuttle_request_id'];
        }
      } else {
        _errorMessage = response.message ?? 'Failed to match shuttles';
      }
    });
  }

  Future<void> _confirmBoarding() async {
    if (_activeRequestId == null) {
      setState(() => _errorMessage = 'No active request to board');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthenticationProvider>();
    if (auth.accessToken == null) {
      setState(() => _errorMessage = 'Authentication failed');
      return;
    }

    final response = await _shuttleService.boardShuttle(
      accessToken: auth.accessToken!,
      shuttleRequestId: _activeRequestId!,
    );

    setState(() {
      _isLoading = false;
      if (response.success) {
        _errorMessage = null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully boarded! Ride history updated.'),
            backgroundColor: Colors.green,
          ),
        );
        // Reset the screen
        _pickupStop = null;
        _destinationStop = null;
        _matchingResult = null;
        _activeRequestId = null;
      } else {
        _errorMessage = response.message ?? 'Failed to confirm boarding';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Find a Shuttle',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                // Pickup stop selector
                Text(
                  'Pickup Location',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _StopDropdown(
                  value: _pickupStop,
                  onChanged: (val) => setState(() => _pickupStop = val),
                  label: 'Select pickup stop',
                  stops: _allStops,
                  isLoading: _isLoadingStops,
                ),
                const SizedBox(height: 20),
                // Destination stop selector
                Text(
                  'Destination',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _StopDropdown(
                  value: _destinationStop,
                  onChanged: (val) => setState(() => _destinationStop = val),
                  label: 'Select destination',
                  stops: _allStops,
                  isLoading: _isLoadingStops,
                ),
                const SizedBox(height: 32),
                // Match button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _performMatching,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(
                            'Find Available Shuttles',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.poppins(
                        color: Colors.red[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                // Matching results
                if (_matchingResult != null) ...[
                  Text(
                    'Available Shuttles',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Your shuttle request info
                  if (_matchingResult!['shuttle_request'] != null)
                    _RequestInfoCard(
                      request: _matchingResult!['shuttle_request'],
                    ),
                  const SizedBox(height: 16),
                  // Matched shuttles
                  if (_matchingResult!['matched'] != null &&
                      (_matchingResult!['matched'] as List).isNotEmpty) ...[
                    Text(
                      'Direct Match',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...((_matchingResult!['matched'] as List)
                        .cast<Map<String, dynamic>>()
                        .map((s) => _ShuttleCard(shuttle: s))
                        .toList()),
                    const SizedBox(height: 16),
                  ],
                  // Nearby shuttles
                  if (_matchingResult!['nearby'] != null &&
                      (_matchingResult!['nearby'] as List).isNotEmpty) ...[
                    Text(
                      'Nearby Shuttles',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...((_matchingResult!['nearby'] as List)
                        .cast<Map<String, dynamic>>()
                        .map((s) => _ShuttleCard(shuttle: s, isNearby: true))
                        .toList()),
                  ],
                  const SizedBox(height: 20),
                  // Boarding button
                  if (_activeRequestId != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _confirmBoarding,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'I Boarded This Shuttle',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StopDropdown extends StatelessWidget {
  final String? value;
  final Function(String?) onChanged;
  final String label;
  final List<_StopData> stops;
  final bool isLoading;

  const _StopDropdown({
    required this.value,
    required this.onChanged,
    required this.label,
    required this.stops,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      hint: Text(label),
      items: stops
          .map((stop) => DropdownMenuItem(
                value: stop.displayLabel,
                child: Text(stop.displayLabel),
              ))
          .toList(),
    );
  }
}

class _RequestInfoCard extends StatelessWidget {
  final Map<String, dynamic> request;

  const _RequestInfoCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Request',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Status: ${request['status'] ?? 'pending'}',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          if (request['matched_trip_id'] != null)
            Text(
              'Matched Trip ID: ${(request['matched_trip_id'] as String).substring(0, 8)}...',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
        ],
      ),
    );
  }
}

class _ShuttleCard extends StatelessWidget {
  final Map<String, dynamic> shuttle;
  final bool isNearby;

  const _ShuttleCard({
    required this.shuttle,
    this.isNearby = false,
  });

  @override
  Widget build(BuildContext context) {
    final name = shuttle['shuttle_name'] ?? shuttle['name'] ?? 'Unknown';
    final eta = shuttle['eta'] ?? 'N/A';
    final route = shuttle['route_name'] ?? 'Route Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isNearby ? Colors.grey[300]! : AppColors.primaryGreen,
          width: isNearby ? 1 : 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!isNearby)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Matched',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'ETA: $eta',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(width: 12),
              Icon(Icons.route, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  route,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
