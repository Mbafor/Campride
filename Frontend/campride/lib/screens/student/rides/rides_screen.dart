import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../../providers/authentication_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common/empty_state_widget.dart';
import '../where_to/where_to_screen.dart';

class RidesScreen extends StatefulWidget {
  const RidesScreen({super.key});

  @override
  State<RidesScreen> createState() => _RidesScreenState();
}

class _RidesScreenState extends State<RidesScreen> {
  List<Map<String, dynamic>> _rides = [];
  bool _isLoading = true;
  String? _errorMessage;

  /// 0 = Past (completed rides), 1 = Ongoing (boarded, not yet alighted).
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  Future<void> _loadRides() async {
    try {
      final auth = context.read<AuthenticationProvider>();
      if (auth.accessToken == null) {
        setState(() {
          _errorMessage = 'Authentication failed';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseHttpUrl}/students/me/rides'),
        headers: {
          'Authorization': 'Bearer ${auth.accessToken}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _rides = List<Map<String, dynamic>>.from(data['rides'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load rides';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading rides: $e';
        _isLoading = false;
      });
    }
  }

  DateTime? _rideDate(Map<String, dynamic> ride) {
    final raw = ride['boarded_at'] ?? ride['created_at'];
    if (raw == null) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('About Rides', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'Past shows rides you\'ve completed. Ongoing shows a ride you\'ve '
          'boarded but haven\'t reached your stop on yet.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Got it', style: GoogleFonts.poppins(color: AppColors.primaryGreen)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: context.textPrimary),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          'Rides',
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: context.textSecondary),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Row(
                children: [
                  _RideTab(label: 'Past', isActive: _tab == 0, onTap: () => setState(() => _tab = 0)),
                  const SizedBox(width: 24),
                  _RideTab(label: 'Ongoing', isActive: _tab == 1, onTap: () => setState(() => _tab = 1)),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: context.divider),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            _errorMessage!,
            style: GoogleFonts.poppins(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final filtered = _rides.where((r) {
      final alighted = r['alighted_at'];
      return _tab == 0 ? alighted != null : alighted == null;
    }).toList();

    if (filtered.isEmpty) {
      return _tab == 0
          ? const EmptyStateWidget(
              icon: Icons.history,
              title: 'No past rides yet',
              subtitle: 'Rides you complete will show up here.',
            )
          : const EmptyStateWidget(
              icon: Icons.directions_bus_outlined,
              title: 'No ongoing ride',
              subtitle: 'When you board a shuttle, it will appear here until you reach your stop.',
            );
    }

    // Group into month sections, preserving the backend's most-recent-first order.
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final ride in filtered) {
      final date = _rideDate(ride);
      final key = date != null ? DateFormat('MMMM yyyy').format(date) : 'Unknown';
      groups.putIfAbsent(key, () => []).add(ride);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        for (final entry in groups.entries) ...[
          Text(
            entry.key,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < entry.value.length; i++) ...[
            _RideRow(ride: entry.value[i], rideDate: _rideDate(entry.value[i])),
            if (i != entry.value.length - 1) Divider(height: 1, color: context.divider),
          ],
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

class _RideTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _RideTab({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? context.textPrimary : context.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 34,
              height: 3,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RideRow extends StatelessWidget {
  final Map<String, dynamic> ride;
  final DateTime? rideDate;

  const _RideRow({required this.ride, required this.rideDate});

  String _formatWhen(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final time = DateFormat('h:mm a').format(date).toLowerCase();
    final day = isToday ? 'Today' : DateFormat('d MMM').format(date);
    return '$day · $time';
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes == 0) return '${secs}s';
    if (secs == 0) return '${minutes}m';
    return '${minutes}m ${secs}s';
  }

  @override
  Widget build(BuildContext context) {
    final routeName = ride['route_name'] ?? 'Unknown route';
    final shuttleName = ride['shuttle_name'] ?? 'Unknown shuttle';
    final shuttlePlate = ride['shuttle_plate'] ?? '';
    final durationSeconds = ride['duration_seconds'] as int?;
    final isOngoing = ride['alighted_at'] == null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            margin: const EdgeInsets.only(top: 20),
            decoration: BoxDecoration(color: context.fieldFill, shape: BoxShape.circle),
            child: Icon(Icons.directions_bus_outlined, size: 20, color: context.textSecondary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatWhen(rideDate),
                  style: GoogleFonts.poppins(fontSize: 13, color: context.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  routeName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOngoing
                      ? 'In progress'
                      : durationSeconds != null
                          ? '$shuttleName • ${_formatDuration(durationSeconds)}'
                          : shuttleName,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isOngoing ? Colors.orange : AppColors.primaryGreen,
                  ),
                ),
                if (shuttlePlate.isNotEmpty && !isOngoing) ...[
                  const SizedBox(height: 2),
                  Text(
                    shuttlePlate,
                    style: GoogleFonts.poppins(fontSize: 11, color: context.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WhereToScreen()),
            ),
            child: Container(
              margin: const EdgeInsets.only(top: 20),
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: context.fieldFill, shape: BoxShape.circle),
              child: const Icon(Icons.refresh, size: 20, color: AppColors.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }
}
