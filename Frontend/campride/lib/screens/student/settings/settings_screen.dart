import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/common/settings_menu_row.dart';
import '../../common/appearance_screen.dart';
import '../../common/change_password_screen.dart';
import '../../common/delete_account_screen.dart';
import '../../common/privacy_screen.dart';
import '../../../widgets/common/logout_dialog.dart';

/// Settings screen reached from the Account tab.
/// Contains: change password, appearance, log out, delete account.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // Change Password
              SettingsMenuRow(
                icon: Icons.lock_outline,
                label: 'Change Password',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                ),
              ),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SettingsDivider()),

              // Appearance
              SettingsMenuRow(
                icon: Icons.brightness_6_outlined,
                label: 'Appearance',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AppearanceScreen()),
                ),
              ),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SettingsDivider()),

              // Privacy
              SettingsMenuRow(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                ),
              ),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SettingsDivider()),

              // Logout
              SettingsMenuRow(
                icon: Icons.logout,
                label: 'Log out',
                iconColor: Colors.red[600],
                labelColor: Colors.red[600],
                onTap: () => showLogoutDialog(context),
              ),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SettingsDivider()),

              // Delete account
              SettingsMenuRow(
                icon: Icons.delete_outline,
                label: 'Delete Account',
                iconColor: Colors.red[600],
                labelColor: Colors.red[600],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DeleteAccountScreen()),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
