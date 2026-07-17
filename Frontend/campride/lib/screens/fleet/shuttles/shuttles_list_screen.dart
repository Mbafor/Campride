import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/authentication_provider.dart';
import '../../../services/shuttle_service.dart';
import '../../../theme/app_colors.dart';

class ShuttlesListScreen extends StatefulWidget {
  const ShuttlesListScreen({super.key});

  @override
  State<ShuttlesListScreen> createState() => _ShuttlesListScreenState();
}

class _ShuttlesListScreenState extends State<ShuttlesListScreen> {
  final _shuttleService = ShuttleService();
  List<ShuttleInfo> _shuttles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadShuttles();
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

  void _showCreateShuttleDialog() {
    final nameController = TextEditingController();
    final plateController = TextEditingController();
    final capacityController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Create Shuttle', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Shuttle Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                  enabled: !isSubmitting,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: plateController,
                  decoration: InputDecoration(
                    labelText: 'Plate Number',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                  enabled: !isSubmitting,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: capacityController,
                  decoration: InputDecoration(
                    labelText: 'Capacity (seats)',
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
                        await _shuttleService.createShuttle(
                          accessToken: auth.accessToken!,
                          name: nameController.text,
                          plateNumber: plateController.text,
                          capacity: int.parse(capacityController.text),
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          _loadShuttles();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Shuttle created: ${nameController.text}')),
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
                backgroundColor: AppColors.primaryGreen,
              ),
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

    if (_shuttles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.airport_shuttle, size: 48, color: AppColors.textSecondaryLight),
            const SizedBox(height: 16),
            Text(
              'No Shuttles Yet',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a shuttle to get started',
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondaryLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showCreateShuttleDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Shuttle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _shuttles.length,
          separatorBuilder: (context, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) => _ShuttleCard(
            shuttle: _shuttles[index],
            onRefresh: _loadShuttles,
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _showCreateShuttleDialog,
            backgroundColor: AppColors.primaryGreen,
            child: const Icon(Icons.add),
          ),
        ),
      ],
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
        return AppColors.textSecondaryLight;
    }
  }

  String _getStatusLabel() {
    return widget.shuttle.status.substring(0, 1).toUpperCase() + widget.shuttle.status.substring(1);
  }

  void _showEditDialog() {
    final nameController = TextEditingController(text: widget.shuttle.name);
    final capacityController = TextEditingController(text: widget.shuttle.capacity.toString());
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit Shuttle', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Shuttle Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                  enabled: !isSubmitting,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: capacityController,
                  decoration: InputDecoration(
                    labelText: 'Capacity (seats)',
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
                        await _shuttleService.updateShuttle(
                          accessToken: auth.accessToken!,
                          shuttleId: widget.shuttle.id,
                          name: nameController.text,
                          capacity: int.parse(capacityController.text),
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          widget.onRefresh();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Updated: ${nameController.text}')),
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
                backgroundColor: AppColors.primaryGreen,
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
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
    return Card(
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
                    color: AppColors.primaryGreen.withOpacity(0.1),
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
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      Text(
                        widget.shuttle.plateNumber,
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
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
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  'Capacity',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
                const Spacer(),
                Text(
                  '${widget.shuttle.capacity} seats',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
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
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
                const Spacer(),
                Text(
                  widget.shuttle.assignedDriverName ?? 'Not assigned',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Live tracking — coming in Phase 5',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showEditDialog,
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isDeleting ? null : _showDeleteConfirm,
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
