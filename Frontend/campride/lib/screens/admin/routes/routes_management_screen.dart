import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/authentication_provider.dart';
import '../../../services/shuttle_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/empty_state_widget.dart';
import '../../../widgets/search_location_picker.dart';
import 'route_form_screen.dart';

class RoutesManagementScreen extends StatefulWidget {
  const RoutesManagementScreen({super.key});

  @override
  State<RoutesManagementScreen> createState() => _RoutesManagementScreenState();
}

class _RoutesManagementScreenState extends State<RoutesManagementScreen> {
  final _shuttleService = ShuttleService();
  final _searchController = TextEditingController();

  List<DriverRoute> _routes = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadRoutes();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRoutes() async {
    final auth = context.read<AuthenticationProvider>();
    if (auth.accessToken == null) {
      setState(() => _loading = false);
      return;
    }

    final result = await _shuttleService.listRoutes(accessToken: auth.accessToken!);

    if (mounted) {
      setState(() {
        _routes = result.data ?? [];
        _loading = false;
      });
      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Failed to load routes'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  List<DriverRoute> get _filteredRoutes {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _routes;
    return _routes.where((r) {
      return r.name.toLowerCase().contains(q) ||
          r.startName.toLowerCase().contains(q) ||
          r.endName.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _openCreateRoute() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const RouteFormScreen()),
    );
    if (created == true) _loadRoutes();
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
          'Routes Management',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: context.textPrimary),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: GestureDetector(
                onTap: _openCreateRoute,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, size: 18, color: Colors.white),
                      const SizedBox(width: 6),
                      Text('Add', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.fieldFill,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.fieldBorder),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.poppins(fontSize: 14, color: context.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search routes...',
                          hintStyle: GoogleFonts.poppins(fontSize: 14, color: context.textSecondary),
                          prefixIcon: Icon(Icons.search, color: context.textSecondary, size: 20),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  icon: Icon(Icons.close, size: 18, color: context.textSecondary),
                                  onPressed: () => _searchController.clear(),
                                ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(child: _buildBody()),
                ],
              ),
      ),
    );
  }

  Widget _buildBody() {
    if (_routes.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.route_outlined,
        title: 'No routes yet',
        subtitle: 'Create a route to get started.',
        action: ElevatedButton.icon(
          onPressed: _openCreateRoute,
          icon: const Icon(Icons.add),
          label: const Text('Add Route'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
        ),
      );
    }

    final filtered = _filteredRoutes;
    if (filtered.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.search_off,
        title: 'No matching routes',
        subtitle: 'Try a different search term.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: filtered.length,
      separatorBuilder: (context, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _RouteCard(
        route: filtered[index],
        onRefresh: _loadRoutes,
      ),
    );
  }
}

class _RouteCard extends StatefulWidget {
  final DriverRoute route;
  final VoidCallback onRefresh;

  const _RouteCard({
    required this.route,
    required this.onRefresh,
  });

  @override
  State<_RouteCard> createState() => _RouteCardState();
}

class _RouteCardState extends State<_RouteCard> {
  final _shuttleService = ShuttleService();
  bool _isDeleting = false;

  Future<void> _openEdit() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => RouteFormScreen(route: widget.route)),
    );
    if (updated == true) widget.onRefresh();
  }

  void _showStopsDialog() {
    showDialog(
      context: context,
      builder: (context) => _StopsDialog(
        routeId: widget.route.id,
        routeName: widget.route.name,
      ),
    );
  }

  void _showDeleteConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Route?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'This will permanently delete "${widget.route.name}" and its stops. This action cannot be undone.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isDeleting
                ? null
                : () async {
                    setState(() => _isDeleting = true);
                    final auth = context.read<AuthenticationProvider>();
                    try {
                      final result = await _shuttleService.deleteRoute(
                        accessToken: auth.accessToken!,
                        routeId: widget.route.id,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        if (result.success) {
                          widget.onRefresh();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Deleted: ${widget.route.name}')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(result.message ?? 'Failed to delete'), backgroundColor: AppColors.error),
                          );
                        }
                      }
                    } finally {
                      if (mounted) setState(() => _isDeleting = false);
                    }
                  },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: _isDeleting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                  )
                : const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.route_outlined, color: AppColors.primaryGreen, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.route.name,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: context.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: context.textSecondary, size: 20),
                  onSelected: (value) {
                    if (value == 'edit') _openEdit();
                    if (value == 'stops') _showStopsDialog();
                    if (value == 'delete') _showDeleteConfirm();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 10), Text('Edit')]),
                    ),
                    const PopupMenuItem(
                      value: 'stops',
                      child: Row(children: [Icon(Icons.stop_circle_outlined, size: 18), SizedBox(width: 10), Text('Stops')]),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      enabled: !_isDeleting,
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                          const SizedBox(width: 10),
                          Text('Delete', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(icon: Icons.location_on, label: 'From', value: widget.route.startName),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.location_on_outlined, label: 'To', value: widget.route.endName),
          ],
        ),
      ),
    );
  }
}

class _StopsDialog extends StatefulWidget {
  final String routeId;
  final String routeName;

  const _StopsDialog({
    required this.routeId,
    required this.routeName,
  });

  @override
  State<_StopsDialog> createState() => _StopsDialogState();
}

class _StopsDialogState extends State<_StopsDialog> {
  final _shuttleService = ShuttleService();
  List<Stop> _stops = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStops();
  }

  Future<void> _loadStops() async {
    final auth = context.read<AuthenticationProvider>();
    final result = await _shuttleService.getRouteStops(accessToken: auth.accessToken!, routeId: widget.routeId);
    if (mounted) {
      setState(() {
        _stops = result.data ?? [];
        _loading = false;
      });
    }
  }

  Future<void> _addStop(String name, double lat, double lng) async {
    final auth = context.read<AuthenticationProvider>();
    final result = await _shuttleService.addRouteStop(
      accessToken: auth.accessToken!,
      routeId: widget.routeId,
      name: name,
      lat: lat,
      lng: lng,
      order: _stops.length + 1,
    );
    if (mounted) {
      if (result.success) {
        _loadStops();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stop added: $name')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Failed to add stop'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _deleteStop(Stop stop) async {
    final auth = context.read<AuthenticationProvider>();
    final result = await _shuttleService.deleteStop(accessToken: auth.accessToken!, stopId: stop.id);
    if (mounted) {
      if (result.success) {
        _loadStops();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Failed to delete stop'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _showAddStopDialog() async {
    final location = await Navigator.push<LocationSearchResult>(
      context,
      MaterialPageRoute(
        builder: (context) => const SearchLocationPicker(
          title: 'Select Stop Location',
          hint: 'Search for a stop location...',
        ),
      ),
    );

    if (location != null && mounted) {
      await _addStop(location.name, location.latitude, location.longitude);
    }
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
                        Icon(Icons.stop_circle_outlined, size: 32, color: context.textSecondary),
                        const SizedBox(height: 12),
                        Text(
                          'No stops yet',
                          style: GoogleFonts.poppins(fontSize: 13, color: context.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _stops.length,
                    separatorBuilder: (context, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final stop = _stops[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text('${index + 1}'),
                        ),
                        title: Text(stop.name),
                        subtitle: Text('Lat: ${stop.lat}, Lng: ${stop.lng}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteStop(stop),
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
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
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
          style: GoogleFonts.poppins(fontSize: 12, color: context.textSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: context.textPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
