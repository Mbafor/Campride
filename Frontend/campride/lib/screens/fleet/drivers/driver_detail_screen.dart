import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/authentication_provider.dart';
import '../../../services/shuttle_service.dart';
import '../../../theme/app_colors.dart';

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

  @override
  void initState() {
    super.initState();
    _loadDriver();
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
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
          title: Text('Driver Details', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        body: Center(
          child: Text(
            'Driver not found',
            style: GoogleFonts.poppins(color: AppColors.textSecondaryLight),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
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

            // Ride History Section (Phase 5 Placeholder)
            _RideHistorySection(),
            const SizedBox(height: 24),

            // Live Location Section (Phase 5 Placeholder)
            _LiveLocationSection(),
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
                    style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondaryLight),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Divider(color: AppColors.dividerLight),
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

class _RideHistorySection extends StatelessWidget {
  const _RideHistorySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border.all(color: Colors.blue[200]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ride history — available in Phase 5',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue[900],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Trip History (Example Preview)',
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        _DummyTripCard(
          date: 'Nov 15, 2024',
          time: '9:00 AM - 10:30 AM',
          route: 'Downtown Loop',
          passengers: 12,
        ),
        const SizedBox(height: 8),
        _DummyTripCard(
          date: 'Nov 14, 2024',
          time: '2:15 PM - 3:45 PM',
          route: 'University Route',
          passengers: 15,
        ),
        const SizedBox(height: 8),
        _DummyTripCard(
          date: 'Nov 13, 2024',
          time: '8:00 AM - 9:15 AM',
          route: 'Airport Express',
          passengers: 8,
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            '⚠️ These are example rows only — not real data',
            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondaryLight, fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }
}

class _DummyTripCard extends StatelessWidget {
  final String date;
  final String time;
  final String route;
  final int passengers;

  const _DummyTripCard({
    required this.date,
    required this.time,
    required this.route,
    required this.passengers,
  });

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
                Icon(Icons.history, size: 18, color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Text(
                        date,
                        style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Completed',
                    style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.success),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: AppColors.textSecondaryLight),
                const SizedBox(width: 6),
                Text(
                  time,
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondaryLight),
                ),
                const Spacer(),
                Icon(Icons.people, size: 14, color: AppColors.textSecondaryLight),
                const SizedBox(width: 4),
                Text(
                  '$passengers passengers',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondaryLight),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveLocationSection extends StatelessWidget {
  const _LiveLocationSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            border: Border.all(color: Colors.orange[200]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[700], size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Live location tracking — available in Phase 5',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange[900],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Live Location (Static Example)',
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 48,
                        color: AppColors.primaryGreen,
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'In Session',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: AppColors.primaryGreen),
                    const SizedBox(width: 8),
                    Text(
                      'Current Location: Downtown District',
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.speed, size: 16, color: AppColors.primaryGreen),
                    const SizedBox(width: 8),
                    Text(
                      'Speed: 32 km/h',
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.directions_bus, size: 16, color: AppColors.primaryGreen),
                    const SizedBox(width: 8),
                    Text(
                      'Route: Downtown Loop',
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    '⚠️ This is a static example — real-time tracking coming in Phase 5',
                    style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondaryLight, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondaryLight),
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
