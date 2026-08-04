import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/settings_menu_row.dart';
import 'contact_support_screen.dart';
import 'support_form_screen.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Support',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            SettingsMenuRow(
              icon: Icons.bug_report_outlined,
              label: 'Report a bug',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SupportFormScreen(
                    title: 'Report a bug',
                    ticketType: 'bug',
                    hint: 'What went wrong? Include what you were doing when it happened.',
                  ),
                ),
              ),
            ),
            const SettingsDivider(),
            SettingsMenuRow(
              icon: Icons.lightbulb_outline,
              label: 'Feature request',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SupportFormScreen(
                    title: 'Feature request',
                    ticketType: 'feature',
                    hint: 'What would you like to see added or changed?',
                  ),
                ),
              ),
            ),
            const SettingsDivider(),
            SettingsMenuRow(
              icon: Icons.chat_bubble_outline,
              label: 'Leave feedback',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SupportFormScreen(
                    title: 'Leave feedback',
                    ticketType: 'feedback',
                    hint: 'Tell us what you think about CampRide.',
                  ),
                ),
              ),
            ),
            const SettingsDivider(),
            SettingsMenuRow(
              icon: Icons.email_outlined,
              label: 'Contact support email',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ContactSupportScreen()),
              ),
            ),
            const SettingsDivider(),
          ],
        ),
      ),
    );
  }
}
