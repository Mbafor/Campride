import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../live_shuttles_screen.dart';
import '../alerts/alerts_screen.dart';
import '../rides/rides_screen.dart';
import '../account/student_account_screen.dart';
import '../route/route_confirm_screen.dart';
import '../../../widgets/common/app_drawer.dart';
import '../../../widgets/common/stop_search_sheet.dart';
import '../../../theme/app_theme.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: const [
              LiveShuttlesScreen(embedded: true), // Home tab (index 0)
              AlertsScreen(), // Alerts tab (index 1)
              RidesScreen(), // Rides tab (index 2)
              StudentAccountScreen(), // Account tab (index 3)
            ],
          ),
          // Floating hamburger — visible on Home tab
          if (_currentIndex == 0)
            Builder(
              builder: (innerContext) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, top: 12),
                  child: GestureDetector(
                    onTap: () => Scaffold.of(innerContext).openDrawer(),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.menu,
                        size: 22,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Floating search card — visible on Home tab
          if (_currentIndex == 0)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                // Translucent "frosted" panel spanning from the search bar
                // down to the bottom navigation, like ride-hailing apps.
                decoration: BoxDecoration(
                  color: context.cardBg.withValues(alpha: 0.92),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: context.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Rectangular search input matching the pull-up sheet width
                    Container(
                      decoration: BoxDecoration(
                        color: context.fieldFill,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: context.fieldBorder,
                          width: 1.5,
                        ),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Where to?',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 15,
                            color: context.textSecondary,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: context.textSecondary,
                            size: 20,
                          ),
                          suffixIcon: Icon(
                            Icons.directions_bus_outlined,
                            color: context.textSecondary,
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: context.textPrimary,
                        ),
                        readOnly: true,
                        onTap: () async {
                          final stop = await showStopSearchSheet(context);
                          if (stop != null && context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    RouteConfirmScreen(initialDropoff: stop),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

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
            children: [
              _NavTab(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavTab(
                icon: Icons.notifications_outlined,
                activeIcon: Icons.notifications,
                label: 'Alerts',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavTab(
                icon: Icons.directions_bus_outlined,
                activeIcon: Icons.directions_bus,
                label: 'Rides',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavTab(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Account',
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primaryGreen : context.textSecondary;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              label,
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
  }
}
