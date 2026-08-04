import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/authentication_provider.dart';
import '../../../services/recent_searches_service.dart';
import '../../../services/shuttle_service.dart';
import '../../../services/stops_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/theme_extensions.dart';
import '../../../widgets/common/empty_state_widget.dart';
import '../live_shuttles_screen.dart';

/// Pickup/dropoff confirmation screen, matching the "ROUTE" mockup panel.
/// Pickup is auto-detected from the student's location; dropoff arrives
/// pre-filled from [WhereToScreen]. Selecting a suggestion matches shuttles
/// for real via the backend and hands off to the live map.
class RouteConfirmScreen extends StatefulWidget {
  final StopInfo initialDropoff;

  const RouteConfirmScreen({super.key, required this.initialDropoff});

  @override
  State<RouteConfirmScreen> createState() => _RouteConfirmScreenState();
}

class _RouteConfirmScreenState extends State<RouteConfirmScreen> {
  final _stopsRepository = StopsRepository();
  final _recentSearches = RecentSearchesService();
  final _shuttleService = ShuttleService();

  final _pickupCtrl = TextEditingController(text: 'Detecting location...');
  final _dropoffCtrl = TextEditingController();
  final _dropoffFocus = FocusNode();

  bool _dropoffFocused = false;
  bool _isLoadingStops = true;
  bool _isMatching = false;
  String? _errorMessage;

  List<StopInfo> _allStops = [];
  StopInfo? _pickupStop;
  StopInfo? _dropoffStop;
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _dropoffStop = widget.initialDropoff;
    _dropoffCtrl.text = widget.initialDropoff.name;
    _dropoffCtrl.addListener(() => setState(() {}));
    _dropoffFocus.addListener(() {
      setState(() => _dropoffFocused = _dropoffFocus.hasFocus);
    });
    _load();
  }

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _dropoffCtrl.dispose();
    _dropoffFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final auth = context.read<AuthenticationProvider>();
      if (auth.accessToken == null) throw Exception('Not authenticated');
      final stops = await _stopsRepository.fetchAllStops(auth.accessToken!);
      if (mounted) {
        setState(() {
          _allStops = stops;
          _isLoadingStops = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStops = false;
          _errorMessage = 'Could not load stops: $e';
        });
      }
    }
    await _detectPickup();
  }

  Future<void> _detectPickup() async {
    setState(() => _pickupCtrl.text = 'Detecting location...');
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services disabled');

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (!mounted) return;
      setState(() => _userPosition = position);

      if (_allStops.isNotEmpty) {
        final nearest = _allStops.reduce(
          (a, b) =>
              _distanceKm(position.latitude, position.longitude, a.lat, a.lng) <
                  _distanceKm(
                    position.latitude,
                    position.longitude,
                    b.lat,
                    b.lng,
                  )
              ? a
              : b,
        );
        if (mounted) {
          setState(() {
            _pickupStop = nearest;
            _pickupCtrl.text = nearest.name;
          });
        }
      } else if (mounted) {
        setState(() => _pickupCtrl.text = 'Current location');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pickupStop = null;
          _pickupCtrl.text = 'Location unavailable';
        });
      }
    }
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _toRad(double deg) => deg * pi / 180;

  List<StopInfo> get _suggestions {
    final query = _dropoffCtrl.text.trim().toLowerCase();
    final candidates = _allStops.where((s) => s.id != _pickupStop?.id);
    if (query.isEmpty) return candidates.toList();
    return candidates
        .where((s) => s.name.toLowerCase().contains(query))
        .toList();
  }

  void _swap() {
    setState(() {
      final tmpStop = _pickupStop;
      final tmpText = _pickupCtrl.text;
      _pickupStop = _dropoffStop;
      _pickupCtrl.text = _dropoffCtrl.text;
      _dropoffStop = tmpStop;
      _dropoffCtrl.text = tmpText;
    });
  }

  Future<void> _selectDropoff(StopInfo stop) async {
    setState(() {
      _dropoffStop = stop;
      _dropoffCtrl.text = stop.name;
    });
    FocusScope.of(context).unfocus();
    await _submit();
  }

  Future<void> _submit() async {
    final pickup = _pickupStop;
    final dropoff = _dropoffStop;

    if (pickup == null) {
      _showMessage('Could not detect your pickup location. Try again.');
      return;
    }
    if (dropoff == null) {
      _showMessage('Please choose a destination.');
      return;
    }
    if (pickup.id == dropoff.id) {
      _showMessage('Pickup and destination cannot be the same stop.');
      return;
    }

    setState(() => _isMatching = true);

    final auth = context.read<AuthenticationProvider>();
    if (auth.accessToken == null) {
      setState(() => _isMatching = false);
      _showMessage('Authentication failed. Please log in again.');
      return;
    }

    final response = await _shuttleService.matchShuttles(
      accessToken: auth.accessToken!,
      pickupLat: pickup.lat,
      pickupLng: pickup.lng,
      destLat: dropoff.lat,
      destLng: dropoff.lng,
    );

    if (!mounted) return;

    if (!response.success || response.data == null) {
      setState(() => _isMatching = false);
      _showMessage(response.message ?? 'Failed to match shuttles');
      return;
    }

    await _recentSearches.addRecent(dropoff);

    final matched = (response.data!['matched'] as List?) ?? const [];
    String? driverId;
    int? etaMinutes;
    if (matched.isNotEmpty) {
      final best = matched.first as Map<String, dynamic>;
      driverId = best['driver_id'] as String?;
      etaMinutes = (best['eta_minutes'] as num?)?.toInt();
    }

    if (!mounted) return;
    setState(() => _isMatching = false);

    if (matched.isEmpty) {
      _showMessage('No shuttles are currently available for this route.');
      return;
    }

    // Return to Home, then open the live map with the matched shuttle
    // highlighted — mirrors the app's existing match -> live-map handoff.
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveShuttlesScreen(
          matchedShuttleId: driverId,
          etaMinutes: etaMinutes,
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    'Route',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.close,
                        size: 24,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: context.fieldFill,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF3D3DCC),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _pickupCtrl.text,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: context.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _detectPickup,
                        child: Icon(
                          Icons.my_location,
                          size: 20,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: context.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _dropoffFocused
                                  ? const Color(0xFF4CAF50)
                                  : context.fieldBorder,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search,
                                color: context.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _dropoffCtrl,
                                  focusNode: _dropoffFocus,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    color: context.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    hintText: 'Dropoff location',
                                    hintStyle: GoogleFonts.poppins(
                                      fontSize: 15,
                                      color: context.textSecondary,
                                    ),
                                  ),
                                  onChanged: (_) {
                                    // Typing invalidates the previously selected stop
                                    // until the student picks a suggestion again.
                                    _dropoffStop = null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.location_on,
                                color: context.textSecondary,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _swap,
                        child: Icon(
                          Icons.swap_vert,
                          size: 24,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: context.divider),
            Expanded(child: _buildSuggestions()),
            if (_isMatching)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Finding shuttles...',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    if (_isLoadingStops) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            _errorMessage!,
            style: GoogleFonts.poppins(color: AppColors.error, fontSize: 13),
          ),
        ),
      );
    }
    final suggestions = _suggestions;
    if (suggestions.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.location_off_outlined,
        title: 'No stops found',
        subtitle:
            'Try searching for a different destination or check the spelling.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      itemCount: suggestions.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: context.divider),
      itemBuilder: (_, i) {
        final stop = suggestions[i];
        final distanceText = _userPosition != null
            ? '${_distanceKm(_userPosition!.latitude, _userPosition!.longitude, stop.lat, stop.lng).toStringAsFixed(1)} km'
            : null;
        return _SuggestionTile(
          name: stop.name,
          subtitle: stop.routeName,
          distanceText: distanceText,
          onTap: _isMatching ? null : () => _selectDropoff(stop),
        );
      },
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final String? distanceText;
  final VoidCallback? onTap;

  const _SuggestionTile({
    required this.name,
    required this.subtitle,
    required this.distanceText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(Icons.access_time, color: context.textSecondary, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (distanceText != null)
              Text(
                distanceText!,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: context.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
