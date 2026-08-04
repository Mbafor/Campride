import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'support_screen.dart';

/// Safety screen reached from the drawer. Collapsible Q&A grouped by
/// topic, including a dedicated "Do's and Don'ts" section for students who
/// are new to requesting and boarding campus shuttles.
class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textPrimary),
        title: Text(
          'Safety',
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
            Text(
              'Everything you need to know about requesting, boarding, and '
              'tracking shuttles with CampRide.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: context.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            const _SectionHeader('Getting Started'),
            const _FaqTile(
              question: 'How do I request a shuttle?',
              answer:
                  'Tap "Where to?" on the home screen, search for or pick your '
                  'destination stop, confirm your pickup point, then tap to '
                  'find available shuttles.',
            ),
            const _FaqTile(
              question: "How do I know which shuttle is mine?",
              answer:
                  'Once you\'re matched, the app shows the shuttle\'s route and '
                  'estimated arrival time. Check this against the shuttle before '
                  'boarding, and only tap "I boarded this shuttle" once you\'re '
                  'actually on it.',
            ),
            const _FaqTile(
              question: 'Can I track the shuttle in real time?',
              answer:
                  'Yes. After a match is made, you can follow the shuttle\'s '
                  'live location on the map until it reaches your stop.',
            ),
            const SizedBox(height: 20),

            const _SectionHeader("Do's and Don'ts"),
            _FaqTile(
              question: 'Things you should do',
              leading: Icons.check_circle_outline,
              leadingColor: Colors.green[600],
              answerWidget: _TipList(
                tips: const [
                  'Arrive at your pickup stop a few minutes early.',
                  'Double-check the shuttle\'s route before boarding.',
                  'Keep your phone charged and location on while you wait.',
                  'Confirm boarding in the app once you\'re actually on the shuttle.',
                  'Report safety concerns or bugs right away through Support.',
                ],
                icon: Icons.check,
                color: Colors.green[600]!,
              ),
            ),
            _FaqTile(
              question: 'Things to avoid',
              leading: Icons.cancel_outlined,
              leadingColor: Colors.red[400],
              answerWidget: _TipList(
                tips: const [
                  'Don\'t board a shuttle that isn\'t the one matched to your request.',
                  'Don\'t request a ride you don\'t intend to take — it holds up the shuttle for other students.',
                  'Don\'t flag down shuttles from the road; wait at the designated stop.',
                  'Don\'t share your account password with anyone.',
                  'Don\'t ignore in-app notifications about delays or route changes.',
                ],
                icon: Icons.close,
                color: Colors.red[400]!,
              ),
            ),
            const SizedBox(height: 20),

            const _SectionHeader('Rides & Notifications'),
            const _FaqTile(
              question: 'Where can I see my past rides?',
              answer: 'Open the drawer and tap "Request History" to see all your previous rides.',
            ),
            const _FaqTile(
              question: 'How do I check for updates or alerts?',
              answer: 'Tap the notifications bell, or "Notifications" in the drawer, to see route and ride alerts.',
            ),
            const SizedBox(height: 20),

            const _SectionHeader('Account & Settings'),
            const _FaqTile(
              question: 'How do I update my name, phone, or email?',
              answer: 'Go to your Profile from the Account tab and tap the field you want to change.',
            ),
            const _FaqTile(
              question: 'How do I change my password?',
              answer: 'Go to Settings, then tap "Change Password".',
            ),
            const _FaqTile(
              question: 'How do I switch between light and dark mode?',
              answer: 'Go to Settings, then tap "Appearance" to choose light, dark, or system default.',
            ),
            const SizedBox(height: 20),

            const _SectionHeader('Troubleshooting'),
            const _FaqTile(
              question: 'The app can\'t find my location',
              answer:
                  'Make sure location services are turned on for CampRide in your phone settings, '
                  'then try again. Your pickup point is detected automatically from your GPS location.',
            ),
            const _FaqTile(
              question: 'No shuttles are matching my request',
              answer:
                  'This usually means no drivers are currently active on that route. Wait a moment and '
                  'try again, or contact Support if it keeps happening.',
            ),
            const SizedBox(height: 28),

            _StillNeedHelp(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SupportScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: AppColors.primaryGreen,
        ),
      ),
    );
  }
}

/// A single collapsible question/answer row.
class _FaqTile extends StatelessWidget {
  final String question;
  final String? answer;
  final Widget? answerWidget;
  final IconData? leading;
  final Color? leadingColor;

  const _FaqTile({
    required this.question,
    this.answer,
    this.answerWidget,
    this.leading,
    this.leadingColor,
  }) : assert(answer != null || answerWidget != null);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          expandedAlignment: Alignment.centerLeft,
          iconColor: AppColors.primaryGreen,
          collapsedIconColor: context.textSecondary,
          leading: leading == null
              ? null
              : Icon(leading, color: leadingColor ?? context.textSecondary, size: 22),
          title: Text(
            question,
            style: GoogleFonts.poppins(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: context.textPrimary,
            ),
          ),
          children: [
            if (answerWidget != null)
              answerWidget!
            else
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  answer!,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    color: context.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Bulleted list of tips used inside a Do's/Don'ts tile.
class _TipList extends StatelessWidget {
  final List<String> tips;
  final IconData icon;
  final Color color;

  const _TipList({required this.tips, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tips
          .map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tip,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        color: context.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StillNeedHelp extends StatelessWidget {
  final VoidCallback onTap;
  const _StillNeedHelp({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.support_agent_outlined, color: AppColors.primaryGreen, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Still need help?',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Reach out to Support and we\'ll get back to you.',
                  style: GoogleFonts.poppins(fontSize: 12.5, color: context.textSecondary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onTap,
            child: Text(
              'Contact',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }
}
