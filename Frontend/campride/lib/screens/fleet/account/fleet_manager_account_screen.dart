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

class FleetManagerAccountScreen extends StatefulWidget {
  const FleetManagerAccountScreen({super.key});

  @override
  State<FleetManagerAccountScreen> createState() => _FleetManagerAccountScreenState();
}

class _FleetManagerAccountScreenState extends State<FleetManagerAccountScreen> {
  final _nameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _nameError;
  String? _nameSuccess;
  String? _passwordError;
  String? _passwordSuccess;
  bool _loadingName = false;
  bool _loadingPassword = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthenticationProvider>();
    _nameController.text = auth.user?.name ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateName() async {
    if (_nameController.text.isEmpty) {
      setState(() => _nameError = 'Name cannot be empty');
      return;
    }

    setState(() {
      _loadingName = true;
      _nameError = null;
      _nameSuccess = null;
    });

    try {
      final auth = context.read<AuthenticationProvider>();
      if (auth.accessToken == null) throw Exception('Not authenticated');

      final response = await http.put(
        Uri.parse('${ApiConfig.baseHttpUrl}/users/me'),
        headers: {
          'Authorization': 'Bearer ${auth.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'name': _nameController.text}),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final auth = context.read<AuthenticationProvider>();
        auth.updateUserName(_nameController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                  const SizedBox(width: 12),
                  Text('Name updated successfully', style: GoogleFonts.poppins()),
                ],
              ),
              backgroundColor: Colors.green[50],
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        setState(() => _nameSuccess = null);
      } else {
        setState(() => _nameError = 'Failed to update name');
      }
    } catch (e) {
      if (mounted) setState(() => _nameError = 'Error: $e');
    } finally {
      if (mounted) setState(() => _loadingName = false);
    }
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
      _passwordSuccess = null;
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                  const SizedBox(width: 12),
                  Text('Password changed successfully', style: GoogleFonts.poppins()),
                ],
              ),
              backgroundColor: Colors.green[50],
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        setState(() {
          _passwordSuccess = null;
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _AccountHeader(),
              const SizedBox(height: 32),

              // Edit Name Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Edit Name', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Enter your name',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                      ),
                    ),
                    if (_nameError != null) ...[const SizedBox(height: 8), Text(_nameError!, style: GoogleFonts.poppins(fontSize: 12, color: Colors.red[600]))],
                    if (_nameSuccess != null) ...[const SizedBox(height: 8), Text(_nameSuccess!, style: GoogleFonts.poppins(fontSize: 12, color: Colors.green[600]))],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loadingName ? null : _updateName,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, padding: const EdgeInsets.symmetric(vertical: 12)),
                        child: _loadingName ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen), strokeWidth: 2))
                            : Text('Save Name', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _RowDivider()),
              const SizedBox(height: 24),

              // Change Password Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Change Password', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    TextField(controller: _currentPasswordController, obscureText: true, decoration: InputDecoration(hintText: 'Current password', filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)))),
                    const SizedBox(height: 12),
                    TextField(controller: _newPasswordController, obscureText: true, decoration: InputDecoration(hintText: 'New password', filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)))),
                    const SizedBox(height: 12),
                    TextField(controller: _confirmPasswordController, obscureText: true, decoration: InputDecoration(hintText: 'Confirm new password', filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)))),
                    if (_passwordError != null) ...[const SizedBox(height: 8), Text(_passwordError!, style: GoogleFonts.poppins(fontSize: 12, color: Colors.red[600]))],
                    if (_passwordSuccess != null) ...[const SizedBox(height: 8), Text(_passwordSuccess!, style: GoogleFonts.poppins(fontSize: 12, color: Colors.green[600]))],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loadingPassword ? null : _changePassword,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, padding: const EdgeInsets.symmetric(vertical: 12)),
                        child: _loadingPassword ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen), strokeWidth: 2))
                            : Text('Change Password', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _RowDivider()),
              const SizedBox(height: 24),

              // Dark mode toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Consumer<ThemeProvider>(
                  builder: (ctx, themeProvider, _) => _MenuRowToggle(icon: Icons.dark_mode_outlined, label: 'Dark Mode', value: themeProvider.isDarkMode, onChanged: (_) async => await themeProvider.toggleTheme()),
                ),
              ),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _RowDivider()),

              // Logout
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _MenuRow(
                  icon: Icons.logout,
                  label: 'Log out',
                  iconColor: Colors.red[600],
                  labelColor: Colors.red[600],
                  onTap: () async {
                    if (!context.mounted) return;
                    final auth = context.read<AuthenticationProvider>();
                    await auth.signOut();
                    await Future.delayed(const Duration(milliseconds: 100));
                    if (context.mounted) context.go(RouteNames.welcome);
                  },
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

class _AccountHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Consumer<AuthenticationProvider>(
              builder: (context, auth, _) {
                final userName = auth.user?.name ?? 'User';
                final userEmail = auth.user?.email ?? 'N/A';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                    const SizedBox(height: 4),
                    Text(userEmail, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
                  ],
                );
              },
            ),
          ),
          Container(width: 54, height: 54, decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle), child: Icon(Icons.person, size: 32, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? labelColor;

  const _MenuRow({required this.icon, required this.label, this.onTap, this.iconColor, this.labelColor});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 17),
        child: Row(children: [
          Icon(icon, size: 24, color: iconColor ?? Colors.black87),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: GoogleFonts.poppins(fontSize: 16, color: labelColor ?? Colors.black87))),
          Icon(Icons.chevron_right, color: Colors.grey[400], size: 22),
        ]),
      ),
    );
  }
}

class _MenuRowToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _MenuRowToggle({required this.icon, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Icon(icon, size: 24, color: textColor),
        const SizedBox(width: 16),
        Expanded(child: Text(label, style: GoogleFonts.poppins(fontSize: 16, color: textColor))),
        Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.primaryGreenLight, activeTrackColor: AppColors.brandGreen.withValues(alpha: 0.4)),
      ]),
    );
  }
}

class _RowDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Divider(height: 1, thickness: 1, color: isDarkMode ? Colors.grey[800] : Colors.grey[200]);
  }
}
