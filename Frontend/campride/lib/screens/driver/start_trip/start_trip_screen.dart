import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/authentication_provider.dart';
import '../../../services/shuttle_service.dart';
import '../../../services/telemetry_service.dart';
import '../../../services/driver_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/theme_extensions.dart';
import '../change_route/change_route_screen.dart';

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
      return SafeArea(
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
          ),
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HomeHeader(
              name: auth.user?.name ?? 'Driver',
              tripStarted: _tripStarted,
            ),
            const SizedBox(height: 20),
            _TripStatusCard(
              isStarted: _tripStarted,
              isLoading: _loading,
              locationSharing: _locationSharing,
              pulseController: _pulseController,
              onToggle: _loading ? null : _toggleTrip,
            ),
            const SizedBox(height: 24),

            // My Route section
                    Text(
                      'My Route',
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.bold, color: context.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    if (_currentRoute != null)
                      _RouteCard(route: _currentRoute!)
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: context.divider),
                          borderRadius: BorderRadius.circular(16),
                          color: context.fieldFill,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.route, color: context.textSecondary, size: 32),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'No route assigned',
                                    style: GoogleFonts.poppins(
                                        fontSize: 13, fontWeight: FontWeight.w500, color: context.textPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Contact your fleet manager to assign a route',
                                    style: GoogleFonts.poppins(fontSize: 11, color: context.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push<DriverRoute>(
                            context,
                            MaterialPageRoute(builder: (_) => const ChangeRouteScreen()),
                          );
                          if (result != null) {
                            await _loadDriverData();
                          }
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primaryGreen),
                        label: Text(
                          'Change Route',
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryGreen),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Assigned Shuttle section
                    Text(
                      'Assigned Shuttle',
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.bold, color: context.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    if (_assignedShuttle != null)
                      _ShuttleCard(shuttle: _assignedShuttle!)
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: context.divider),
                          borderRadius: BorderRadius.circular(16),
                          color: context.fieldFill,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.airport_shuttle, color: context.textSecondary, size: 32),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'No shuttle assigned yet',
                                    style: GoogleFonts.poppins(
                                        fontSize: 13, fontWeight: FontWeight.w500, color: context.textPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Contact your fleet manager to assign a shuttle',
                                    style: GoogleFonts.poppins(fontSize: 11, color: context.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Route stops (only show if route assigned)
                    if (_currentRoute != null) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Route Stops',
                              style: GoogleFonts.poppins(
                                  fontSize: 18, fontWeight: FontWeight.bold, color: context.textPrimary),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_stops.length} Stop${_stops.length == 1 ? '' : 's'}',
                              style: GoogleFonts.poppins(
                                  fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryGreen),
                            ),
                          ),
                        ],
                      ),
              const SizedBox(height: 12),
              _StopsTimeline(stops: _stops),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Greeting header: "Welcome back!" and an online/trip-status pill.
/// Neutral card background (white in light mode, dark gray in dark mode) —
/// no branded green fill, matching the rest of the app's card styling.
class _HomeHeader extends StatelessWidget {
  final String name;
  final bool tripStarted;

  const _HomeHeader({required this.name, required this.tripStarted});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -16,
            bottom: -10,
            child: Icon(
              Icons.directions_bus_filled_rounded,
              size: 120,
              color: context.divider,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_greeting, $name 👋',
                  style: GoogleFonts.poppins(fontSize: 14, color: context.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Welcome back!',
                  style: GoogleFonts.poppins(
                      fontSize: 26, fontWeight: FontWeight.bold, color: context.textPrimary),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: context.fieldFill,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tripStarted ? 'Trip in progress' : "You're online and ready",
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w600, color: context.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TripStatusCard extends StatelessWidget {
  final bool isStarted;
  final bool isLoading;
  final bool locationSharing;
  final AnimationController pulseController;
  final VoidCallback? onToggle;

  const _TripStatusCard({
    required this.isStarted,
    required this.isLoading,
    required this.locationSharing,
    required this.pulseController,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = isStarted
        ? (locationSharing ? 'Sharing your live location' : 'Starting location sharing…')
        : 'Press start to begin your route';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.divider),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: pulseController,
            builder: (_, child) => Transform.scale(
              scale: isStarted ? 1.0 + pulseController.value * 0.12 : 1.0,
              child: child,
            ),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isStarted ? Icons.directions_bus : Icons.directions_bus_outlined,
                color: AppColors.primaryGreen,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isStarted ? 'Trip Active' : 'Ready to Start',
                  style: GoogleFonts.poppins(
                      fontSize: 17, fontWeight: FontWeight.bold, color: context.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(fontSize: 12, color: context.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _PillActionButton(
            label: isStarted ? 'End Trip' : 'Start Route',
            icon: isStarted ? Icons.stop_rounded : Icons.play_arrow_rounded,
            isLoading: isLoading,
            danger: isStarted,
            onTap: onToggle,
          ),
        ],
      ),
    );
  }
}

class _PillActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final bool danger;
  final VoidCallback? onTap;

  const _PillActionButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.danger,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = danger ? AppColors.error : AppColors.primaryGreen;
    return SizedBox(
      height: 42,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ],
              ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final DriverRoute route;
  const _RouteCard({required this.route});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.alt_route, color: AppColors.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  route.name,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700, fontSize: 15, color: context.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.circle_outlined, size: 14, color: AppColors.primaryGreen),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  route.startName,
                  style: GoogleFonts.poppins(fontSize: 12, color: context.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(height: 1, color: context.divider),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.location_on, size: 14, color: AppColors.primaryGreen),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  route.endName,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.poppins(fontSize: 12, color: context.textSecondary),
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

class _StopsTimeline extends StatelessWidget {
  final List<Stop> stops;
  const _StopsTimeline({required this.stops});

  @override
  Widget build(BuildContext context) {
    if (stops.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.divider),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.signpost_outlined, size: 40, color: context.textSecondary),
              const SizedBox(height: 12),
              Text(
                'No stops on this route',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Stops will appear here once they\'re added to your route.',
                style: GoogleFonts.poppins(fontSize: 12, color: context.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: stops.asMap().entries.map((e) {
        final isFirst = e.key == 0;
        final isLast = e.key == stops.length - 1;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isFirst ? AppColors.primaryGreen : AppColors.primaryGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${e.key + 1}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isFirst ? Colors.white : AppColors.primaryGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  e.value.name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: isFirst || isLast ? FontWeight.w600 : FontWeight.normal,
                    color: context.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ShuttleCard extends StatelessWidget {
  final ShuttleInfo shuttle;
  const _ShuttleCard({required this.shuttle});

  String _statusLabel() {
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

  Color _statusColor() {
    switch (shuttle.status.toLowerCase()) {
      case 'active':
        return AppColors.success;
      case 'idle':
        return AppColors.warning;
      case 'offline':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: context.fieldFill, shape: BoxShape.circle),
            child: Icon(Icons.directions_bus, color: AppColors.primaryGreen, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Assigned Shuttle',
                    style: GoogleFonts.poppins(fontSize: 12, color: context.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  shuttle.name,
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w700, color: context.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${shuttle.plateNumber} • ${shuttle.capacity} seats',
                  style: GoogleFonts.poppins(fontSize: 12, color: context.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _statusColor().withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: _statusColor(), shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(
                  _statusLabel(),
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
