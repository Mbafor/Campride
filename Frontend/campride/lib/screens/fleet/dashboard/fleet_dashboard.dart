import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import 'fleet_manager_dashboard.dart';
import '../drivers/drivers_list_screen.dart';
import '../shuttles/shuttles_list_screen.dart';
import '../account/fleet_manager_account_screen.dart';

class FleetDashboard extends StatefulWidget {
  const FleetDashboard({super.key});

  @override
  State<FleetDashboard> createState() => _FleetDashboardState();
}

class _FleetDashboardState extends State<FleetDashboard> {
  int _currentIndex = 0;

  void _goToTab(int index) => setState(() => _currentIndex = index);

  late final List<Widget> _screens = [
    FleetManagerDashboard(
      onDriversTap: () => _goToTab(1),
      onShuttlesTap: () => _goToTab(2),
    ),
    const DriversListScreen(),
const ShuttlesListScreen(embedded: true),
    const FleetManagerAccountScreen(),
  ];

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard'),
    _NavItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Drivers'),
    _NavItem(icon: Icons.airport_shuttle_outlined, activeIcon: Icons.airport_shuttle, label: 'Shuttles'),
    _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Account'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        items: _navItems,
        onTap: _goToTab,
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border(top: BorderSide(color: context.divider, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: items.asMap().entries.map((e) {
              final isActive = e.key == currentIndex;
              final color = isActive ? AppColors.primaryGreen : context.textSecondary;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(e.key),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(isActive ? e.value.activeIcon : e.value.icon, size: 24, color: color),
                      const SizedBox(height: 4),
                      Text(
                        e.value.label,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
