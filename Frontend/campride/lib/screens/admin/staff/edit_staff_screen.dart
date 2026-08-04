import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/authentication_provider.dart';
import '../../../services/shuttle_service.dart';
import '../../../theme/app_theme.dart';

/// Shared "Edit Staff" screen for both drivers and fleet managers —
/// the two roles expose the same editable fields (name, email), just
/// against different backend endpoints.
class EditStaffScreen extends StatefulWidget {
  final String id;
  final String name;
  final String email;
  final bool isFleetManager;

  const EditStaffScreen({
    super.key,
    required this.id,
    required this.name,
    required this.email,
    required this.isFleetManager,
  });

  @override
  State<EditStaffScreen> createState() => _EditStaffScreenState();
}

class _EditStaffScreenState extends State<EditStaffScreen> {
  final _shuttleService = ShuttleService();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Please enter a name');
      return;
    }
    if (email.isEmpty) {
      setState(() => _error = 'Please enter an email address');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final auth = context.read<AuthenticationProvider>();
    try {
      final result = widget.isFleetManager
          ? await _shuttleService.updateFleetManager(
              accessToken: auth.accessToken!,
              managerId: widget.id,
              name: name,
              email: email,
            )
          : await _shuttleService.updateDriver(
              accessToken: auth.accessToken!,
              driverId: widget.id,
              name: name,
              email: email,
            );

      if (!mounted) return;

      if (result.success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Updated: $name')),
        );
      } else {
        setState(() => _error = result.message ?? 'Failed to update');
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
          widget.isFleetManager ? 'Edit Fleet Manager' : 'Edit Driver',
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
              Text('Name', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary)),
              const SizedBox(height: 8),
              _FormField(controller: _nameController, hint: 'Full name'),
              const SizedBox(height: 16),

              Text('Email', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary)),
              const SizedBox(height: 8),
              _FormField(controller: _emailController, hint: 'name@example.com', keyboardType: TextInputType.emailAddress),

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
                      : Text('Save Changes', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
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
  final TextInputType? keyboardType;

  const _FormField({
    required this.controller,
    required this.hint,
    this.keyboardType,
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
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(fontSize: 14, color: context.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(fontSize: 14, color: context.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
