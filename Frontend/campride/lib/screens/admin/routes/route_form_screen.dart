import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/authentication_provider.dart';
import '../../../services/shuttle_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/search_location_picker.dart';

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
  LocationSearchResult? _startLocation;
  LocationSearchResult? _endLocation;
  bool _isLoading = false;
  String? _error;

  bool get _isEditing => widget.route != null;

  @override
  void initState() {
    super.initState();
    final r = widget.route;
    _nameController = TextEditingController(text: r?.name ?? '');
    if (r != null) {
      _startLocation = LocationSearchResult(
        name: r.startName,
        latitude: r.startLat,
        longitude: r.startLng,
      );
      _endLocation = LocationSearchResult(
        name: r.endName,
        latitude: r.endLat,
        longitude: r.endLng,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectStartLocation() async {
    final result = await Navigator.push<LocationSearchResult>(
      context,
      MaterialPageRoute(
        builder: (context) => SearchLocationPicker(
          title: 'Select Start Point',
          hint: 'Search for start location...',
          initialLocation: _startLocation,
        ),
      ),
    );
    if (result != null) {
      setState(() => _startLocation = result);
    }
  }

  Future<void> _selectEndLocation() async {
    final result = await Navigator.push<LocationSearchResult>(
      context,
      MaterialPageRoute(
        builder: (context) => SearchLocationPicker(
          title: 'Select End Point',
          hint: 'Search for end location...',
          initialLocation: _endLocation,
        ),
      ),
    );
    if (result != null) {
      setState(() => _endLocation = result);
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Please fill in the route name');
      return;
    }
    if (_startLocation == null) {
      setState(() => _error = 'Please select a start point');
      return;
    }
    if (_endLocation == null) {
      setState(() => _error = 'Please select an end point');
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
              startName: _startLocation!.name,
              endName: _endLocation!.name,
              startLat: _startLocation!.latitude,
              startLng: _startLocation!.longitude,
              endLat: _endLocation!.latitude,
              endLng: _endLocation!.longitude,
            )
          : await _shuttleService.createRoute(
              accessToken: auth.accessToken!,
              name: name,
              startName: _startLocation!.name,
              endName: _endLocation!.name,
              startLat: _startLocation!.latitude,
              startLng: _startLocation!.longitude,
              endLat: _endLocation!.latitude,
              endLng: _endLocation!.longitude,
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
              _LocationSelector(
                location: _startLocation,
                onTap: _selectStartLocation,
              ),
              const SizedBox(height: 20),

              Text('End Point', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: context.textPrimary)),
              const SizedBox(height: 8),
              _LocationSelector(
                location: _endLocation,
                onTap: _selectEndLocation,
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

class _LocationSelector extends StatelessWidget {
  final LocationSearchResult? location;
  final VoidCallback onTap;

  const _LocationSelector({
    required this.location,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (location == null) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: context.fieldFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.fieldBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.location_on_outlined, size: 18, color: context.textSecondary),
              const SizedBox(width: 12),
              Text(
                'Select location',
                style: GoogleFonts.poppins(fontSize: 14, color: context.textSecondary),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward, size: 18, color: context.textSecondary),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.fieldFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryGreen),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.location_on, size: 18, color: AppColors.primaryGreen),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    location!.name,
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: context.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Lat: ${location!.latitude.toStringAsFixed(4)}, Lng: ${location!.longitude.toStringAsFixed(4)}',
                    style: GoogleFonts.poppins(fontSize: 11, color: context.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.edit_outlined, size: 18, color: AppColors.primaryGreen),
          ],
        ),
      ),
    );
  }
}
