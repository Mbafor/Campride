import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../config/api_config.dart';
import '../../providers/authentication_provider.dart';
import '../../theme/app_theme.dart';

/// Standalone "Change password" screen, reached from Settings.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
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
                    style: GoogleFonts.poppins(color: context.textPrimary)),
              ],
            ),
            backgroundColor: context.cardBg,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        Navigator.pop(context);
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
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Change Password',
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
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              TextField(
                controller: _currentPasswordController,
                obscureText: true,
                style: GoogleFonts.poppins(color: context.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Current password',
                  filled: true,
                  fillColor: context.fieldFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: context.fieldBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: context.fieldBorder),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                style: GoogleFonts.poppins(color: context.textPrimary),
                decoration: InputDecoration(
                  hintText: 'New password',
                  filled: true,
                  fillColor: context.fieldFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: context.fieldBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: context.fieldBorder),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                style: GoogleFonts.poppins(color: context.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Confirm new password',
                  filled: true,
                  fillColor: context.fieldFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: context.fieldBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: context.fieldBorder),
                  ),
                ),
              ),
              if (_passwordError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _passwordError!,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.red[600]),
                ),
              ],
              const SizedBox(height: 20),
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
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Change Password',
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
