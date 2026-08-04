import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../providers/authentication_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/profile_avatar_view.dart';
import '../../common/coming_soon_screen.dart';
import '../../common/safety_screen.dart';
import '../../common/support_screen.dart';
import '../profile/student_profile_screen.dart';
import '../settings/settings_screen.dart';

/// ACCOUNT tab — name + 5.0 rating header, "Safety checkup" promo card,
/// and menu rows (Profile, Settings, Saved places, Support).
class StudentAccountScreen extends StatelessWidget {
  const StudentAccountScreen({super.key});

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
                  final name = auth.user?.name ?? 'User';
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
                              'Learn ways to make rides safer',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const _DashedProgressRing(size: 30),
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
                      MaterialPageRoute(builder: (_) => const StudentProfileScreen()),
                    ),
                  ),
                  _MenuRow(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                  _MenuRow(
                    icon: Icons.location_on_outlined,
                    label: 'Saved places',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ComingSoonScreen(
                          title: 'Saved places',
                          icon: Icons.location_on_outlined,
                        ),
                      ),
                    ),
                  ),
                  _MenuRow(
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

/// Decorative dashed progress ring for the Safety checkup card, matching
/// the mockup's incomplete-checklist icon.
class _DashedProgressRing extends StatelessWidget {
  final double size;
  const _DashedProgressRing({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _DashedRingPainter()),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    final paint = Paint()
      ..color = AppColors.textSecondaryLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    const dashCount = 8;
    const gapFraction = 0.35;
    final sweepPerDash = (2 * pi / dashCount) * (1 - gapFraction);
    final sweepPerGap = (2 * pi / dashCount) * gapFraction;

    double angle = -pi / 2;
    for (var i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        angle,
        sweepPerDash,
        false,
        paint,
      );
      angle += sweepPerDash + sweepPerGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(icon, size: 22, color: context.textPrimary),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Divider(height: 1, thickness: 1, color: context.divider),
      ],
    );
  }
}
