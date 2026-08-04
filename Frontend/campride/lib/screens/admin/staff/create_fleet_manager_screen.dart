import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/authentication_provider.dart';
import '../../../services/shuttle_service.dart';
import '../../../theme/app_theme.dart';

/// Dedicated "Add Fleet Manager" screen, reached from Staff Management.
class CreateFleetManagerScreen extends StatefulWidget {
  const CreateFleetManagerScreen({super.key});

  @override
  State<CreateFleetManagerScreen> createState() => _CreateFleetManagerScreenState();
}

class _CreateFleetManagerScreenState extends State<CreateFleetManagerScreen> {
  final _shuttleService = ShuttleService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty) {
      setState(() => _error = 'Please enter the fleet manager\'s name');
      return;
    }
    if (email.isEmpty) {
      setState(() => _error = 'Please enter an email address');
      return;
    }
    if (password.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final auth = context.read<AuthenticationProvider>();
    try {
      final result = await _shuttleService.createFleetManager(
        name: name,
        email: email,
        password: password,
        accessToken: auth.accessToken!,
      );

      if (!mounted) return;

      if (result.success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fleet manager created: $email')),
        );
      } else {
        setState(() => _error = result.message ?? 'Failed to create fleet manager');
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
          'Add Fleet Manager',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: context.textPrimary),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New fleet manager account',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: context.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Fleet managers can manage drivers, shuttles, and assignments across the fleet.',
                style: GoogleFonts.poppins(fontSize: 13, color: context.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),

              Text('Name', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary)),
              const SizedBox(height: 8),
              _FormField(controller: _nameController, hint: 'Full name'),
              const SizedBox(height: 16),

              Text('Email', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary)),
              const SizedBox(height: 8),
              _FormField(controller: _emailController, hint: 'manager@example.com', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),

              Text('Password', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary)),
              const SizedBox(height: 8),
              _FormField(
                controller: _passwordController,
                hint: 'Min. 8 characters',
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 20,
                    color: context.textSecondary,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.error)),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                        )
                      : Text('Create Fleet Manager', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;

  const _FormField({
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.fieldFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.fieldBorder),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(fontSize: 14, color: context.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(fontSize: 14, color: context.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
