import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'contact_support_screen.dart';
import 'safety_screen.dart';
import 'support_form_screen.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textPrimary),
        title: Text(
          'Support',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: context.textPrimary,
          ),
        ),
        centerTitle: false,
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
                    Icons.support_agent_outlined,
                    color: AppColors.primaryGreen,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "We're here to help you",
                        style: GoogleFonts.poppins(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Get answers, report issues, or just reach out to our team '
                        'to make your shuttle experience smoother.',
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
            _SupportMenuRow(
              icon: Icons.bug_report_outlined,
              label: 'Report a bug',
              description: "Something not working right? Tell us what happened so we can fix it fast.",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SupportFormScreen(
                    title: 'Report a bug',
                    ticketType: 'bug',
                  ),
                ),
              ),
            ),
            const _RowDivider(),
            _SupportMenuRow(
              icon: Icons.lightbulb_outline,
              label: 'Feature request',
              description: "Got an idea that would make CampRide better? Tell us what you'd like to see.",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SupportFormScreen(
                    title: 'Feature request',
                    ticketType: 'feature',
                  ),
                ),
              ),
            ),
            const _RowDivider(),
            _SupportMenuRow(
              icon: Icons.chat_bubble_outline,
              label: 'Leave feedback',
              description: 'Rate your overall experience and leave a comment to help us keep improving.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SupportFormScreen(
                    title: 'Leave feedback',
                    ticketType: 'feedback',
                  ),
                ),
              ),
            ),
            const _RowDivider(),
            _SupportMenuRow(
              icon: Icons.shield_outlined,
              label: 'Safety',
              description: "Read helpful do's, don'ts, and answers to common questions about riding safely.",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SafetyScreen()),
              ),
            ),
            const _RowDivider(),
            _SupportMenuRow(
              icon: Icons.email_outlined,
              label: 'Contact support email',
              description: 'Prefer email? Reach our support team directly for anything not covered above.',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ContactSupportScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tappable Support row: icon, title, a short one-line description, and
/// a trailing chevron.
class _SupportMenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  const _SupportMenuRow({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: context.textPrimary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: context.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(Icons.chevron_right, color: context.textSecondary, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, thickness: 1, color: context.divider);
  }
}
