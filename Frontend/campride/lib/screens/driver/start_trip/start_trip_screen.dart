import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/authentication_provider.dart';
import '../../../services/shuttle_service.dart';
import '../../../services/telemetry_service.dart';
import '../../../services/driver_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/buttons/custom_button.dart';

class StartTripScreen extends StatefulWidget {
  const StartTripScreen({super.key});

  @override
  State<StartTripScreen> createState() => _StartTripScreenState();
}

class _StartTripScreenState extends State<StartTripScreen>
    with SingleTickerProviderStateMixin {
  bool _tripStarted = false;
  bool _loading = false;
  bool _loadingRoute = true;
  bool _locationSharing = false;
  late AnimationController _pulseController;
  final _shuttleService = ShuttleService();
  final _telemetryService = TelemetryService();
  final _driverService = DriverService();
  DriverRoute? _currentRoute;
  List<Stop> _stops = [];
  ShuttleInfo? _assignedShuttle;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _loadDriverData();
  }

  Future<void> _loadDriverData() async {
    final auth = context.read<AuthenticationProvider>();
    if (auth.accessToken == null) {
      setState(() => _loadingRoute = false);
      return;
    }

    // Load route
    final routeResult = await _shuttleService.getDriverRoute(
      accessToken: auth.accessToken!,
    );

    // Load shuttle
    final shuttleResult = await _shuttleService.getDriverShuttle(
      accessToken: auth.accessToken!,
    );

    // Load stops if route exists
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
        _currentRoute = routeResult.data;
        _stops = stops;
        _assignedShuttle = shuttleResult.data;
        _loadingRoute = false;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _toggleTrip() async {
    final auth = context.read<AuthenticationProvider>();

    if (!_tripStarted) {
      // Starting a trip
      await _startTrip(auth);
    } else {
      // Ending a trip
      await _endTrip(auth);
    }
  }

  Future<void> _startTrip(AuthenticationProvider auth) async {
    if (auth.accessToken == null) {
      _showError('Authentication token not found');
      return;
    }

    setState(() => _loading = true);

    // Set up error and status callbacks
    _telemetryService.onError = (error) {
      if (mounted) {
        _showError(error);
      }
    };

    _telemetryService.onConnected = () {
      if (mounted) {
        setState(() => _locationSharing = true);
        _showSuccess('Location sharing started');
      }
    };

    _telemetryService.onDisconnected = () {
      if (mounted) {
        setState(() => _locationSharing = false);
      }
    };

    // Start telemetry
    final success = await _telemetryService.startTelemetry(auth.accessToken!);

    if (mounted) {
      setState(() => _loading = false);

      if (success) {
        setState(() {
          _tripStarted = true;
          _pulseController.repeat(reverse: true);
        });
      }
    }
  }

  Future<void> _endTrip(AuthenticationProvider auth) async {
    if (auth.accessToken == null) {
      _showError('Authentication token not found');
      return;
    }

    setState(() => _loading = true);

    // Stop telemetry first
    _telemetryService.stopTelemetry();

    // Call offline endpoint
    final result = await _driverService.endTrip(accessToken: auth.accessToken!);

    if (mounted) {
      setState(() => _loading = false);

      if (result.success) {
        setState(() {
          _tripStarted = false;
          _pulseController.stop();
          _pulseController.reset();
        });
        _showSuccess('Trip ended successfully');
      } else {
        _showError(result.error ?? 'Failed to end trip');
        // Still mark as ended even if the offline call failed
        setState(() {
          _tripStarted = false;
          _pulseController.stop();
          _pulseController.reset();
        });
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
    final auth = context.watch<AuthenticationProvider>();

    if (_loadingRoute) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${auth.user?.name ?? 'Driver'}',
                  style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ready to start your route?',
                  style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondaryLight),
                ),
              ],
            ),
          ),

          // Trip status card
          _TripStatusCard(isStarted: _tripStarted, pulseController: _pulseController),
          const SizedBox(height: 24),

          // My Route section
          Text(
            'My Route',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (_currentRoute != null)
            _RouteCard(route: _currentRoute!)
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.dividerLight),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[50],
              ),
              child: Row(
                children: [
                  Icon(Icons.route, color: AppColors.textSecondaryLight, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No route assigned',
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Contact your fleet manager to assign a route',
                          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Route selection coming soon'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.edit, size: 18),
              label: Text(
                'Change Route',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: AppColors.primaryGreen),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Assigned Shuttle section
          Text(
            'Assigned Shuttle',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (_assignedShuttle != null)
            _ShuttleCard(shuttle: _assignedShuttle!)
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.dividerLight),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[50],
              ),
              child: Row(
                children: [
                  Icon(Icons.airport_shuttle, color: AppColors.textSecondaryLight, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No shuttle assigned yet',
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Contact your fleet manager to assign a shuttle',
                          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // Route stops timeline (only show if route assigned)
          if (_currentRoute != null) ...[
            Text(
              'Route Stops',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _StopsTimeline(stops: _stops),
            const SizedBox(height: 32),
          ],

          // Start/End trip button
          CustomButton(
            label: _tripStarted ? 'End Trip' : 'Start Trip',
            isLoading: _loading,
            variant: _tripStarted ? ButtonVariant.outline : ButtonVariant.primary,
            icon: Icon(_tripStarted ? Icons.stop_circle_outlined : Icons.play_circle_outline),
            onPressed: _loading ? null : _toggleTrip,
          ),
          if (_tripStarted) ...[
            const SizedBox(height: 12),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_locationSharing) ...[
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      _locationSharing
                        ? 'Sharing location — passengers can track you'
                        : 'Trip in progress — starting location sharing...',
                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.success),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _TripStatusCard extends StatelessWidget {
  final bool isStarted;
  final AnimationController pulseController;

  const _TripStatusCard({required this.isStarted, required this.pulseController});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isStarted
              ? [AppColors.success, const Color(0xFF2E7D32)]
              : [AppColors.primaryGreen, AppColors.primaryGreenLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: pulseController,
            builder: (_, child) => Transform.scale(
              scale: isStarted ? 1.0 + pulseController.value * 0.15 : 1.0,
              child: child,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isStarted ? Icons.directions_bus : Icons.directions_bus_outlined,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isStarted ? 'Trip Active' : 'Ready to Start',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isStarted ? 'Live tracking enabled' : 'Press Start to begin',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isStarted) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('LIVE', style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final DriverRoute route;
  const _RouteCard({required this.route});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.route, color: AppColors.primaryGreen, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    route.name,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondaryLight),
                const SizedBox(width: 4),
                Text(
                  '${route.startName} → ${route.endName}',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondaryLight),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StopsTimeline extends StatelessWidget {
  final List<Stop> stops;
  const _StopsTimeline({required this.stops});

  @override
  Widget build(BuildContext context) {
    if (stops.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No stops available for this route',
              style: GoogleFonts.poppins(color: AppColors.textSecondaryLight),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Route Stops', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 12),
            ...stops.asMap().entries.map((e) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: e.key == 0 || e.key == stops.length - 1
                            ? AppColors.primaryGreen
                            : AppColors.primaryGreen.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${e.key + 1}',
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    if (e.key < stops.length - 1)
                      Container(width: 2, height: 28, color: AppColors.primaryGreen.withOpacity(0.2)),
                  ],
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    e.value.name,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: e.key == 0 || e.key == stops.length - 1 ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            )).toList(),
          ],
        ),
      ),
    );
  }
}

class _ShuttleCard extends StatelessWidget {
  final ShuttleInfo shuttle;
  const _ShuttleCard({required this.shuttle});

  String _getStatusColor() {
    switch (shuttle.status.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'idle':
        return 'Idle';
      case 'offline':
        return 'Offline';
      default:
        return shuttle.status;
    }
  }

  Color _getStatusBadgeColor() {
    switch (shuttle.status.toLowerCase()) {
      case 'active':
        return AppColors.success;
      case 'idle':
        return AppColors.warning;
      case 'offline':
        return AppColors.error;
      default:
        return AppColors.textSecondaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.airport_shuttle, color: AppColors.primaryGreen, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    shuttle.name,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusBadgeColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusColor(),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getStatusBadgeColor(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.tag, size: 14, color: AppColors.textSecondaryLight),
                const SizedBox(width: 6),
                Text(
                  shuttle.plateNumber,
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
                const SizedBox(width: 16),
                Icon(Icons.people, size: 14, color: AppColors.textSecondaryLight),
                const SizedBox(width: 6),
                Text(
                  '${shuttle.capacity} seats',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
