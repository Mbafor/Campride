import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../config/api_config.dart';
import '../../providers/authentication_provider.dart';
import '../../routes/route_names.dart';
import '../../theme/app_theme.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthenticationProvider>();
      if (auth.accessToken == null) throw Exception('Not authenticated');

      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseHttpUrl}/users/me'),
            headers: {
              'Authorization': 'Bearer ${auth.accessToken}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              if (_passwordController.text.isNotEmpty)
                'current_password': _passwordController.text,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        await auth.signOut();
        if (mounted) context.go(RouteNames.welcome);
      } else if (response.statusCode == 401) {
        setState(() => _error = 'Current password is incorrect');
      } else {
        setState(() => _error = 'Failed to delete account. Please try again.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete account?', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'This cannot be undone from within the app. You will be signed out immediately.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteAccount();
            },
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.red[600])),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textPrimary),
        title: Text(
          'Delete Account',
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
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning_amber_rounded, color: Colors.red[600], size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                'Delete your account',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your account will be deactivated and you will be signed out. '
                "You won't be able to log back in with this account afterwards.",
                style: GoogleFonts.poppins(fontSize: 14, color: context.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 28),
              Text(
                'Current password',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: context.fieldFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.fieldBorder, width: 1.5),
                ),
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: GoogleFonts.poppins(fontSize: 15, color: context.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Leave blank if you signed in with Google',
                    hintStyle: GoogleFonts.poppins(fontSize: 13, color: context.textSecondary),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: context.textSecondary,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: GoogleFonts.poppins(fontSize: 12, color: Colors.red[600])),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _showConfirmDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Delete account',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
