import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/authentication_provider.dart';
import '../../../services/shuttle_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/empty_state_widget.dart';
import 'create_driver_screen.dart';
import 'driver_detail_screen.dart';

enum _DriverFilter { all, assigned, unassigned, active }

const _avatarPalette = [
  AppColors.primaryGreen,
  Color(0xFF2E8B8B), // teal
  Color(0xFF7C4DFF), // purple
  Color(0xFFE0942A), // amber/orange
  Color(0xFF3B7DDD), // blue
  Color(0xFFD1478A), // pink
];

class DriversListScreen extends StatefulWidget {
  const DriversListScreen({super.key});

  @override
  State<DriversListScreen> createState() => _DriversListScreenState();
}

class _DriversListScreenState extends State<DriversListScreen> {
  final _shuttleService = ShuttleService();
  final _searchController = TextEditingController();

  List<DriverInfo> _drivers = [];
  List<ShuttleInfo> _shuttles = [];
  bool _loading = true;
  _DriverFilter _filter = _DriverFilter.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthenticationProvider>();
    if (auth.accessToken == null) {
      setState(() => _loading = false);
      return;
    }

    final driversResult = await _shuttleService.listDrivers(accessToken: auth.accessToken!);
    final shuttlesResult = await _shuttleService.listShuttles(accessToken: auth.accessToken!);

    if (mounted) {
      setState(() {
        _drivers = driversResult.data ?? [];
        _shuttles = shuttlesResult.data ?? [];
        _loading = false;
      });
    }
  }

  int get _assignedCount => _drivers.where((d) => d.assignedShuttleId != null).length;
  int get _unassignedCount => _drivers.where((d) => d.assignedShuttleId == null).length;
  int get _activeCount => _drivers.where((d) => d.isActive).length;

  List<DriverInfo> get _filteredDrivers {
    var list = _drivers;
    switch (_filter) {
      case _DriverFilter.assigned:
        list = list.where((d) => d.assignedShuttleId != null).toList();
        break;
      case _DriverFilter.unassigned:
        list = list.where((d) => d.assignedShuttleId == null).toList();
        break;
      case _DriverFilter.active:
        list = list.where((d) => d.isActive).toList();
        break;
      case _DriverFilter.all:
        break;
    }

    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((d) {
        return d.name.toLowerCase().contains(q) ||
            d.email.toLowerCase().contains(q) ||
            d.id.toLowerCase().contains(q) ||
            (d.assignedShuttleName?.toLowerCase().contains(q) ?? false) ||
            (d.assignedRouteName?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    return list;
  }

  Future<void> _openCreateDriver() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateDriverScreen()),
    );
    if (created == true) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SafeArea(
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
          ),
        ),
      );
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Drivers',
                        style: GoogleFonts.poppins(
                            fontSize: 26, fontWeight: FontWeight.bold, color: context.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manage and assign drivers to shuttles and routes',
                        style: GoogleFonts.poppins(fontSize: 12.5, color: context.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _openCreateDriver,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text('Add Driver', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search bar
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
                  hintText: 'Search drivers...',
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

          // Filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'All Drivers',
                  count: _drivers.length,
                  isActive: _filter == _DriverFilter.all,
                  onTap: () => setState(() => _filter = _DriverFilter.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Assigned',
                  count: _assignedCount,
                  isActive: _filter == _DriverFilter.assigned,
                  onTap: () => setState(() => _filter = _DriverFilter.assigned),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Unassigned',
                  count: _unassignedCount,
                  isActive: _filter == _DriverFilter.unassigned,
                  onTap: () => setState(() => _filter = _DriverFilter.unassigned),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Active',
                  count: _activeCount,
                  isActive: _filter == _DriverFilter.active,
                  onTap: () => setState(() => _filter = _DriverFilter.active),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_drivers.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.people_outline,
        title: 'No drivers yet',
        subtitle: 'Add a driver to start assigning shuttles and routes.',
        action: ElevatedButton.icon(
          onPressed: _openCreateDriver,
          icon: const Icon(Icons.add),
          label: const Text('Add Driver'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
        ),
      );
    }

    final filtered = _filteredDrivers;
    if (filtered.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.search_off,
        title: 'No matching drivers',
        subtitle: 'Try a different search term or filter.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: filtered.length,
      separatorBuilder: (context, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _DriverCard(
        driver: filtered[index],
        shuttles: _shuttles,
        avatarColor: _avatarPalette[_drivers.indexOf(filtered[index]) % _avatarPalette.length],
        onRefresh: _loadData,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryGreen.withValues(alpha: 0.12) : context.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? AppColors.primaryGreen : context.divider, width: isActive ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.primaryGreen : context.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryGreen.withValues(alpha: 0.2) : context.fieldFill,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isActive ? AppColors.primaryGreen : context.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverCard extends StatefulWidget {
  final DriverInfo driver;
  final List<ShuttleInfo> shuttles;
  final Color avatarColor;
  final VoidCallback onRefresh;

  const _DriverCard({
    required this.driver,
    required this.shuttles,
    required this.avatarColor,
    required this.onRefresh,
  });

  @override
  State<_DriverCard> createState() => _DriverCardState();
}

class _DriverCardState extends State<_DriverCard> {
  final _shuttleService = ShuttleService();
  bool _assigning = false;

  void _showAssignShuttleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assign Shuttle', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.shuttles.isEmpty)
                Text(
                  'No shuttles available',
                  style: GoogleFonts.poppins(color: context.textSecondary),
                )
              else
                ...widget.shuttles.map((shuttle) => ListTile(
                      title: Text(shuttle.name, style: GoogleFonts.poppins()),
                      subtitle: Text(shuttle.plateNumber, style: GoogleFonts.poppins(fontSize: 12)),
                      onTap: () async {
                        Navigator.pop(context);
                        setState(() => _assigning = true);
                        final auth = context.read<AuthenticationProvider>();
                        try {
                          await _shuttleService.assignDriverToShuttle(
                            shuttleId: shuttle.id,
                            driverId: widget.driver.id,
                            accessToken: auth.accessToken!,
                          );
                          if (mounted) {
                            widget.onRefresh();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Assigned to ${shuttle.name}')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _assigning = false);
                        }
                      },
                    )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final driver = widget.driver;
    final isUnassigned = driver.assignedShuttleId == null;

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DriverDetailScreen(driverId: driver.id)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: widget.avatarColor,
                        child: Text(
                          driver.name.isNotEmpty ? driver.name.substring(0, 1).toUpperCase() : '?',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: driver.isActive ? AppColors.success : context.textSecondary,
                            shape: BoxShape.circle,
                            border: Border.all(color: context.cardBg, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver.name,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15, color: context.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _MiniInfo(
                                icon: Icons.directions_bus_outlined,
                                label: 'Shuttle',
                                value: driver.assignedShuttleName ?? 'Not assigned',
                              ),
                            ),
                            Expanded(
                              child: _MiniInfo(
                                icon: Icons.alt_route,
                                label: 'Route',
                                value: driver.assignedRouteName ?? 'Not assigned',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: (driver.isActive ? AppColors.success : AppColors.error).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          driver.isActive ? 'Active' : 'Inactive',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: driver.isActive ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Icon(Icons.chevron_right, color: context.textSecondary, size: 20),
                    ],
                  ),
                ],
              ),
              if (isUnassigned) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _assigning ? null : _showAssignShuttleDialog,
                    icon: _assigning
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGreen),
                          )
                        : const Icon(Icons.airport_shuttle, size: 16),
                    label: Text('Assign', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                      side: const BorderSide(color: AppColors.primaryGreen),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniInfo({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: AppColors.primaryGreen),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.poppins(fontSize: 10.5, color: context.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: context.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
