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
              'Shuttles will appear here once they are added to the fleet',
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondaryLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _shuttles.length,
      separatorBuilder: (context, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _ShuttleCard(shuttle: _shuttles[index]),
    );
  }
}

class _ShuttleCard extends StatelessWidget {
  final ShuttleInfo shuttle;

  const _ShuttleCard({required this.shuttle});

  Color _getStatusColor() {
    switch (shuttle.status.toLowerCase()) {
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
    return shuttle.status.substring(0, 1).toUpperCase() + shuttle.status.substring(1);
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
                  '${shuttle.capacity} seats',
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
                  shuttle.assignedDriverName ?? 'Not assigned',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
