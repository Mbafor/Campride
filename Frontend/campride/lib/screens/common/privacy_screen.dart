import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

/// Privacy screen reached from Settings. Plain-language explanation of
/// what CampRide collects, why, who can see it, and what controls
/// students have over their own data.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textPrimary),
        title: Text(
          'Privacy',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: context.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.privacy_tip_outlined,
                    color: AppColors.primaryGreen,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your privacy matters',
                        style: GoogleFonts.poppins(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Here\'s what CampRide collects, how it\'s used, and the '
                        'controls you have over your own information.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: context.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            const _PrivacySection(
              icon: Icons.badge_outlined,
              title: 'Information we collect',
              body:
                  'Your name, email, phone number, and optional profile photo and '
                  'gender. When you request a ride, we also use your device\'s '
                  'location and keep a record of the ride once it\'s complete.',
            ),
            const _PrivacySection(
              icon: Icons.tune,
              title: 'How we use it',
              body:
                  'To match you with nearby shuttles, show you live tracking, send '
                  'ride and account notifications, and improve the reliability and '
                  'safety of CampRide.',
            ),
            const _PrivacySection(
              icon: Icons.visibility_outlined,
              title: 'Who can see it',
              body:
                  'Drivers see your name and pickup/dropoff points only for rides '
                  'you request. Fleet managers and admins can see ride records for '
                  'safety and operations. We never sell your data to third parties.',
            ),
            const _PrivacySection(
              icon: Icons.location_on_outlined,
              title: 'Location data',
              body:
                  'Location is only used while you\'re requesting or on a ride, to '
                  'find nearby shuttles and track your trip. You can turn off '
                  'location access in your phone settings, but this will limit '
                  'your ability to request rides.',
            ),
            const _PrivacySection(
              icon: Icons.lock_outline,
              title: 'How we protect it',
              body:
                  'Passwords and account credentials are stored securely and never '
                  'shown in plain text. We use industry-standard practices to keep '
                  'your data safe.',
            ),
            const _PrivacySection(
              icon: Icons.tune_outlined,
              title: 'Your controls',
              body:
                  'You can update your profile details anytime from the Profile '
                  'screen, and permanently delete your account and data from '
                  'Settings whenever you choose.',
            ),

            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.fieldFill,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.mail_outline, color: context.textSecondary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Have a question about your privacy or data? Reach out to us '
                      'through Support.',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: context.textSecondary,
                        height: 1.4,
                      ),
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

class _PrivacySection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _PrivacySection({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primaryGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: context.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
