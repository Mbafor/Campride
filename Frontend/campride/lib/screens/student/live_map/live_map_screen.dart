import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/shuttle_model.dart';
import '../../../services/mock_shuttle_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/common/empty_state_widget.dart';
import '../../../widgets/common/section_header.dart';

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen>
    with SingleTickerProviderStateMixin {
  final _shuttleService = MockShuttleService();
  List<ShuttleModel> _shuttles = [];
  bool _loading = true;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadShuttles();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadShuttles() async {
    final data = await _shuttleService.getActiveShuttles();
    if (mounted) setState(() { _shuttles = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadShuttles,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MapPlaceholder(pulseController: _pulseController),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Active Shuttles'),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ))
            else if (_shuttles.isEmpty)
              const EmptyStateWidget(
                icon: Icons.directions_bus_outlined,
                title: 'No Active Shuttles',
                subtitle: 'Check back later for live shuttle updates',
              )
            else
              ..._shuttles.map((s) => _ShuttleCard(shuttle: s)),
          ],
        ),
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  final AnimationController pulseController;
  const _MapPlaceholder({required this.pulseController});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Grid lines
          CustomPaint(
            size: const Size(double.infinity, 220),
            painter: _GridPainter(),
          ),
          AnimatedBuilder(
            animation: pulseController,
            builder: (context, child) => Container(
              width: 80 + pulseController.value * 30,
              height: 80 + pulseController.value * 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGreen.withOpacity(0.1 - pulseController.value * 0.08),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, size: 48, color: AppColors.primaryGreen.withOpacity(0.6)),
              const SizedBox(height: 8),
              Text(
                'Live Map',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGreen,
                ),
              ),
              Text(
                'Real-time tracking coming soon',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryGreen.withOpacity(0.06)
      ..strokeWidth = 1;
    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ShuttleCard extends StatelessWidget {
  final ShuttleModel shuttle;
  const _ShuttleCard({required this.shuttle});

  @override
  Widget build(BuildContext context) {
    final occupancyColor = shuttle.occupancyRate > 0.8
        ? AppColors.error
        : shuttle.occupancyRate > 0.6
            ? AppColors.warning
            : AppColors.success;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.directions_bus, color: AppColors.primaryGreen, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shuttle.plateNumber,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      Text(
                        shuttle.driverName,
                        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${shuttle.minutesAway} min',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondaryLight),
                const SizedBox(width: 4),
                Text(
                  shuttle.currentLocation,
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
                const Icon(Icons.arrow_forward, size: 14, color: AppColors.textSecondaryLight),
                Text(
                  shuttle.nextStop,
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: shuttle.occupancyRate,
                      backgroundColor: Colors.grey.shade200,
                      color: occupancyColor,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${shuttle.occupancy}/${shuttle.capacity}',
                  style: GoogleFonts.poppins(fontSize: 12, color: occupancyColor, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
