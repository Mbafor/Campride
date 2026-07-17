import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/authentication_provider.dart';
import '../../../services/shuttle_service.dart';
import '../../../theme/app_colors.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthenticationProvider>(
      builder: (context, auth, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Super Admin',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome message
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${auth.user?.name ?? "Admin"}',
                      style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'System administration and oversight',
                      style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Stats overview
                _StatsRow(),
                const SizedBox(height: 32),

                // Quick Navigation
                Text(
                  'Management',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _NavigationCard(
                  icon: Icons.people,
                  title: 'Drivers & Staff',
                  subtitle: 'Manage drivers and fleet managers',
                  onTap: () => _navigateTo(context, 'staff'),
                ),
                const SizedBox(height: 10),
                _NavigationCard(
                  icon: Icons.airport_shuttle,
                  title: 'Shuttles',
                  subtitle: 'View and manage shuttles',
                  onTap: () => _navigateTo(context, 'shuttles'),
                ),
                const SizedBox(height: 10),
                _NavigationCard(
                  icon: Icons.route,
                  title: 'Routes & Stops',
                  subtitle: 'Manage routes and stops',
                  onTap: () => _navigateTo(context, 'routes'),
                ),
                const SizedBox(height: 10),
                _NavigationCard(
                  icon: Icons.location_on_outlined,
                  title: 'Live Map',
                  subtitle: 'Track fleet location (Phase 5)',
                  onTap: () => _navigateTo(context, 'map'),
                  isPlaceholder: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateTo(BuildContext context, String section) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigating to $section...')),
    );
  }
}

class _StatsRow extends StatefulWidget {
  @override
  State<_StatsRow> createState() => _StatsRowState();
}

class _StatsRowState extends State<_StatsRow> {
  final _shuttleService = ShuttleService();
  int _totalShuttles = 0;
  int _totalRoutes = 0;
  int _totalDrivers = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final auth = context.read<AuthenticationProvider>();
    if (auth.accessToken == null) {
      setState(() => _loading = false);
      return;
    }

    final driversResult = await _shuttleService.listDrivers(accessToken: auth.accessToken!);
    final shuttlesResult = await _shuttleService.listShuttles(accessToken: auth.accessToken!);
    final routesResult = await _shuttleService.listRoutes(accessToken: auth.accessToken!);

    if (mounted) {
      setState(() {
        _totalDrivers = driversResult.data?.length ?? 0;
        _totalShuttles = shuttlesResult.data?.length ?? 0;
        _totalRoutes = routesResult.data?.length ?? 0;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.people_outline,
              label: 'Drivers',
              value: '$_totalDrivers',
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.directions_bus_outlined,
              label: 'Shuttles',
              value: '$_totalShuttles',
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.route_outlined,
              label: 'Routes',
              value: '$_totalRoutes',
              color: AppColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondaryLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isPlaceholder;

  const _NavigationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isPlaceholder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isPlaceholder ? Colors.grey[200] : AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isPlaceholder ? AppColors.textSecondaryLight : AppColors.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isPlaceholder ? AppColors.textSecondaryLight : AppColors.primaryGreen,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
