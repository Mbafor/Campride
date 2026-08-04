import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/authentication_provider.dart';
import '../../../services/shuttle_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/empty_state_widget.dart';
import '../../student/live_shuttles_screen.dart';
import 'shuttle_form_screen.dart';

enum _ShuttleFilter { all, active, idle, offline }

class ShuttlesListScreen extends StatefulWidget {
  const ShuttlesListScreen({super.key});

  @override
  State<ShuttlesListScreen> createState() => _ShuttlesListScreenState();
}

class _ShuttlesListScreenState extends State<ShuttlesListScreen> {
  final _shuttleService = ShuttleService();
  final _searchController = TextEditingController();

  List<ShuttleInfo> _shuttles = [];
  bool _loading = true;
  _ShuttleFilter _filter = _ShuttleFilter.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadShuttles();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadShuttles() async {
    final auth = context.read<AuthenticationProvider>();
    if (auth.accessToken == null) {
      setState(() => _loading = false);
      return;
    }

    final result = await _shuttleService.listShuttles(accessToken: auth.accessToken!);

    if (mounted) {
      setState(() {
        _shuttles = result.data ?? [];
        _loading = false;
      });
    }
  }

  int _countFor(String status) =>
      _shuttles.where((s) => s.status.toLowerCase() == status).length;

  List<ShuttleInfo> get _filteredShuttles {
    var list = _shuttles;
    switch (_filter) {
      case _ShuttleFilter.active:
        list = list.where((s) => s.status.toLowerCase() == 'active').toList();
        break;
      case _ShuttleFilter.idle:
        list = list.where((s) => s.status.toLowerCase() == 'idle').toList();
        break;
      case _ShuttleFilter.offline:
        list = list.where((s) => s.status.toLowerCase() == 'offline').toList();
        break;
      case _ShuttleFilter.all:
        break;
    }

    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((s) {
        return s.name.toLowerCase().contains(q) ||
            s.plateNumber.toLowerCase().contains(q) ||
            s.status.toLowerCase().contains(q) ||
            (s.assignedDriverName?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    return list;
  }

  Future<void> _openCreateShuttle() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ShuttleFormScreen()),
    );
    if (created == true) _loadShuttles();
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
        ),
      );
    }

    if (_shuttles.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.airport_shuttle,
        title: 'No shuttles yet',
        subtitle: 'Add a shuttle to start assigning drivers and routes.',
        action: ElevatedButton.icon(
          onPressed: _openCreateShuttle,
          icon: const Icon(Icons.add),
          label: const Text('Add Shuttle'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
        ),
      );
    }

    final filtered = _filteredShuttles;
    if (filtered.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.search_off,
        title: 'No matching shuttles',
        subtitle: 'Try a different search term or filter.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: filtered.length,
      separatorBuilder: (context, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _ShuttleCard(
        shuttle: filtered[index],
        onRefresh: _loadShuttles,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        'Shuttles',
                        style: GoogleFonts.poppins(
                            fontSize: 26, fontWeight: FontWeight.bold, color: context.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manage your fleet\'s shuttles and assignments',
                        style: GoogleFonts.poppins(fontSize: 12.5, color: context.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _openCreateShuttle,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text('Add Shuttle', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
                  hintText: 'Search shuttles...',
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
                  label: 'All Shuttles',
                  count: _shuttles.length,
                  isActive: _filter == _ShuttleFilter.all,
                  onTap: () => setState(() => _filter = _ShuttleFilter.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Active',
                  count: _countFor('active'),
                  isActive: _filter == _ShuttleFilter.active,
                  onTap: () => setState(() => _filter = _ShuttleFilter.active),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Idle',
                  count: _countFor('idle'),
                  isActive: _filter == _ShuttleFilter.idle,
                  onTap: () => setState(() => _filter = _ShuttleFilter.idle),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Offline',
                  count: _countFor('offline'),
                  isActive: _filter == _ShuttleFilter.offline,
                  onTap: () => setState(() => _filter = _ShuttleFilter.offline),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(child: _buildBody()),
        ],
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

class _ShuttleCard extends StatefulWidget {
  final ShuttleInfo shuttle;
  final VoidCallback onRefresh;

  const _ShuttleCard({
    required this.shuttle,
    required this.onRefresh,
  });

  @override
  State<_ShuttleCard> createState() => _ShuttleCardState();
}

class _ShuttleCardState extends State<_ShuttleCard> {
  final _shuttleService = ShuttleService();
  bool _isDeleting = false;

  Color _getStatusColor() {
    switch (widget.shuttle.status.toLowerCase()) {
      case 'active':
        return AppColors.success;
      case 'idle':
        return AppColors.warning;
      case 'offline':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel() {
    if (widget.shuttle.status.isEmpty) return widget.shuttle.status;
    return widget.shuttle.status.substring(0, 1).toUpperCase() + widget.shuttle.status.substring(1);
  }

  Future<void> _openEditShuttle() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ShuttleFormScreen(shuttle: widget.shuttle)),
    );
    if (updated == true) widget.onRefresh();
  }

  void _showDeleteConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Shuttle?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'This will permanently delete "${widget.shuttle.name}". This action cannot be undone.',
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
                      await _shuttleService.deleteShuttle(
                        accessToken: auth.accessToken!,
                        shuttleId: widget.shuttle.id,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        widget.onRefresh();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Deleted: ${widget.shuttle.name}')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                        );
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
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
                  child: const Icon(Icons.airport_shuttle, color: AppColors.primaryGreen, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.shuttle.name,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimary),
                      ),
                      Text(
                        widget.shuttle.plateNumber,
                        style: GoogleFonts.poppins(fontSize: 12, color: context.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusLabel(),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: context.textSecondary, size: 20),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _openEditShuttle();
                    } else if (value == 'delete') {
                      _showDeleteConfirm();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 10),
                          Text('Edit'),
                        ],
                      ),
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
            Row(
              children: [
                Icon(Icons.people, size: 16, color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  'Capacity',
                  style: GoogleFonts.poppins(fontSize: 12, color: context.textSecondary),
                ),
                const Spacer(),
                Text(
                  '${widget.shuttle.capacity} seats',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: context.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  'Driver',
                  style: GoogleFonts.poppins(fontSize: 12, color: context.textSecondary),
                ),
                const Spacer(),
                Text(
                  widget.shuttle.assignedDriverName ?? 'Not assigned',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: context.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LiveShuttlesScreen()),
                ),
                icon: const Icon(Icons.location_on_outlined, size: 16),
                label: Text('View on Live Map', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGreen,
                  side: const BorderSide(color: AppColors.primaryGreen),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
