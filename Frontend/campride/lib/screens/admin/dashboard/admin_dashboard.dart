import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/authentication_provider.dart';
import '../../../services/shuttle_service.dart';
import '../../../theme/app_colors.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: _selectedTab == 0 ? _ShuttlesTab() : _RoutesTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (index) => setState(() => _selectedTab = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bus_outlined),
            activeIcon: Icon(Icons.directions_bus),
            label: 'Shuttles',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.route_outlined),
            activeIcon: Icon(Icons.route),
            label: 'Routes',
          ),
        ],
      ),
    );
  }
}

class _ShuttlesTab extends StatefulWidget {
  @override
  State<_ShuttlesTab> createState() => _ShuttlesTabState();
}

class _ShuttlesTabState extends State<_ShuttlesTab> {
  final _shuttleService = ShuttleService();
  List<ShuttleInfo> _shuttles = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadShuttles();
  }

  Future<void> _loadShuttles() async {
    final auth = context.read<AuthenticationProvider>();
    if (auth.accessToken == null) {
      setState(() {
        _loading = false;
        _errorMessage = 'No access token available';
      });
      return;
    }

    final result = await _shuttleService.adminListShuttles(
      accessToken: auth.accessToken!,
    );

    if (mounted) {
      setState(() {
        _loading = false;
        if (result.success && result.data != null) {
          _shuttles = result.data!;
          _errorMessage = null;
        } else {
          _errorMessage = result.message ?? 'Failed to load shuttles';
        }
      });
    }
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

    return RefreshIndicator(
      onRefresh: _loadShuttles,
      child: _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(_errorMessage!),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadShuttles,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _shuttles.isEmpty
              ? Center(
                  child: Text(
                    'No shuttles registered',
                    style: GoogleFonts.poppins(color: AppColors.textSecondaryLight),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _shuttles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _AdminShuttleCard(
                    shuttle: _shuttles[index],
                    onRefresh: _loadShuttles,
                  ),
                ),
    );
  }
}

class _AdminShuttleCard extends StatelessWidget {
  final ShuttleInfo shuttle;
  final VoidCallback onRefresh;

  const _AdminShuttleCard({
    required this.shuttle,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryGreen.withOpacity(0.2),
                  child: const Icon(Icons.directions_bus, color: AppColors.primaryGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shuttle.name,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      Text(
                        shuttle.plateNumber,
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(icon: Icons.event_seat, label: 'Capacity', value: '${shuttle.capacity} seats'),
            _InfoRow(
              icon: Icons.person,
              label: 'Driver',
              value: shuttle.assignedDriverName ?? 'Unassigned',
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showDeleteConfirmation(context),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Shuttle'),
        content: Text('Are you sure you want to delete ${shuttle.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteShuttle(context);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteShuttle(BuildContext context) async {
    final auth = context.read<AuthenticationProvider>();
    if (auth.accessToken == null) return;

    final service = ShuttleService();
    await service.deleteShuttle(
      accessToken: auth.accessToken!,
      shuttleId: shuttle.id,
    );
    onRefresh();
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primaryGreen),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondaryLight)),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _RoutesTab extends StatefulWidget {
  @override
  State<_RoutesTab> createState() => _RoutesTabState();
}

class _RoutesTabState extends State<_RoutesTab> {
  final _shuttleService = ShuttleService();
  List<DriverRoute> _routes = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    final auth = context.read<AuthenticationProvider>();
    if (auth.accessToken == null) {
      setState(() {
        _loading = false;
        _errorMessage = 'No access token available';
      });
      return;
    }

    final result = await _shuttleService.listRoutes(
      accessToken: auth.accessToken!,
    );

    if (mounted) {
      setState(() {
        _loading = false;
        if (result.success && result.data != null) {
          _routes = result.data!;
          _errorMessage = null;
        } else {
          _errorMessage = result.message ?? 'Failed to load routes';
        }
      });
    }
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

    return RefreshIndicator(
      onRefresh: _loadRoutes,
      child: _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(_errorMessage!),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadRoutes,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _routes.isEmpty
              ? Center(
                  child: Text(
                    'No routes created',
                    style: GoogleFonts.poppins(color: AppColors.textSecondaryLight),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _routes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _RouteCard(
                    route: _routes[index],
                    onRefresh: _loadRoutes,
                  ),
                ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final DriverRoute route;
  final VoidCallback onRefresh;

  const _RouteCard({
    required this.route,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryGreen.withOpacity(0.2),
                  child: const Icon(Icons.route, color: AppColors.primaryGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.name,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      Text(
                        '${route.startName} → ${route.endName}',
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondaryLight),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showDeleteConfirmation(context),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Route'),
        content: Text('Are you sure you want to delete ${route.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRoute(context);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRoute(BuildContext context) async {
    final auth = context.read<AuthenticationProvider>();
    if (auth.accessToken == null) return;

    final service = ShuttleService();
    await service.deleteRoute(
      accessToken: auth.accessToken!,
      routeId: route.id,
    );
    onRefresh();
  }
}
