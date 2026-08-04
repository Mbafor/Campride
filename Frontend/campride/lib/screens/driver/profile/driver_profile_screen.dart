import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../providers/authentication_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/profile_avatar_view.dart';
import '../../../widgets/common/settings_menu_row.dart';
import '../../common/safety_screen.dart';
import '../../common/support_screen.dart';
import '../../student/profile/student_profile_screen.dart';
import '../../student/settings/settings_screen.dart';

/// Driver ACCOUNT tab — mirrors the student Account tab exactly: name +
/// rating header, "Safety checkup" promo card, and menu rows (Profile,
/// Settings, Support). Profile/Settings/Support are the same shared
/// screens the student app uses — they only touch the generic
/// AuthenticationProvider, so they work identically for a driver account.
class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 18),

            // ── Profile header: name + rating + avatar ──────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Consumer<AuthenticationProvider>(
                builder: (context, auth, _) {
                  final name = auth.user?.name ?? 'Driver';
                  final photoUrl = auth.user?.photoUrl;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: context.divider,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star, size: 14, color: Colors.amber[700]),
                                  const SizedBox(width: 4),
                                  Text(
                                    '5.0',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const StudentProfileScreen()),
                        ),
                        child: ProfileAvatarView(photoUrl: photoUrl, name: name, size: 54),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // ── Safety checkup card ─────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SafetyScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.fieldFill,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Safety checkup',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Learn ways to make trips safer',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.chevron_right, color: context.textSecondary),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Menu rows ───────────────────────────────────
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  SettingsMenuRow(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StudentProfileScreen()),
                    ),
                  ),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SettingsDivider()),
                  SettingsMenuRow(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SettingsDivider()),
                  SettingsMenuRow(
                    icon: Icons.support_agent_outlined,
                    label: 'Support',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SupportScreen()),
                    ),
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
