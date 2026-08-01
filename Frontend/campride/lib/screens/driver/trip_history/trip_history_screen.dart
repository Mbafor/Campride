import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../../providers/authentication_provider.dart';
import '../../../config/api_config.dart';
import '../../../theme/app_colors.dart';

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

      final response = await http.get(
        Uri.parse('${ApiConfig.baseHttpUrl}/driver/trips?limit=$_pageSize&offset=$_offset'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Trip History',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading && _trips.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _trips.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _error!,
                              style: GoogleFonts.poppins(fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : _trips.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history_outlined,
                                  size: 64,
                                  color: AppColors.textSecondaryLight,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'No Trips Yet',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Your completed trips will appear here',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _trips.length + (_loading ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _trips.length) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                                    ),
                                  ),
                                );
                              }

                              final trip = _trips[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.route, size: 18, color: AppColors.primaryGreen),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                trip.routeName,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Icon(Icons.airport_shuttle, size: 16, color: AppColors.textSecondaryLight),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '${trip.shuttleName} (${trip.shuttlePlate})',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: AppColors.textSecondaryLight,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Icon(Icons.schedule, size: 16, color: AppColors.textSecondaryLight),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                DateFormat('MMM dd, HH:mm').format(trip.startedAt),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: AppColors.textSecondaryLight,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (trip.durationSeconds != null) ...[
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Icon(Icons.timer, size: 16, color: AppColors.textSecondaryLight),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${(trip.durationSeconds! ~/ 60).toString().padLeft(2, '0')}:${(trip.durationSeconds! % 60).toString().padLeft(2, '0')} min',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: AppColors.textSecondaryLight,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
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
