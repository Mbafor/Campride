import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/app_constants.dart';
import '../../../models/route_model.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/buttons/custom_button.dart';
import '../../../widgets/common/section_header.dart';

class StartTripScreen extends StatefulWidget {
  const StartTripScreen({super.key});

  @override
  State<StartTripScreen> createState() => _StartTripScreenState();
}

class _StartTripScreenState extends State<StartTripScreen>
    with SingleTickerProviderStateMixin {
  bool _tripStarted = false;
  bool _loading = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _toggleTrip() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _tripStarted = !_tripStarted;
        _loading = false;
        if (_tripStarted) {
          _pulseController.repeat(reverse: true);
        } else {
          _pulseController.stop();
          _pulseController.reset();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final routes = RouteModel.mockRoutes();
    final activeRoute = routes.first;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TripStatusCard(isStarted: _tripStarted, pulseController: _pulseController),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Current Route'),
          const SizedBox(height: 12),
          _RouteCard(route: activeRoute),
          const SizedBox(height: 24),
          _StopsTimeline(stops: activeRoute.stops),
          const SizedBox(height: 32),
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
              child: Text(
                'Trip in progress — passengers can track you',
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.success),
              ),
            ),
          ],
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isStarted ? 'Trip Active' : 'Ready to Start',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                isStarted ? 'Live tracking enabled' : 'Press Start to begin',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
          if (isStarted) ...[
            const Spacer(),
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
  final RouteModel route;
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
                    AppConstants.mockRoute,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: AppColors.textSecondaryLight),
                const SizedBox(width: 4),
                Text(
                  '${route.startTime} - ${route.endTime}',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.refresh, size: 14, color: AppColors.textSecondaryLight),
                const SizedBox(width: 4),
                Text(
                  'Every ${route.frequency} min',
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

class _StopsTimeline extends StatelessWidget {
  final List<String> stops;
  const _StopsTimeline({required this.stops});

  @override
  Widget build(BuildContext context) {
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
                    e.value,
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
