import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';

class _TripRecord {
  final String id;
  final String route;
  final DateTime date;
  final String duration;
  final int passengers;
  final String status;

  const _TripRecord({
    required this.id,
    required this.route,
    required this.date,
    required this.duration,
    required this.passengers,
    required this.status,
  });
}

final _mockTrips = [
  _TripRecord(
    id: 'trip_001',
    route: 'Brunei Hall → KSB → Unity Hall',
    date: DateTime.now().subtract(const Duration(hours: 3)),
    duration: '45 min',
    passengers: 28,
    status: 'Completed',
  ),
  _TripRecord(
    id: 'trip_002',
    route: 'Main Gate → Pent Hall → JCRC',
    date: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    duration: '55 min',
    passengers: 31,
    status: 'Completed',
  ),
  _TripRecord(
    id: 'trip_003',
    route: 'Tech Junction → Faculty of Engineering',
    date: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
    duration: '30 min',
    passengers: 14,
    status: 'Completed',
  ),
  _TripRecord(
    id: 'trip_004',
    route: 'Brunei Hall → KSB → Unity Hall',
    date: DateTime.now().subtract(const Duration(days: 2)),
    duration: '42 min',
    passengers: 25,
    status: 'Completed',
  ),
  _TripRecord(
    id: 'trip_005',
    route: 'Main Gate → University Hospital',
    date: DateTime.now().subtract(const Duration(days: 3)),
    duration: '20 min',
    passengers: 8,
    status: 'Cancelled',
  ),
];

class TripHistoryScreen extends StatelessWidget {
  const TripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SummaryBanner(),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _mockTrips.length,
            separatorBuilder: (context, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _TripCard(trip: _mockTrips[i]),
          ),
        ),
      ],
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryGreen, AppColors.primaryGreenLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: 'Total Trips', value: '${_mockTrips.length}'),
          Container(width: 1, height: 40, color: Colors.white30),
          _StatItem(
            label: 'Passengers',
            value: '${_mockTrips.fold(0, (s, t) => s + t.passengers)}',
          ),
          Container(width: 1, height: 40, color: Colors.white30),
          _StatItem(label: 'This Week', value: '3'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
      ],
    );
  }
}

class _TripCard extends StatelessWidget {
  final _TripRecord trip;
  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final isCompleted = trip.status == 'Completed';
    final statusColor = isCompleted ? AppColors.success : AppColors.error;

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
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.directions_bus, color: AppColors.primaryGreen, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    trip.route,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    trip.status,
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _TripMeta(icon: Icons.calendar_today_outlined, text: DateFormat('MMM d, y • h:mm a').format(trip.date)),
                const SizedBox(width: 16),
                _TripMeta(icon: Icons.timer_outlined, text: trip.duration),
                const SizedBox(width: 16),
                _TripMeta(icon: Icons.people_outline, text: '${trip.passengers} pax'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TripMeta extends StatelessWidget {
  final IconData icon;
  final String text;
  const _TripMeta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondaryLight),
        const SizedBox(width: 3),
        Text(text, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondaryLight)),
      ],
    );
  }
}
