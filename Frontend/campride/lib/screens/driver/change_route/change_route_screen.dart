import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../providers/authentication_provider.dart';
import '../../../services/shuttle_service.dart';
import '../../../config/api_config.dart';
import '../../../theme/app_colors.dart';

class ChangeRouteScreen extends StatefulWidget {
  const ChangeRouteScreen({super.key});

  @override
  State<ChangeRouteScreen> createState() => _ChangeRouteScreenState();
}

class _ChangeRouteScreenState extends State<ChangeRouteScreen> {
  late Future<List<DriverRoute>> _routesFuture;
  DriverRoute? _selectedRoute;
  List<Stop> _selectedStops = [];
  bool _loadingStops = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _routesFuture = _loadRoutes();
  }

  Future<List<DriverRoute>> _loadRoutes() async {
    try {
      final auth = context.read<AuthenticationProvider>();
      if (auth.accessToken == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseHttpUrl}/routes'),
        headers: {'Authorization': 'Bearer ${auth.accessToken}'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // API returns list directly, not wrapped in 'data' key
        final list = data is List ? data : (data['data'] as List? ?? []);
        final routes = list
            .map((r) => DriverRoute.fromJson(r as Map<String, dynamic>))
            .toList();
        return routes;
      } else {
        throw Exception('Failed to load routes');
      }
    } catch (e) {
      throw Exception('Error loading routes: $e');
    }
  }

  Future<void> _loadStops(DriverRoute route) async {
    setState(() => _loadingStops = true);

    try {
      final auth = context.read<AuthenticationProvider>();
      if (auth.accessToken == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseHttpUrl}/routes/${route.id}/stops'),
        headers: {'Authorization': 'Bearer ${auth.accessToken}'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // API returns list directly, not wrapped in 'data' key
        final list = data is List ? data : (data['data'] as List? ?? []);
        final stops = list
            .map((s) => Stop.fromJson(s as Map<String, dynamic>))
            .toList();

        if (mounted) {
          setState(() {
            _selectedRoute = route;
            _selectedStops = stops;
            _loadingStops = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _loadingStops = false);
          _showError('Failed to load route stops');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingStops = false);
        _showError('Error loading stops: $e');
      }
    }
  }

  Future<void> _submitRouteChange() async {
    if (_selectedRoute == null) {
      _showError('Please select a route');
      return;
    }

    setState(() => _submitting = true);

    try {
      final auth = context.read<AuthenticationProvider>();
      if (auth.accessToken == null) throw Exception('Not authenticated');

      final response = await http.put(
        Uri.parse('${ApiConfig.baseHttpUrl}/driver/route'),
        headers: {
          'Authorization': 'Bearer ${auth.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'route_id': _selectedRoute!.id}),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      setState(() => _submitting = false);

      if (response.statusCode == 200) {
        _showSuccess('Route changed to ${_selectedRoute!.name}');
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) Navigator.pop(context, _selectedRoute);
      } else {
        _showError('Failed to change route (${response.statusCode})');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        _showError('Error: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Change Route', style: GoogleFonts.poppins()),
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<DriverRoute>>(
              future: _routesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load routes',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondaryLight),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final routes = snapshot.data ?? [];
                if (routes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.route_outlined, size: 64, color: AppColors.textSecondaryLight),
                        const SizedBox(height: 16),
                        Text(
                          'No routes available',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Routes',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      ...routes.map((route) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () => _loadStops(route),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _selectedRoute?.id == route.id
                                    ? AppColors.primaryGreen
                                    : AppColors.dividerLight,
                                width: _selectedRoute?.id == route.id ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: _selectedRoute?.id == route.id
                                  ? AppColors.primaryGreen.withOpacity(0.05)
                                  : Colors.transparent,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _selectedRoute?.id == route.id
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_unchecked,
                                      color: AppColors.primaryGreen,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        route.name,
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.location_on_outlined,
                                        size: 14, color: AppColors.textSecondaryLight),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${route.startName} → ${route.endName}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: AppColors.textSecondaryLight,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      )).toList(),
                      if (_selectedRoute != null && _selectedStops.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Route Stops',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        if (_loadingStops)
                          const Center(child: CircularProgressIndicator())
                        else
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.dividerLight),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[50],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _selectedStops
                                  .asMap()
                                  .entries
                                  .map((e) => Padding(
                                    padding: EdgeInsets.only(
                                      bottom: e.key < _selectedStops.length - 1 ? 8 : 0,
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: e.key == 0 || e.key == _selectedStops.length - 1
                                                ? AppColors.primaryGreen
                                                : AppColors.primaryGreen.withOpacity(0.3),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${e.key + 1}',
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            e.value.name,
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight:
                                                  e.key == 0 || e.key == _selectedStops.length - 1
                                                      ? FontWeight.w600
                                                      : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                                  .toList(),
                            ),
                          ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting || _selectedRoute == null ? null : _submitRouteChange,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _selectedRoute == null ? 'Select a Route' : 'Confirm Change',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
