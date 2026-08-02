import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../live_shuttles_screen.dart';
import '../alerts/alerts_screen.dart';
import '../account/student_account_screen.dart';
import '../../../widgets/common/app_drawer.dart';
import '../../../theme/app_colors.dart';

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
      backgroundColor: Colors.white,
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: const [
              LiveShuttlesScreen(), // Home tab (index 0)
              AlertsScreen(),       // Alerts tab (index 1)
              StudentAccountScreen(), // Account tab (index 2)
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.menu, size: 22, color: Colors.black87),
                    ),
                  ),
                ),
              ),
            ),
          // Floating search bar — visible on Home tab
          if (_currentIndex == 0)
            Positioned(
              bottom: 80,
              left: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Where to?',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  style: GoogleFonts.poppins(fontSize: 14),
                  readOnly: true,
                  onTap: () {
                    // TODO: Navigate to Route screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Route screen coming soon')),
                    );
                  },
                ),
              ),
            ),
          // Recenter button — visible on Home tab
          if (_currentIndex == 0)
            Positioned(
              bottom: 80,
              right: 16,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryGreen,
                elevation: 4,
                onPressed: () {
                  // TODO: Implement recenter to user location
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Recenter to my location')),
                  );
                },
                child: const Icon(Icons.my_location, size: 20),
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
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
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
                icon: Icons.calendar_today_outlined,
                activeIcon: Icons.calendar_today,
                label: 'Alerts',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavTab(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Account',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
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
    final color = isActive ? AppColors.primaryGreen : Colors.grey[500]!;
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
