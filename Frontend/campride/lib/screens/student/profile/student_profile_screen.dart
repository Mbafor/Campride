import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../models/user_model.dart';
import '../../../providers/authentication_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../routes/route_names.dart';
import '../../../theme/app_colors.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = UserModel.mockStudent();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _ProfileHeader(user: user),
          const SizedBox(height: 24),
          _InfoCard(user: user),
          const SizedBox(height: 16),
          _SettingsCard(),
          const SizedBox(height: 24),
          _SignOutButton(),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserModel user;
  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryGreen, AppColors.primaryGreenLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.accentGold,
            child: Text(
              user.name.substring(0, 1),
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreenDark,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user.name,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            user.email,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final UserModel user;
  const _InfoCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student Info', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            _InfoRow(icon: Icons.badge_outlined, label: 'Student ID', value: user.studentId ?? 'N/A'),
            _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: user.phoneNumber ?? 'N/A'),
            _InfoRow(icon: Icons.school_outlined, label: 'Role', value: 'Student'),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryGreen),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondaryLight),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            Consumer<ThemeProvider>(
              builder: (context, theme, _) => Row(
                children: [
                  const Icon(Icons.dark_mode_outlined, size: 20, color: AppColors.primaryGreen),
                  const SizedBox(width: 12),
                  Text('Dark Mode', style: GoogleFonts.poppins(fontSize: 14)),
                  const Spacer(),
                  Switch(
                    value: theme.isDarkMode,
                    onChanged: (_) => theme.toggleTheme(),
                    activeColor: AppColors.primaryGreen,
                  ),
                ],
              ),
            ),
            const Divider(),
            Row(
              children: [
                const Icon(Icons.notifications_outlined, size: 20, color: AppColors.primaryGreen),
                const SizedBox(width: 12),
                Text('Notifications', style: GoogleFonts.poppins(fontSize: 14)),
                const Spacer(),
                Switch(value: true, onChanged: (_) {}, activeColor: AppColors.primaryGreen),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          await context.read<AuthenticationProvider>().signOut();
          if (context.mounted) context.go(RouteNames.welcome);
        },
        icon: const Icon(Icons.logout_rounded, color: AppColors.error),
        label: Text(
          'Sign Out',
          style: GoogleFonts.poppins(color: AppColors.error, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
