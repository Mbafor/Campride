import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/authentication_provider.dart';
import '../../../services/shuttle_service.dart';
import '../../../theme/app_colors.dart';

class FleetManagerDashboard extends StatelessWidget {
  const FleetManagerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthenticationProvider>(
      builder: (context, auth, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Fleet Manager',
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
                      'Welcome, ${auth.user?.name ?? "Fleet Manager"}',
                      style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your fleet operations',
                      style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Stats row
                _StatsRow(),
                const SizedBox(height: 32),

                // Quick Navigation
                Text(
                  'Quick Navigation',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _NavigationCard(
                  icon: Icons.person_outline,
                  title: 'Drivers Management',
                  subtitle: 'Manage drivers and assignments',
                  onTap: () => _navigateTo(context, 'drivers'),
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
    // TODO: Implement navigation to respective sections
    // This will be replaced with actual navigation/routing
  }
}

class _StatsRow extends StatefulWidget {
  @override
  State<_StatsRow> createState() => _StatsRowState();
}

class _StatsRowState extends State<_StatsRow> {
  final _shuttleService = ShuttleService();
  int _totalDrivers = 0;
  int _totalShuttles = 0;
  int _activeShuttles = 0;
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

    if (mounted) {
      int active = 0;
      if (shuttlesResult.success && shuttlesResult.data != null) {
        active = shuttlesResult.data!.where((s) => s.status.toLowerCase() == 'active').length;
      }

      setState(() {
        _totalDrivers = driversResult.data?.length ?? 0;
        _totalShuttles = shuttlesResult.data?.length ?? 0;
        _activeShuttles = active;
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
              icon: Icons.person_outline,
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
              icon: Icons.circle,
              label: 'Active',
              value: '$_activeShuttles',
              color: AppColors.success,
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

class _TabNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  const _TabNavigation({
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Drivers',
              isActive: selectedIndex == 0,
              onPressed: () => onTabChanged(0),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TabButton(
              label: 'Shuttles',
              isActive: selectedIndex == 1,
              onPressed: () => onTabChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(
          color: isActive ? AppColors.primaryGreen : AppColors.dividerLight,
          width: isActive ? 2 : 1,
        ),
        backgroundColor: isActive ? AppColors.primaryGreen.withOpacity(0.05) : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          color: isActive ? AppColors.primaryGreen : AppColors.textSecondaryLight,
        ),
      ),
    );
  }
}
