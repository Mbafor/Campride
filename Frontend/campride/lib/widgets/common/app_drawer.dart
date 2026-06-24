import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../routes/route_names.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF2F2F2),
      width: MediaQuery.of(context).size.width * 0.82,
      child: SafeArea(
        child: Column(
          children: [
            // Profile header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2C2C2C),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, size: 30, color: Color(0xFFBDBDBD)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Hi Edwin',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFF757575), size: 26),
                  ],
                ),
              ),
            ),
            // Menu items
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _DrawerItem(label: 'Request History', onTap: () => Navigator.pop(context)),
                    _DrawerItem(label: 'Couriers', onTap: () => Navigator.pop(context)),
                    _DrawerItem(label: 'Notifications', onTap: () => Navigator.pop(context)),
                    _DrawerItem(label: 'Safety', onTap: () => Navigator.pop(context)),
                    _DrawerItem(label: 'Settings', onTap: () => Navigator.pop(context)),
                    _DrawerItem(label: 'Help', onTap: () => Navigator.pop(context)),
                    _DrawerItem(label: 'Support', onTap: () => Navigator.pop(context)),
                  ],
                ),
              ),
            ),
            // Driver Mode button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  context.go(RouteNames.driverDashboard);
                },
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Driver Mode',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFBDBDBD), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
