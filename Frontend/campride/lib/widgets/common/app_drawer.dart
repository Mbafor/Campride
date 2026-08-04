import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/authentication_provider.dart';
import '../../screens/common/safety_screen.dart';
import '../../screens/common/support_screen.dart';
import '../../screens/student/rides/rides_screen.dart';
import '../../screens/student/alerts/alerts_screen.dart';
import '../../screens/student/profile/student_profile_screen.dart';
import '../../screens/student/settings/settings_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';
import 'profile_avatar_view.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: context.scaffoldBg,
      width: MediaQuery.of(context).size.width * 0.82,
      child: SafeArea(
        child: Column(
          children: [
            // Profile header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StudentProfileScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Consumer<AuthenticationProvider>(
                  builder: (context, auth, _) {
                    final userName = auth.user?.name ?? 'Guest';
                    return Row(
                      children: [
                        ProfileAvatarView(photoUrl: auth.user?.photoUrl, name: auth.user?.name, size: 52),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Hi $userName',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimary,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: context.textSecondary, size: 26),
                      ],
                    );
                  },
                ),
              ),
            ),
            // Menu items
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _DrawerItem(
                        label: 'Rides',
                        icon: Icons.directions_bus_outlined,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const RidesScreen()));
                        },
                      ),
                      _DrawerItem(
                        label: 'Alerts',
                        icon: Icons.notifications_outlined,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen()));
                        },
                      ),
                      _DrawerItem(
                        label: 'Safety',
                        icon: Icons.shield_outlined,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SafetyScreen()),
                          );
                        },
                      ),
                      _DrawerItem(
                        label: 'Settings',
                        icon: Icons.settings,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                        },
                      ),
                      _DrawerItem(
                        label: 'Support',
                        icon: Icons.support_agent_outlined,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SupportScreen()),
                          );
                        },
                      ),
                    ],
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
  final IconData icon;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primaryGreen, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: context.textPrimary,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.primaryGreen, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
