import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

/// A tappable row used across Settings/Account/Support screens:
/// icon, label, optional trailing widget (defaults to a chevron).
class SettingsMenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? labelColor;
  final Widget? trailing;

  const SettingsMenuRow({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.iconColor,
    this.labelColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor ?? context.textPrimary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: labelColor ?? context.textPrimary,
                ),
              ),
            ),
            trailing ??
                Icon(Icons.chevron_right, color: context.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, thickness: 1, color: context.divider);
  }
}
