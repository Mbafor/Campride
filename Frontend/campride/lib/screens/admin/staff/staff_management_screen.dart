import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/authentication_provider.dart';
import '../../../services/shuttle_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/empty_state_widget.dart';
import '../../fleet/drivers/create_driver_screen.dart';
import 'create_fleet_manager_screen.dart';
import 'edit_staff_screen.dart';

enum _StaffFilter { all, drivers, managers, active }

const _avatarPalette = [
  AppColors.primaryGreen,
  Color(0xFF2E8B8B),
  Color(0xFF7C4DFF),
  Color(0xFFE0942A),
  Color(0xFF3B7DDD),
  Color(0xFFD1478A),
];

class _StaffMember {
  final String id;
  final String name;
  final String email;
  final bool isActive;
  final bool isFleetManager;
  final String? assignedShuttleName;
  final String? assignedRouteName;

  _StaffMember({
    required this.id,
    required this.name,
    required this.email,
    required this.isActive,
    required this.isFleetManager,
    this.assignedShuttleName,
    this.assignedRouteName,
  });

  factory _StaffMember.fromDriver(DriverInfo d) => _StaffMember(
        id: d.id,
        name: d.name,
        email: d.email,
        isActive: d.isActive,
        isFleetManager: false,
        assignedShuttleName: d.assignedShuttleName,
        assignedRouteName: d.assignedRouteName,
      );

  factory _StaffMember.fromManager(FleetManagerInfo m) => _StaffMember(
        id: m.id,
        name: m.name,
        email: m.email,
        isActive: m.isActive,
        isFleetManager: true,
      );
}

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final _shuttleService = ShuttleService();
  final _searchController = TextEditingController();

  List<_StaffMember> _staff = [];
  bool _loading = true;
  _StaffFilter _filter = _StaffFilter.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadStaff();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStaff() async {
    final auth = context.read<AuthenticationProvider>();
    if (auth.accessToken == null) {
      setState(() => _loading = false);
      return;
    }

    final driversResult = await _shuttleService.listDrivers(accessToken: auth.accessToken!);
    final managersResult = await _shuttleService.listFleetManagers(accessToken: auth.accessToken!);

    if (mounted) {
      setState(() {
        _staff = [
          ...(driversResult.data ?? []).map(_StaffMember.fromDriver),
          ...(managersResult.data ?? []).map(_StaffMember.fromManager),
        ];
        _loading = false;
      });
    }
  }

  int get _driverCount => _staff.where((s) => !s.isFleetManager).length;
  int get _managerCount => _staff.where((s) => s.isFleetManager).length;
  int get _activeCount => _staff.where((s) => s.isActive).length;

  List<_StaffMember> get _filteredStaff {
    var list = _staff;
    switch (_filter) {
      case _StaffFilter.drivers:
        list = list.where((s) => !s.isFleetManager).toList();
        break;
      case _StaffFilter.managers:
        list = list.where((s) => s.isFleetManager).toList();
        break;
      case _StaffFilter.active:
        list = list.where((s) => s.isActive).toList();
        break;
      case _StaffFilter.all:
        break;
    }

    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((s) {
        return s.name.toLowerCase().contains(q) || s.email.toLowerCase().contains(q);
      }).toList();
    }
    return list;
  }

  Future<void> _openCreateDriver() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateDriverScreen()),
    );
    if (created == true) _loadStaff();
  }

  Future<void> _openCreateFleetManager() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateFleetManagerScreen()),
    );
    if (created == true) _loadStaff();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: context.scaffoldBg,
        appBar: _buildAppBar(context),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: _buildAppBar(context),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),

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
                    hintText: 'Search staff...',
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
                    label: 'All Staff',
                    count: _staff.length,
                    isActive: _filter == _StaffFilter.all,
                    onTap: () => setState(() => _filter = _StaffFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Drivers',
                    count: _driverCount,
                    isActive: _filter == _StaffFilter.drivers,
                    onTap: () => setState(() => _filter = _StaffFilter.drivers),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Fleet Managers',
                    count: _managerCount,
                    isActive: _filter == _StaffFilter.managers,
                    onTap: () => setState(() => _filter = _StaffFilter.managers),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Active',
                    count: _activeCount,
                    isActive: _filter == _StaffFilter.active,
                    onTap: () => setState(() => _filter = _StaffFilter.active),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: context.scaffoldBg,
      elevation: 0,
      iconTheme: IconThemeData(color: context.textPrimary),
      title: Text(
        'Drivers & Staff',
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: context.textPrimary),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'driver') _openCreateDriver();
              if (value == 'manager') _openCreateFleetManager();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'driver',
                child: Row(children: [Icon(Icons.person_outline, size: 18), SizedBox(width: 10), Text('Driver')]),
              ),
              const PopupMenuItem(
                value: 'manager',
                child: Row(children: [Icon(Icons.badge_outlined, size: 18), SizedBox(width: 10), Text('Fleet Manager')]),
              ),
            ],
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
      ],
    );
  }

  Widget _buildList() {
    if (_staff.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.people_outline,
        title: 'No staff yet',
        subtitle: 'Add a driver or fleet manager to get started.',
        action: ElevatedButton.icon(
          onPressed: _openCreateDriver,
          icon: const Icon(Icons.add),
          label: const Text('Add Driver'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
        ),
      );
    }

    final filtered = _filteredStaff;
    if (filtered.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.search_off,
        title: 'No matching staff',
        subtitle: 'Try a different search term or filter.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: filtered.length,
      separatorBuilder: (context, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _StaffCard(
        member: filtered[index],
        avatarColor: _avatarPalette[_staff.indexOf(filtered[index]) % _avatarPalette.length],
        onRefresh: _loadStaff,
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

class _StaffCard extends StatefulWidget {
  final _StaffMember member;
  final Color avatarColor;
  final VoidCallback onRefresh;

  const _StaffCard({
    required this.member,
    required this.avatarColor,
    required this.onRefresh,
  });

  @override
  State<_StaffCard> createState() => _StaffCardState();
}

class _StaffCardState extends State<_StaffCard> {
  final _shuttleService = ShuttleService();
  bool _busy = false;

  Future<void> _openEdit() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditStaffScreen(
          id: widget.member.id,
          name: widget.member.name,
          email: widget.member.email,
          isFleetManager: widget.member.isFleetManager,
        ),
      ),
    );
    if (updated == true) widget.onRefresh();
  }

  Future<void> _toggleStatus() async {
    setState(() => _busy = true);
    final auth = context.read<AuthenticationProvider>();
    final newStatus = !widget.member.isActive;
    try {
      final result = widget.member.isFleetManager
          ? await _shuttleService.setFleetManagerStatus(
              accessToken: auth.accessToken!,
              managerId: widget.member.id,
              isActive: newStatus,
            )
          : await _shuttleService.setDriverStatus(
              accessToken: auth.accessToken!,
              driverId: widget.member.id,
              isActive: newStatus,
            );
      if (mounted) {
        if (result.success) {
          widget.onRefresh();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(newStatus ? 'Activated: ${widget.member.name}' : 'Deactivated: ${widget.member.name}')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message ?? 'Failed to update status'), backgroundColor: AppColors.error),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showDeleteConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${widget.member.isFleetManager ? 'Fleet Manager' : 'Driver'}?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'This will remove "${widget.member.name}" from active staff. This action cannot be undone.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _busy
                ? null
                : () async {
                    setState(() => _busy = true);
                    final auth = context.read<AuthenticationProvider>();
                    try {
                      final result = widget.member.isFleetManager
                          ? await _shuttleService.deleteFleetManager(
                              accessToken: auth.accessToken!,
                              managerId: widget.member.id,
                            )
                          : await _shuttleService.deleteDriver(
                              accessToken: auth.accessToken!,
                              driverId: widget.member.id,
                            );
                      if (context.mounted) {
                        Navigator.pop(context);
                        if (result.success) {
                          widget.onRefresh();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Deleted: ${widget.member.name}')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(result.message ?? 'Failed to delete'), backgroundColor: AppColors.error),
                          );
                        }
                      }
                    } finally {
                      if (mounted) setState(() => _busy = false);
                    }
                  },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: _busy
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
    final member = widget.member;

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.divider),
      ),
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
                        member.name.isNotEmpty ? member.name.substring(0, 1).toUpperCase() : '?',
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
                          color: member.isActive ? AppColors.success : context.textSecondary,
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
                        member.name,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15, color: context.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        member.email,
                        style: GoogleFonts.poppins(fontSize: 12, color: context.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (member.isFleetManager ? Colors.blue : AppColors.primaryGreen).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          member.isFleetManager ? 'Fleet Manager' : 'Driver',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: member.isFleetManager ? Colors.blue : AppColors.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: context.textSecondary, size: 20),
                  onSelected: (value) {
                    if (value == 'edit') _openEdit();
                    if (value == 'status') _toggleStatus();
                    if (value == 'delete') _showDeleteConfirm();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 10), Text('Edit')]),
                    ),
                    PopupMenuItem(
                      value: 'status',
                      enabled: !_busy,
                      child: Row(
                        children: [
                          Icon(member.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline, size: 18),
                          const SizedBox(width: 10),
                          Text(member.isActive ? 'Deactivate' : 'Activate'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      enabled: !_busy,
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
            if (!member.isFleetManager) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MiniInfo(
                      icon: Icons.directions_bus_outlined,
                      label: 'Shuttle',
                      value: member.assignedShuttleName ?? 'Not assigned',
                    ),
                  ),
                  Expanded(
                    child: _MiniInfo(
                      icon: Icons.alt_route,
                      label: 'Route',
                      value: member.assignedRouteName ?? 'Not assigned',
                    ),
                  ),
                ],
              ),
            ],
          ],
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
