import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/authentication_provider.dart';
import '../../../services/shuttle_service.dart';
import '../../../theme/app_theme.dart';

/// Dedicated Add/Edit Route screen, reached from Routes Management.
/// Pass [route] to edit an existing route, or leave it null to create one.
class RouteFormScreen extends StatefulWidget {
  final DriverRoute? route;

  const RouteFormScreen({super.key, this.route});

  @override
  State<RouteFormScreen> createState() => _RouteFormScreenState();
}

class _RouteFormScreenState extends State<RouteFormScreen> {
  final _shuttleService = ShuttleService();
  late final TextEditingController _nameController;
  late final TextEditingController _startNameController;
  late final TextEditingController _startLatController;
  late final TextEditingController _startLngController;
  late final TextEditingController _endNameController;
  late final TextEditingController _endLatController;
  late final TextEditingController _endLngController;
  bool _isLoading = false;
  String? _error;

  bool get _isEditing => widget.route != null;

  @override
  void initState() {
    super.initState();
    final r = widget.route;
    _nameController = TextEditingController(text: r?.name ?? '');
    _startNameController = TextEditingController(text: r?.startName ?? '');
    _startLatController = TextEditingController(text: r != null ? r.startLat.toString() : '');
    _startLngController = TextEditingController(text: r != null ? r.startLng.toString() : '');
    _endNameController = TextEditingController(text: r?.endName ?? '');
    _endLatController = TextEditingController(text: r != null ? r.endLat.toString() : '');
    _endLngController = TextEditingController(text: r != null ? r.endLng.toString() : '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _startNameController.dispose();
    _startLatController.dispose();
    _startLngController.dispose();
    _endNameController.dispose();
    _endLatController.dispose();
    _endLngController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final startName = _startNameController.text.trim();
    final endName = _endNameController.text.trim();
    final startLat = double.tryParse(_startLatController.text.trim());
    final startLng = double.tryParse(_startLngController.text.trim());
    final endLat = double.tryParse(_endLatController.text.trim());
    final endLng = double.tryParse(_endLngController.text.trim());

    if (name.isEmpty || startName.isEmpty || endName.isEmpty) {
      setState(() => _error = 'Please fill in the route and location names');
      return;
    }
    if (startLat == null || startLng == null || endLat == null || endLng == null) {
      setState(() => _error = 'Please enter valid coordinates');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final auth = context.read<AuthenticationProvider>();
    try {
      final result = _isEditing
          ? await _shuttleService.updateRoute(
              accessToken: auth.accessToken!,
              routeId: widget.route!.id,
              name: name,
              startName: startName,
              endName: endName,
              startLat: startLat,
              startLng: startLng,
              endLat: endLat,
              endLng: endLng,
            )
          : await _shuttleService.createRoute(
              accessToken: auth.accessToken!,
              name: name,
              startName: startName,
              endName: endName,
              startLat: startLat,
              startLng: startLng,
              endLat: endLat,
              endLng: endLng,
            );

      if (!mounted) return;

      if (result.success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Route updated: $name' : 'Route created: $name')),
        );
      } else {
        setState(() => _error = result.message ?? 'Failed to save route');
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
          _isEditing ? 'Edit Route' : 'Add Route',
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
                _isEditing ? 'Route details' : 'New route',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: context.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Define the route name and its start/end points. Stops can be added afterward.',
                style: GoogleFonts.poppins(fontSize: 13, color: context.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),

              Text('Route Name', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary)),
              const SizedBox(height: 8),
              _FormField(controller: _nameController, hint: 'e.g. Campus to Commercial Area'),
              const SizedBox(height: 20),

              Text('Start Point', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: context.textPrimary)),
              const SizedBox(height: 8),
              _FormField(controller: _startNameController, hint: 'Location name'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _FormField(controller: _startLatController, hint: 'Latitude', keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true))),
                  const SizedBox(width: 12),
                  Expanded(child: _FormField(controller: _startLngController, hint: 'Longitude', keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true))),
                ],
              ),
              const SizedBox(height: 20),

              Text('End Point', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: context.textPrimary)),
              const SizedBox(height: 8),
              _FormField(controller: _endNameController, hint: 'Location name'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _FormField(controller: _endLatController, hint: 'Latitude', keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true))),
                  const SizedBox(width: 12),
                  Expanded(child: _FormField(controller: _endLngController, hint: 'Longitude', keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true))),
                ],
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
                      : Text(
                          _isEditing ? 'Save Changes' : 'Create Route',
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
