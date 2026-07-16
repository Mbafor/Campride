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

    final result = await _shuttleService.listShuttles(
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

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadShuttles,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_shuttles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.airport_shuttle, size: 48, color: AppColors.primaryGreen),
              const SizedBox(height: 16),
              Text(
                'No Shuttles',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'No shuttles registered yet',
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondaryLight),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadShuttles,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _shuttles.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _ShuttleCard(shuttle: _shuttles[index]),
      ),
    );
  }
}

class _ShuttleCard extends StatelessWidget {
  final ShuttleInfo shuttle;
  const _ShuttleCard({required this.shuttle});

  @override
  Widget build(BuildContext context) {
    final statusColor = shuttle.status == 'idle' ? AppColors.primaryGreen :
                        shuttle.status == 'active' ? AppColors.success :
                        AppColors.textSecondaryLight;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.2),
                  child: Icon(
                    Icons.directions_bus,
                    color: statusColor,
                  ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    shuttle.status.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.event_seat,
              label: 'Capacity',
              value: '${shuttle.capacity} seats',
            ),
            _InfoRow(
              icon: Icons.person,
              label: 'Driver',
              value: shuttle.assignedDriverName ?? 'Unassigned',
            ),
          ],
        ),
      ),
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
