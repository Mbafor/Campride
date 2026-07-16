import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../models/user_model.dart';
import '../../../providers/authentication_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../routes/route_names.dart';
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
              _DriverStats(),
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

class _DriverStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(icon: Icons.directions_bus, label: 'Total Trips', value: '142')),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(icon: Icons.people, label: 'Passengers', value: '3,847')),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(icon: Icons.star, label: 'Rating', value: '4.8')),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryGreen, size: 22),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondaryLight), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vehicle Info', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            _InfoRow(icon: Icons.directions_bus_outlined, label: 'Plate Number', value: 'GR 1234-20'),
            _InfoRow(icon: Icons.category_outlined, label: 'Capacity', value: '32 seats'),
            _InfoRow(icon: Icons.route_outlined, label: 'Assigned Route', value: 'Main Campus Loop'),
            _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: '+233 20 000 0002'),
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
