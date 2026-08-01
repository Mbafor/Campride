import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../../providers/authentication_provider.dart';
import '../../../config/api_config.dart';
import '../../../theme/app_colors.dart';

class FleetTripData {
  final String rideId;
  final String routeName;
  final String shuttleName;
  final String shuttlePlate;
  final DateTime boardedAt;
  final DateTime alightedAt;
  final int? durationSeconds;

  FleetTripData({
    required this.rideId,
    required this.routeName,
    required this.shuttleName,
    required this.shuttlePlate,
    required this.boardedAt,
    required this.alightedAt,
    this.durationSeconds,
  });

  factory FleetTripData.fromJson(Map<String, dynamic> json) {
    return FleetTripData(
      rideId: json['ride_id'] ?? '',
      routeName: json['route_name'] ?? '',
      shuttleName: json['shuttle_name'] ?? '',
      shuttlePlate: json['shuttle_plate'] ?? '',
      boardedAt: DateTime.parse(json['boarded_at'] ?? DateTime.now().toIso8601String()),
      alightedAt: DateTime.parse(json['alighted_at'] ?? DateTime.now().toIso8601String()),
      durationSeconds: json['duration_seconds'],
    );
  }
}

class DriverTripHistoryFullScreen extends StatefulWidget {
  final String driverId;
  final String driverName;

  const DriverTripHistoryFullScreen({
    super.key,
    required this.driverId,
    required this.driverName,
  });

  @override
  State<DriverTripHistoryFullScreen> createState() => _DriverTripHistoryFullScreenState();
}

class _DriverTripHistoryFullScreenState extends State<DriverTripHistoryFullScreen> {
  List<FleetTripData> _trips = [];
  bool _loading = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _pageSize = 20;
  DateTime? _selectedDate;
  String? _error;

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
      if (_hasMore && !_loading) {
        _loadMoreTrips();
      }
    }
  }

  Future<void> _loadTrips({bool reset = true}) async {
    if (!mounted) return;

    if (reset) {
      setState(() {
        _trips = [];
        _offset = 0;
        _hasMore = true;
        _error = null;
        _loading = true;
      });
    } else {
      setState(() => _loading = true);
    }

    try {
      final auth = context.read<AuthenticationProvider>();
      if (auth.accessToken == null) throw Exception('Not authenticated');

      String url = '${ApiConfig.baseHttpUrl}/fleet/drivers/${widget.driverId}/rides?limit=$_pageSize&offset=$_offset';
      if (_selectedDate != null) {
        final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
        url += '&date=$dateStr';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer ${auth.accessToken}'},
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rides = (data['rides'] as List? ?? [])
            .map((r) => FleetTripData.fromJson(r as Map<String, dynamic>))
            .toList();

        final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
        final totalCount = pagination['total_count'] as int? ?? 0;
        final returnedCount = rides.length;

        setState(() {
          if (reset) {
            _trips = rides;
          } else {
            _trips.addAll(rides);
          }
          _hasMore = (_offset + returnedCount) < totalCount;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load trips';
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
    if (_loading || !_hasMore) return;
    setState(() => _offset += _pageSize);
    _loadTrips(reset: false);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadTrips(reset: true);
    }
  }

  void _clearFilter() {
    setState(() => _selectedDate = null);
    _loadTrips(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Trip History — ${widget.driverName}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Filter bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _selectedDate == null
                          ? 'Filter by Date'
                          : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  ),
                ),
                if (_selectedDate != null) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _clearFilter,
                    icon: const Icon(Icons.close, size: 16),
                    label: Text('Clear', style: GoogleFonts.poppins(fontSize: 12)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[400]),
                  ),
                ],
              ],
            ),
          ),
          // Trip list
          Expanded(
            child: _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                        const SizedBox(height: 12),
                        Text(_error!, style: GoogleFonts.poppins(fontSize: 14)),
                      ],
                    ),
                  )
                : _trips.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_outlined, size: 48, color: AppColors.textSecondaryLight),
                            const SizedBox(height: 12),
                            Text(
                              _selectedDate == null ? 'No trips yet' : 'No trips on this date',
                              style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondaryLight),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _trips.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _trips.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                                ),
                              ),
                            );
                          }

                          final trip = _trips[index];
                          final durationStr = trip.durationSeconds != null
                              ? '${trip.durationSeconds! ~/ 60}m'
                              : 'N/A';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.directions_bus, size: 18, color: AppColors.primaryGreen),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                trip.routeName,
                                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                                              ),
                                              Text(
                                                trip.shuttleName,
                                                style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondaryLight),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondaryLight),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat('MMM dd, yyyy').format(trip.boardedAt),
                                          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondaryLight),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(Icons.access_time, size: 14, color: AppColors.textSecondaryLight),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${DateFormat('hh:mm a').format(trip.boardedAt)} - ${DateFormat('hh:mm a').format(trip.alightedAt)}',
                                          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondaryLight),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(Icons.timer, size: 14, color: AppColors.textSecondaryLight),
                                        const SizedBox(width: 4),
                                        Text(
                                          durationStr,
                                          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondaryLight),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
