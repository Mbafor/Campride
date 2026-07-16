import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/authentication_provider.dart';
import '../../../services/shuttle_service.dart';
import '../../../theme/app_colors.dart';
import '../drivers/drivers_list_screen.dart';
import '../shuttles/shuttles_list_screen.dart';

class FleetManagerDashboard extends StatefulWidget {
  const FleetManagerDashboard({super.key});

  @override
  State<FleetManagerDashboard> createState() => _FleetManagerDashboardState();
}

class _FleetManagerDashboardState extends State<FleetManagerDashboard> {
  int _selectedTabIndex = 0;
  final _shuttleService = ShuttleService();

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const DriversListScreen(),
      const ShuttlesListScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Fleet Manager',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          _StatsRow(),
          const SizedBox(height: 16),
          _TabNavigation(
            selectedIndex: _selectedTabIndex,
            onTabChanged: (index) => setState(() => _selectedTabIndex = index),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _screens[_selectedTabIndex],
          ),
        ],
      ),
    );
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
