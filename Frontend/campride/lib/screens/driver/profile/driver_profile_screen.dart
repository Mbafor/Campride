import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../models/user_model.dart';
import '../../../providers/authentication_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../routes/route_names.dart';
import '../../../services/shuttle_service.dart';
import '../../../theme/app_colors.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthenticationProvider>(
      builder: (context, auth, _) {
        final driver = auth.user;
        if (driver == null) {
          return Center(
            child: Text(
              'User data not available',
              style: GoogleFonts.poppins(color: AppColors.textSecondaryLight),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _DriverHeader(driver: driver),
              const SizedBox(height: 20),
              _ComingSoonStats(),
              const SizedBox(height: 16),
              _VehicleCard(),
              const SizedBox(height: 16),
              _SettingsCard(),
              const SizedBox(height: 24),
              _SignOutButton(),
            ],
          ),
        );
      },
    );
  }
}

class _DriverHeader extends StatelessWidget {
  final UserModel driver;
  const _DriverHeader({required this.driver});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryGreenDark, AppColors.primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.accentGold,
                child: Text(
                  driver.name.substring(0, 1),
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreenDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                child: const Icon(Icons.check, size: 12, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            driver.name,
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            driver.email,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Verified Driver',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.dividerLight),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.textSecondaryLight, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trip Statistics Coming Soon',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Trips, passengers, and rating data will appear here once you complete rides',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondaryLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatefulWidget {
  const _VehicleCard();

  @override
  State<_VehicleCard> createState() => _VehicleCardState();
}

class _VehicleCardState extends State<_VehicleCard> {
  final _shuttleService = ShuttleService();
  ShuttleInfo? _shuttle;
  DriverRoute? _route;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVehicleData();
  }

  Future<void> _loadVehicleData() async {
    final auth = context.read<AuthenticationProvider>();
    if (auth.accessToken == null) {
      setState(() => _loading = false);
      return;
    }

    // Load shuttle and route in parallel
    final shuttleResult = await _shuttleService.getDriverShuttle(accessToken: auth.accessToken!);
    final routeResult = await _shuttleService.getDriverRoute(accessToken: auth.accessToken!);

    if (mounted) {
      setState(() {
        _shuttle = shuttleResult.data;
        _route = routeResult.data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
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
            Text('Vehicle & Route Info', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            if (_shuttle != null) ...[
              _InfoRow(icon: Icons.directions_bus_outlined, label: 'Plate Number', value: _shuttle!.plateNumber),
              _InfoRow(icon: Icons.category_outlined, label: 'Capacity', value: '${_shuttle!.capacity} seats'),
              _InfoRow(
                icon: Icons.circle,
                label: 'Shuttle Status',
                value: _shuttle!.status.substring(0, 1).toUpperCase() + _shuttle!.status.substring(1),
              ),
            ] else
              _InfoRow(icon: Icons.directions_bus_outlined, label: 'Shuttle', value: 'Not assigned'),
            const SizedBox(height: 8),
            if (_route != null)
              _InfoRow(icon: Icons.route_outlined, label: 'Assigned Route', value: _route!.name)
            else
              _InfoRow(icon: Icons.route_outlined, label: 'Assigned Route', value: 'Not assigned'),
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

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryGreen),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondaryLight)),
          const Spacer(),
          Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            Consumer<ThemeProvider>(
              builder: (context, theme, _) => Row(
                children: [
                  const Icon(Icons.dark_mode_outlined, size: 20, color: AppColors.primaryGreen),
                  const SizedBox(width: 12),
                  Text('Dark Mode', style: GoogleFonts.poppins(fontSize: 14)),
                  const Spacer(),
                  Switch(
                    value: theme.isDarkMode,
                    onChanged: (_) => theme.toggleTheme(),
                    activeColor: AppColors.primaryGreen,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          await context.read<AuthenticationProvider>().signOut();
          if (context.mounted) context.go(RouteNames.welcome);
        },
        icon: const Icon(Icons.logout_rounded, color: AppColors.error),
        label: Text(
          'Sign Out',
          style: GoogleFonts.poppins(color: AppColors.error, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
