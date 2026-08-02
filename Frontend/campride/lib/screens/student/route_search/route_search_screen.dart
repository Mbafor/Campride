import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

import '../../../config/api_config.dart';
import '../../../providers/authentication_provider.dart';
import '../../../theme/app_colors.dart';
import '../live_shuttles_screen.dart';

class RouteSearchScreen extends StatefulWidget {
  const RouteSearchScreen({super.key});

  @override
  State<RouteSearchScreen> createState() => _RouteSearchScreenState();
}

class _RouteSearchScreenState extends State<RouteSearchScreen> {
  List<Map<String, dynamic>> _allStops = [];
  String? _pickupStop;
  String? _destinationStop;
  bool _isLoading = true;
  String? _errorMessage;
  Position? _currentPosition;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Request location permission and get position
      await _getCurrentLocation();
      // Fetch all stops
      await _fetchAllStops();
      // Find nearest stop for pickup
      if (_allStops.isNotEmpty && _currentPosition != null) {
        _findNearestStop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      LocationPermission finalStatus = permission;

      if (permission == LocationPermission.denied) {
        finalStatus = await Geolocator.requestPermission();
      }

      if (finalStatus == LocationPermission.denied ||
          finalStatus == LocationPermission.deniedForever) {
        throw 'Location permission denied. Please enable it in settings.';
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() => _currentPosition = position);
      }
    } catch (e) {
      // Continue without location - user can select manually
    }
  }

  Future<void> _fetchAllStops() async {
    try {
      final auth = context.read<AuthenticationProvider>();
      if (auth.accessToken == null) throw 'Not authenticated';

      // Get all routes
      final routesResponse = await http.get(
        Uri.parse('${ApiConfig.baseHttpUrl}/routes'),
        headers: {'Authorization': 'Bearer ${auth.accessToken}'},
      ).timeout(const Duration(seconds: 10));

      if (routesResponse.statusCode != 200) {
        throw 'Failed to fetch routes';
      }

      final routes = jsonDecode(routesResponse.body) as List;
      final stops = <String, Map<String, dynamic>>{};

      // Fetch stops for each route
      for (final route in routes) {
        final routeId = route['id'];
        final stopsResponse = await http.get(
          Uri.parse('${ApiConfig.baseHttpUrl}/routes/$routeId/stops'),
          headers: {'Authorization': 'Bearer ${auth.accessToken}'},
        ).timeout(const Duration(seconds: 10));

        if (stopsResponse.statusCode == 200) {
          final routeStops = jsonDecode(stopsResponse.body);
          final stopList = routeStops is Map
              ? (routeStops['data'] ?? routeStops['stops'] ?? []) as List
              : routeStops as List;

          for (final stop in stopList) {
            final stopId = stop['id'] as String;
            stops[stopId] = {
              'id': stopId,
              'name': stop['name'] ?? 'Unknown Stop',
              'latitude': (stop['latitude'] as num?)?.toDouble() ?? 0.0,
              'longitude': (stop['longitude'] as num?)?.toDouble() ?? 0.0,
            };
          }
        }
      }

      if (mounted) {
        setState(() {
          _allStops = stops.values.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load stops: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _findNearestStop() {
    if (_currentPosition == null || _allStops.isEmpty) return;

    double nearest = double.infinity;
    Map<String, dynamic>? nearestStop;

    for (final stop in _allStops) {
      final distance = _haversineDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        stop['latitude'],
        stop['longitude'],
      );

      if (distance < nearest) {
        nearest = distance;
        nearestStop = stop;
      }
    }

    if (nearestStop != null) {
      setState(() => _pickupStop = nearestStop!['id']);
    }
  }

  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Earth radius in km
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) *
            cos(_toRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRad(double deg) => deg * pi / 180;

  Future<void> _submitSearch() async {
    if (_pickupStop == null || _destinationStop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both pickup and destination')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final auth = context.read<AuthenticationProvider>();
      if (auth.accessToken == null) throw 'Not authenticated';

      final pickupData = _allStops.firstWhere((s) => s['id'] == _pickupStop);
      final destinationData = _allStops.firstWhere((s) => s['id'] == _destinationStop);

      final response = await http.post(
        Uri.parse('${ApiConfig.baseHttpUrl}/shuttles/match'),
        headers: {
          'Authorization': 'Bearer ${auth.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'pickup_lat': pickupData['latitude'],
          'pickup_lng': pickupData['longitude'],
          'destination_lat': destinationData['latitude'],
          'destination_lng': destinationData['longitude'],
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final matchData = jsonDecode(response.body);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => LiveShuttlesScreen(
                matchedShuttleId: matchData['shuttle_id'],
                etaMinutes: matchData['eta_minutes'] as int?,
              ),
            ),
          );
        }
      } else {
        throw 'Failed to match shuttles';
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Route',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Icon(Icons.info_outline, color: AppColors.primaryGreen),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(color: Colors.red),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pickup field
                      Text(
                        'Pickup',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: _pickupStop,
                        hint: Text(
                          'Auto-detected nearby',
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                        items: _allStops
                            .map((stop) => DropdownMenuItem<String>(
                                  value: stop['id'] as String,
                                  child: Text(
                                    stop['name'] as String,
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _pickupStop = value),
                        underline: Container(
                          height: 1,
                          color: Colors.grey[300],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Destination field
                      Text(
                        'Destination',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: _destinationStop,
                        hint: Text(
                          'Select destination',
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                        items: _allStops
                            .map((stop) => DropdownMenuItem<String>(
                                  value: stop['id'] as String,
                                  child: Text(
                                    stop['name'] as String,
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => _destinationStop = value),
                        underline: Container(
                          height: 1,
                          color: Colors.grey[300],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitSearch,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _isSubmitting
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Find Shuttles',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
