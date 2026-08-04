import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/authentication_provider.dart';
import '../../../services/shuttle_service.dart';
import '../../../theme/app_theme.dart';

/// Dedicated Add/Edit Shuttle screen, reached from the Shuttles list.
/// Pass [shuttle] to edit an existing shuttle, or leave it null to create one.
class ShuttleFormScreen extends StatefulWidget {
  final ShuttleInfo? shuttle;

  const ShuttleFormScreen({super.key, this.shuttle});

  @override
  State<ShuttleFormScreen> createState() => _ShuttleFormScreenState();
}

class _ShuttleFormScreenState extends State<ShuttleFormScreen> {
  final _shuttleService = ShuttleService();
  late final TextEditingController _nameController;
  late final TextEditingController _plateController;
  late final TextEditingController _capacityController;
  bool _isLoading = false;
  String? _error;

  bool get _isEditing => widget.shuttle != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.shuttle?.name ?? '');
    _plateController = TextEditingController(text: widget.shuttle?.plateNumber ?? '');
    _capacityController = TextEditingController(text: widget.shuttle?.capacity.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _plateController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final plate = _plateController.text.trim();
    final capacityText = _capacityController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Please enter a shuttle name');
      return;
    }
    if (plate.isEmpty) {
      setState(() => _error = 'Please enter a plate number');
      return;
    }
    final capacity = int.tryParse(capacityText);
    if (capacity == null || capacity <= 0) {
      setState(() => _error = 'Please enter a valid capacity');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final auth = context.read<AuthenticationProvider>();
    try {
      final result = _isEditing
          ? await _shuttleService.updateShuttle(
              accessToken: auth.accessToken!,
              shuttleId: widget.shuttle!.id,
              name: name,
              plateNumber: plate,
              capacity: capacity,
            )
          : await _shuttleService.createShuttle(
              accessToken: auth.accessToken!,
              name: name,
              plateNumber: plate,
              capacity: capacity,
            );

      if (!mounted) return;

      if (result.success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Shuttle updated: $name' : 'Shuttle created: $name')),
        );
      } else {
        setState(() => _error = result.message ?? 'Failed to save shuttle');
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
          _isEditing ? 'Edit Shuttle' : 'Add Shuttle',
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
                _isEditing ? 'Shuttle details' : 'New shuttle',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: context.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                _isEditing
                    ? 'Update this shuttle\'s name, plate number, or capacity.'
                    : 'Add a shuttle to start assigning drivers and routes.',
                style: GoogleFonts.poppins(fontSize: 13, color: context.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),

              Text('Shuttle Name', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary)),
              const SizedBox(height: 8),
              _FormField(controller: _nameController, hint: 'e.g. Shuttle 3'),
              const SizedBox(height: 16),

              Text('Plate Number', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary)),
              const SizedBox(height: 8),
              _FormField(controller: _plateController, hint: 'e.g. GR 1234-24'),
              const SizedBox(height: 16),

              Text('Capacity (seats)', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary)),
              const SizedBox(height: 8),
              _FormField(controller: _capacityController, hint: 'e.g. 30', keyboardType: TextInputType.number),

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
                      : Text(
                          _isEditing ? 'Save Changes' : 'Create Shuttle',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
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
