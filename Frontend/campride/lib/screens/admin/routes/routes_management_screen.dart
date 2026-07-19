import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../providers/authentication_provider.dart';
import '../../../config/api_config.dart';
import '../../../theme/app_colors.dart';

class RoutesManagementScreen extends StatefulWidget {
  const RoutesManagementScreen({super.key});

  @override
  State<RoutesManagementScreen> createState() => _RoutesManagementScreenState();
}

class _RoutesManagementScreenState extends State<RoutesManagementScreen> {
  List<Map<String, dynamic>> _routes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    final auth = context.read<AuthenticationProvider>();
    if (auth.accessToken == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseHttpUrl}/admin/routes'),
        headers: {'Authorization': 'Bearer ${auth.accessToken}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        if (mounted) {
          setState(() {
            _routes = data.cast<Map<String, dynamic>>();
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading routes: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showCreateRouteDialog() {
    final nameController = TextEditingController();
    final startNameController = TextEditingController();
    final endNameController = TextEditingController();
    final startLatController = TextEditingController();
    final startLngController = TextEditingController();
    final endLatController = TextEditingController();
    final endLngController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Create Route', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Route Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                  enabled: !isSubmitting,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: startNameController,
                  decoration: InputDecoration(
                    labelText: 'Start Location Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                  enabled: !isSubmitting,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: startLatController,
                  decoration: InputDecoration(
                    labelText: 'Start Latitude',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  enabled: !isSubmitting,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: startLngController,
                  decoration: InputDecoration(
                    labelText: 'Start Longitude',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  enabled: !isSubmitting,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: endNameController,
                  decoration: InputDecoration(
                    labelText: 'End Location Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                  enabled: !isSubmitting,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: endLatController,
                  decoration: InputDecoration(
                    labelText: 'End Latitude',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  enabled: !isSubmitting,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: endLngController,
                  decoration: InputDecoration(
                    labelText: 'End Longitude',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  enabled: !isSubmitting,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setDialogState(() => isSubmitting = true);
                      final auth = context.read<AuthenticationProvider>();
                      try {
                        final response = await http.post(
                          Uri.parse('${ApiConfig.baseHttpUrl}/admin/routes'),
                          headers: {
                            'Authorization': 'Bearer ${auth.accessToken}',
                            'Content-Type': 'application/json',
                          },
                          body: jsonEncode({
                            'name': nameController.text,
                            'start_name': startNameController.text,
                            'start_lat': double.parse(startLatController.text),
                            'start_lng': double.parse(startLngController.text),
                            'end_name': endNameController.text,
                            'end_lat': double.parse(endLatController.text),
                            'end_lng': double.parse(endLngController.text),
                          }),
                        );

                        if (context.mounted) {
                          if (response.statusCode == 200 || response.statusCode == 201) {
                            Navigator.pop(context);
                            _loadRoutes();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Route created: ${nameController.text}')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${response.statusCode}'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                    )
                  : const Text('Create', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
        ),
      );
    }

    if (_routes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route_outlined, size: 48, color: AppColors.textSecondaryLight),
            const SizedBox(height: 16),
            Text(
              'No Routes Yet',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a route to get started',
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondaryLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showCreateRouteDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Route'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _routes.length,
          separatorBuilder: (context, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) => _RouteCard(
            route: _routes[index],
            onRefresh: _loadRoutes,
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _showCreateRouteDialog,
            backgroundColor: AppColors.primaryGreen,
            child: const Icon(Icons.add),
            tooltip: 'Add Route',
          ),
        ),
      ],
    );
  }
}

class _RouteCard extends StatelessWidget {
  final Map<String, dynamic> route;
  final VoidCallback onRefresh;

  const _RouteCard({
    required this.route,
    required this.onRefresh,
  });


  void _showStopsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _StopsDialog(
        routeId: route['id'],
        routeName: route['name'],
        onRefresh: onRefresh,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              route['name'] ?? 'Unnamed Route',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.location_on,
              label: 'From',
              value: route['start_name'] ?? 'Unknown',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: 'To',
              value: route['end_name'] ?? 'Unknown',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.calendar_today,
              label: 'Created',
              value: route['created_at']?.toString().split('T').first ?? 'N/A',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showStopsDialog(context),
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('Stops', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Delete — coming in Phase 5',
              style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondaryLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StopsDialog extends StatefulWidget {
  final String routeId;
  final String routeName;
  final VoidCallback onRefresh;

  const _StopsDialog({
    required this.routeId,
    required this.routeName,
    required this.onRefresh,
  });

  @override
  State<_StopsDialog> createState() => _StopsDialogState();
}

class _StopsDialogState extends State<_StopsDialog> {
  List<Map<String, dynamic>> _stops = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStops();
  }

  Future<void> _loadStops() async {
    final auth = context.read<AuthenticationProvider>();
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseHttpUrl}/routes/${widget.routeId}/stops'),
        headers: {'Authorization': 'Bearer ${auth.accessToken}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        if (mounted) {
          setState(() {
            _stops = data.cast<Map<String, dynamic>>();
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _addStop(String name, double lat, double lng, int order) async {
    final auth = context.read<AuthenticationProvider>();
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseHttpUrl}/admin/routes/${widget.routeId}/stops'),
        headers: {
          'Authorization': 'Bearer ${auth.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'lat': lat,
          'lng': lng,
          'order': order,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _loadStops();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Stop added: $name')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showAddStopDialog() {
    final nameController = TextEditingController();
    final latController = TextEditingController();
    final lngController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Add Stop', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Stop Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: latController,
                decoration: InputDecoration(
                  labelText: 'Latitude',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lngController,
                decoration: InputDecoration(
                  labelText: 'Longitude',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _addStop(
                nameController.text,
                double.parse(latController.text),
                double.parse(lngController.text),
                _stops.length + 1,
              );
              if (mounted) Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Stops - ${widget.routeName}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: double.maxFinite,
        child: _loading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                ),
              )
            : _stops.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.stop_circle_outlined, size: 32, color: AppColors.textSecondaryLight),
                        const SizedBox(height: 12),
                        Text(
                          'No stops yet',
                          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _stops.length,
                    separatorBuilder: (context, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final stop = _stops[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text('${index + 1}'),
                        ),
                        title: Text(stop['name'] ?? 'Unnamed'),
                        subtitle: Text('Lat: ${stop['lat']}, Lng: ${stop['lng']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: null,
                        ),
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton.icon(
          onPressed: _showAddStopDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Stop'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryGreen),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondaryLight),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
