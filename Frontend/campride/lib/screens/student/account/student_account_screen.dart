import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../providers/authentication_provider.dart';
import '../../../theme/app_colors.dart';
import '../profile/student_profile_screen.dart';
import '../settings/settings_screen.dart';

/// ACCOUNT tab — matches the design screenshot:
/// name + 5.0 rating header, quick action buttons (Help / Safety / Inbox),
/// "Safety checkup" promotion card, and menu rows
/// (Profile, Settings, Saved places, Support).
class StudentAccountScreen extends StatelessWidget {
  const StudentAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: ACCOUNT ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Text(
                'ACCOUNT',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Profile header: name + rating ───────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Consumer<AuthenticationProvider>(
                builder: (context, auth, _) {
                  final name = auth.user?.name ?? 'User';
                  return Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.person,
                            size: 32, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.star,
                                    size: 16, color: Colors.amber[700]),
                                const SizedBox(width: 4),
                                Text(
                                  '5.0',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // ── Quick action buttons: Help / Safety / Inbox ─
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickButton(
                      icon: Icons.help_outline,
                      label: 'Help',
                      onTap: () => _showComingSoon(context, 'Help'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickButton(
                      icon: Icons.health_and_safety_outlined,
                      label: 'Safety',
                      onTap: () => _showComingSoon(context, 'Safety'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickButton(
                      icon: Icons.inbox_outlined,
                      label: 'Inbox',
                      onTap: () => _showComingSoon(context, 'Inbox'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Safety checkup card ─────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => _showComingSoon(context, 'Safety checkup'),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey[200]!, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: AppColors.primaryGreen,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Safety checkup',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Learn ways to make rides safer',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          color: Colors.grey[400], size: 22),
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
                  _MenuRow(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const StudentProfileScreen()),
                    ),
                  ),
                  _MenuRow(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen()),
                    ),
                  ),
                  _MenuRow(
                    icon: Icons.bookmark_border,
                    label: 'Saved places',
                    onTap: () => _showComingSoon(context, 'Saved places'),
                  ),
                  _MenuRow(
                    icon: Icons.support_outlined,
                    label: 'Support',
                    onTap: () => _showComingSoon(context, 'Support'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature is coming soon',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 74,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: Colors.black87),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              children: [
                Icon(icon, size: 22, color: Colors.black87),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ),
        Divider(height: 1, thickness: 1, color: Colors.grey[100]),
      ],
    );
  }
}
