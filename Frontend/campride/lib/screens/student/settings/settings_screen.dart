import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../providers/authentication_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../routes/route_names.dart';
import '../../../theme/app_colors.dart';
import '../../../config/api_config.dart';

/// Settings screen reached from the Account tab.
/// Contains: change password, dark mode toggle, and log out.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _passwordError;
  bool _loadingPassword = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty) {
      setState(() => _passwordError = 'Current password required');
      return;
    }
    if (_newPasswordController.text.isEmpty) {
      setState(() => _passwordError = 'New password required');
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _passwordError = 'Passwords do not match');
      return;
    }
    if (_newPasswordController.text.length < 8) {
      setState(() => _passwordError = 'Password must be at least 8 characters');
      return;
    }

    setState(() {
      _loadingPassword = true;
      _passwordError = null;
    });

    try {
      final auth = context.read<AuthenticationProvider>();
      if (auth.accessToken == null) throw Exception('Not authenticated');

      final response = await http.put(
        Uri.parse('${ApiConfig.baseHttpUrl}/auth/change-password'),
        headers: {
          'Authorization': 'Bearer ${auth.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'current_password': _currentPasswordController.text,
          'new_password': _newPasswordController.text,
        }),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                const SizedBox(width: 12),
                Text('Password changed successfully',
                    style: GoogleFonts.poppins()),
              ],
            ),
            backgroundColor: Colors.green[50],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() {
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });
      } else if (response.statusCode == 401) {
        setState(() => _passwordError = 'Current password is incorrect');
      } else {
        setState(() => _passwordError = 'Failed to change password');
      }
    } catch (e) {
      if (mounted) setState(() => _passwordError = 'Error: $e');
    } finally {
      if (mounted) setState(() => _loadingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
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

              // Change Password Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Change Password',
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _currentPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Current password',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'New password',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Confirm new password',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                    if (_passwordError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _passwordError!,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.red[600]),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loadingPassword ? null : _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _loadingPassword
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primaryGreen),
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Change Password',
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey[200])),
              const SizedBox(height: 24),

              // Dark mode toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Consumer<ThemeProvider>(
                  builder: (ctx, themeProvider, _) => Row(
                    children: [
                      Icon(Icons.dark_mode_outlined,
                          size: 24, color: Colors.black87),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Dark Mode',
                          style: GoogleFonts.poppins(
                              fontSize: 16, color: Colors.black87),
                        ),
                      ),
                      Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (_) async =>
                            await themeProvider.toggleTheme(),
                        activeThumbColor: AppColors.primaryGreenLight,
                        activeTrackColor:
                            AppColors.brandGreen.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey[200])),
              const SizedBox(height: 24),

              // Logout
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: InkWell(
                  onTap: () async {
                    final auth =
                        context.read<AuthenticationProvider>();
                    await auth.signOut();
                    await Future.delayed(
                        const Duration(milliseconds: 100));
                    if (context.mounted) {
                      context.go(RouteNames.welcome);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    child: Row(
                      children: [
                        Icon(Icons.logout,
                            size: 24, color: Colors.red[600]),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Log out',
                            style: GoogleFonts.poppins(
                                fontSize: 16, color: Colors.red[600]),
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            color: Colors.grey[400], size: 22),
                      ],
                    ),
                  ),
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
