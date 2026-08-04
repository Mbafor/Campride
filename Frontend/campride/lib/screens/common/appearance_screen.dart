import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Appearance',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Choose how CampRide looks on this device.',
                    style: GoogleFonts.poppins(fontSize: 13, color: context.textSecondary),
                  ),
                ),
                const SizedBox(height: 12),
                _AppearanceOption(
                  icon: Icons.brightness_auto_outlined,
                  label: 'System default',
                  subtitle: 'Matches your device settings',
                  selected: themeProvider.appearanceMode == AppearanceMode.system,
                  onTap: () => themeProvider.setAppearance(AppearanceMode.system),
                ),
                _AppearanceOption(
                  icon: Icons.light_mode_outlined,
                  label: 'Light',
                  subtitle: null,
                  selected: themeProvider.appearanceMode == AppearanceMode.light,
                  onTap: () => themeProvider.setAppearance(AppearanceMode.light),
                ),
                _AppearanceOption(
                  icon: Icons.dark_mode_outlined,
                  label: 'Dark',
                  subtitle: null,
                  selected: themeProvider.appearanceMode == AppearanceMode.dark,
                  onTap: () => themeProvider.setAppearance(AppearanceMode.dark),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AppearanceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _AppearanceOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: context.textPrimary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(fontSize: 15, color: context.textPrimary),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: GoogleFonts.poppins(fontSize: 12, color: context.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: AppColors.primaryGreenLight, size: 22)
            else
              Icon(Icons.circle_outlined, color: context.textSecondary, size: 22),
          ],
        ),
      ),
    );
  }
}
