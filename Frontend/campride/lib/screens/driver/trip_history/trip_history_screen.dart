import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../../providers/authentication_provider.dart';
import '../../../config/api_config.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/theme_extensions.dart';
import '../../../widgets/common/empty_state_widget.dart';

class DriverTripData {
  final String tripId;
  final String routeName;
  final String shuttleName;
  final String shuttlePlate;
  final DateTime startedAt;
  final DateTime endedAt;
  final int? durationSeconds;

  DriverTripData({
    required this.tripId,
    required this.routeName,
    required this.shuttleName,
    required this.shuttlePlate,
    required this.startedAt,
    required this.endedAt,
    this.durationSeconds,
  });

  factory DriverTripData.fromJson(Map<String, dynamic> json) {
    return DriverTripData(
      tripId: json['trip_id'] ?? '',
      routeName: json['route_name'] ?? '',
      shuttleName: json['shuttle_name'] ?? '',
      shuttlePlate: json['shuttle_plate'] ?? '',
      startedAt: DateTime.parse(json['started_at'] ?? DateTime.now().toIso8601String()),
      endedAt: DateTime.parse(json['ended_at'] ?? DateTime.now().toIso8601String()),
      durationSeconds: json['duration_seconds'],
    );
  }
}

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  List<DriverTripData> _trips = [];
  bool _loading = false;
  int _totalCount = 0;
  int _offset = 0;
  final int _pageSize = 20;
  String? _error;
  DateTime? _selectedDate;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadTrips();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (_trips.length < _totalCount && !_loading) {
        _loadMoreTrips();
      }
    }
  }

  Future<void> _loadTrips({bool reset = true}) async {
    if (!mounted) return;

    setState(() {
      if (reset) {
        _trips = [];
        _offset = 0;
      }
      _loading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthenticationProvider>(context, listen: false);
      final token = authProvider.accessToken;

      if (token == null) {
        if (mounted) {
          setState(() {
            _error = 'Not authenticated';
            _loading = false;
          });
        }
        return;
      }

      final dateParam = _selectedDate != null
          ? '&date=${DateFormat('yyyy-MM-dd').format(_selectedDate!)}'
          : '';
      final response = await http.get(
        Uri.parse('${ApiConfig.baseHttpUrl}/driver/trips?limit=$_pageSize&offset=$_offset$dateParam'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tripList = (data['trips'] as List? ?? [])
            .map((t) => DriverTripData.fromJson(t as Map<String, dynamic>))
            .toList();

        setState(() {
          if (reset) {
            _trips = tripList;
          } else {
            _trips.addAll(tripList);
          }
          _totalCount = data['count'] ?? 0;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load trips (${response.statusCode})';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadMoreTrips() async {
    if (_loading) return;
    _offset += _pageSize;
    await _loadTrips(reset: false);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
    _loadTrips();
  }

  void _clearDateFilter() {
    setState(() => _selectedDate = null);
    _loadTrips();
  }

  /// [_trips] (already most-recent-first) flattened into month header
  /// strings interleaved with the trips that fall under them.
  List<dynamic> get _flatItems {
    final items = <dynamic>[];
    String? lastMonthKey;
    for (final trip in _trips) {
      final key = DateFormat('MMMM yyyy').format(trip.startedAt);
      if (key != lastMonthKey) {
        items.add(key);
        lastMonthKey = key;
      }
      items.add(trip);
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Trip History',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _pickDate,
                  icon: Icon(Icons.calendar_month_outlined, color: context.textPrimary),
                  tooltip: 'Filter by date',
                ),
              ],
            ),
          ),
          if (_selectedDate != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('d MMM yyyy').format(_selectedDate!),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: _clearDateFilter,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.close, size: 16, color: AppColors.primaryGreen),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading && _trips.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _trips.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            _error!,
                            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.error),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : _trips.isEmpty
                        ? _selectedDate != null
                            ? EmptyStateWidget(
                                icon: Icons.event_busy_outlined,
                                title: 'No trips on this date',
                                subtitle: 'Try a different date, or clear the filter to see all trips.',
                                action: TextButton(
                                  onPressed: _clearDateFilter,
                                  child: Text(
                                    'Clear filter',
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600, color: AppColors.primaryGreen),
                                  ),
                                ),
                              )
                            : const EmptyStateWidget(
                                icon: Icons.history_outlined,
                                title: 'No trips yet',
                                subtitle: 'Start a trip from the Home tab — it will show up here once you end it.',
                              )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            itemCount: _flatItems.length + (_loading ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _flatItems.length) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                                    ),
                                  ),
                                );
                              }

                              final item = _flatItems[index];
                              if (item is String) {
                                return Padding(
                                  padding: EdgeInsets.fromLTRB(0, index == 0 ? 8 : 20, 0, 8),
                                  child: Text(
                                    item,
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                );
                              }

                              final trip = item as DriverTripData;
                              final isLast = index == _flatItems.length - 1 ||
                                  _flatItems[index + 1] is String;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _TripRow(trip: trip),
                                  if (!isLast) Divider(height: 1, color: context.divider),
                                ],
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _TripRow extends StatelessWidget {
  final DriverTripData trip;

  const _TripRow({required this.trip});

  String _formatWhen(DateTime date) {
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(color: context.fieldFill, shape: BoxShape.circle),
            child: Icon(Icons.directions_bus_outlined, size: 20, color: context.textSecondary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatWhen(trip.startedAt),
                  style: GoogleFonts.poppins(fontSize: 13, color: context.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  trip.routeName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  trip.durationSeconds != null
                      ? '${trip.shuttleName} • ${_formatDuration(trip.durationSeconds!)}'
                      : trip.shuttleName,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryGreen,
                  ),
                ),
                if (trip.shuttlePlate.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    trip.shuttlePlate,
                    style: GoogleFonts.poppins(fontSize: 11, color: context.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
