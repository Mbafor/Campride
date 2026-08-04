import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../../providers/authentication_provider.dart';
import '../../../services/shuttle_service.dart';
import '../../../config/api_config.dart';
import '../../../theme/app_theme.dart';
import 'driver_trip_history_full_screen.dart';

class FleetRoute {
  final String routeId;
  final String routeName;
  final String startName;
  final String endName;
  final int tripCount;
  final DateTime lastUsed;

  FleetRoute({
    required this.routeId,
    required this.routeName,
    required this.startName,
    required this.endName,
    required this.tripCount,
    required this.lastUsed,
  });

  factory FleetRoute.fromJson(Map<String, dynamic> json) {
    return FleetRoute(
      routeId: json['route_id'] ?? '',
      routeName: json['route_name'] ?? '',
      startName: json['start_name'] ?? '',
      endName: json['end_name'] ?? '',
      tripCount: (json['trip_count'] ?? 0) is int ? json['trip_count'] : int.parse(json['trip_count'].toString()),
      lastUsed: DateTime.parse(json['last_used'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class DriverDetailScreen extends StatefulWidget {
  final String driverId;

  const DriverDetailScreen({
    super.key,
    required this.driverId,
  });

  @override
  State<DriverDetailScreen> createState() => _DriverDetailScreenState();
}

class _DriverDetailScreenState extends State<DriverDetailScreen> {
  final _shuttleService = ShuttleService();
  DriverInfo? _driver;
  bool _loading = true;
  List<FleetRoute> _routes = [];
  bool _loadingRoutes = false;

  @override
  void initState() {
    super.initState();
    _loadDriver();
    _loadRoutes();
  }

  Future<void> _loadDriver() async {
    final auth = context.read<AuthenticationProvider>();
    if (auth.accessToken == null) {
      setState(() => _loading = false);
      return;
    }

    final result = await _shuttleService.getDriver(
      accessToken: auth.accessToken!,
      driverId: widget.driverId,
    );

    if (mounted) {
      setState(() {
        _driver = result.data;
        _loading = false;
      });
    }
  }

  Future<void> _loadRoutes() async {
    if (!mounted) return;
    setState(() => _loadingRoutes = true);

    try {
      final auth = context.read<AuthenticationProvider>();
      if (auth.accessToken == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseHttpUrl}/fleet/drivers/${widget.driverId}/routes'),
        headers: {'Authorization': 'Bearer ${auth.accessToken}'},
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // API returns wrapped response: {"driver_id": "...", "routes": [...]}
        final list = data is List ? data : (data['routes'] as List? ?? []);
        final routes = list.map((r) => FleetRoute.fromJson(r as Map<String, dynamic>)).toList();
        setState(() {
          _routes = routes;
          _loadingRoutes = false;
        });
      } else {
        setState(() => _loadingRoutes = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loadingRoutes = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Driver Details', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
          ),
        ),
      );
    }

    if (_driver == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Driver Details', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        body: Center(
          child: Text(
            'Driver not found',
            style: GoogleFonts.poppins(color: context.textSecondary),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _driver!.name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Personal Info Section
            _PersonalInfoCard(driver: _driver!),
            const SizedBox(height: 24),

            // Ride History Section - Summary with link to full screen
            _TripHistorySummarySection(
              driver: _driver!,
            ),
            const SizedBox(height: 24),

            // Routes History Section
            _RoutesHistorySection(
              routes: _routes,
              loading: _loadingRoutes,
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonalInfoCard extends StatelessWidget {
  final DriverInfo driver;

  const _PersonalInfoCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primaryGreen,
                child: Text(
                  driver.name.substring(0, 1),
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text(
                    driver.name,
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    driver.email,
                    style: GoogleFonts.poppins(fontSize: 14, color: context.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Divider(color: context.divider),
            const SizedBox(height: 16),
            Text(
              'Assignment Info',
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.airport_shuttle,
              label: 'Assigned Shuttle',
              value: driver.assignedShuttleName ?? 'Not assigned',
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.route,
              label: 'Current Route',
              value: driver.assignedRouteName ?? 'Not assigned',
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.circle,
              label: 'Status',
              value: driver.isActive ? 'Active' : 'Inactive',
              valueColor: driver.isActive ? AppColors.success : AppColors.error,
            ),
          ],
        ),
      ),
    );
  }
}

class _TripHistorySummarySection extends StatelessWidget {
  final DriverInfo driver;

  const _TripHistorySummarySection({required this.driver});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trip History',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DriverTripHistoryFullScreen(
                    driverId: driver.id,
                    driverName: driver.name,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: Text(
              'View Full Trip History',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoutesHistorySection extends StatelessWidget {
  final List<FleetRoute> routes;
  final bool loading;

  const _RoutesHistorySection({
    required this.routes,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Routes History',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        if (loading)
          const Center(child: CircularProgressIndicator())
        else if (routes.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(Icons.route_outlined, size: 48, color: context.textSecondary),
                  const SizedBox(height: 12),
                  Text(
                    'No routes yet',
                    style: GoogleFonts.poppins(fontSize: 14, color: context.textSecondary),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: routes
                .asMap()
                .entries
                .map((e) => Padding(
                  padding: EdgeInsets.only(bottom: e.key < routes.length - 1 ? 8 : 0),
                  child: _RouteCard(route: e.value),
                ))
                .toList(),
          ),
      ],
    );
  }
}

class _RouteCard extends StatelessWidget {
  final FleetRoute route;

  const _RouteCard({required this.route});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route, size: 18, color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.routeName,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Text(
                        '${route.startName} → ${route.endName}',
                        style: GoogleFonts.poppins(fontSize: 11, color: context.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.repeat, size: 14, color: context.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${route.tripCount} trips',
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: context.textSecondary),
                ),
                const Spacer(),
                Icon(Icons.schedule, size: 14, color: context.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Last: ${DateFormat('MMM dd').format(route.lastUsed)}',
                  style: GoogleFonts.poppins(fontSize: 11, color: context.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryGreen),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: context.textSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
