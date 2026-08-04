import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/authentication_provider.dart';
import '../../services/recent_searches_service.dart';
import '../../services/stops_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';

/// Opens a Google-Maps-style pull-up search panel showing recent destinations
/// and all available campus stops. The returned future completes with the
/// selected [StopInfo], or `null` if the sheet is dismissed.
Future<StopInfo?> showStopSearchSheet(BuildContext context) {
  return showModalBottomSheet<StopInfo>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    useSafeArea: true,
    builder: (_) => const StopSearchSheet(),
  );
}

/// Draggable bottom sheet used for "Where to?" search. Starts partially
/// expanded and can be pulled up to reveal more stops. When the student taps
/// a stop the sheet is dismissed so the caller can navigate onward.
class StopSearchSheet extends StatefulWidget {
  const StopSearchSheet({super.key});

  @override
  State<StopSearchSheet> createState() => _StopSearchSheetState();
}

class _StopSearchSheetState extends State<StopSearchSheet> {
  final _stopsRepository = StopsRepository();
  final _recentSearches = RecentSearchesService();
  final _searchCtrl = TextEditingController();

  bool _isLoadingStops = true;
  String? _errorMessage;
  List<StopInfo> _allStops = [];
  List<StopInfo> _recents = [];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = context.read<AuthenticationProvider>();
    final accessToken = auth.accessToken;

    final recents = await _recentSearches.getRecents();
    if (mounted) setState(() => _recents = recents);

    try {
      if (accessToken == null) throw Exception('Not authenticated');
      final stops = await _stopsRepository.fetchAllStops(accessToken);
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
  }

  String get _query => _searchCtrl.text.trim().toLowerCase();

  bool get _isSearching => _query.isNotEmpty;

  List<StopInfo> get _filteredStops =>
      _allStops.where((s) => s.name.toLowerCase().contains(_query)).toList();

  void _selectStop(StopInfo stop) {
    Navigator.pop(context, stop);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        autofocus: false,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Where to?',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: context.textSecondary,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: context.textSecondary,
                            size: 20,
                          ),
                          suffixIcon: _isSearching
                              ? GestureDetector(
                                  onTap: _searchCtrl.clear,
                                  child: Icon(
                                    Icons.close,
                                    color: context.textSecondary,
                                    size: 18,
                                  ),
                                )
                              : null,
                          filled: true,
                          fillColor: context.fieldFill,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(child: _buildContent(scrollController)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(ScrollController scrollController) {
    if (_isSearching) {
      if (_isLoadingStops) {
        return Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        );
      }
      if (_errorMessage != null) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            _errorMessage!,
            style: GoogleFonts.poppins(color: AppColors.error, fontSize: 13),
          ),
        );
      }
      final results = _filteredStops;
      if (results.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 44, color: context.textSecondary),
              const SizedBox(height: 12),
              Text(
                'No matching stops',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'We couldn\'t find a stop matching '
                  '"${_searchCtrl.text.trim()}". Try a different name.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: context.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return ListView.separated(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        itemCount: results.length,
        separatorBuilder: (_, _) => Divider(height: 1, color: context.divider),
        itemBuilder: (_, i) => _StopTile(
          icon: Icons.location_on_outlined,
          name: results[i].name,
          subtitle: results[i].routeName,
          onTap: () => _selectStop(results[i]),
        ),
      );
    }

    // Default view — recents + available stops.
    if (_isLoadingStops) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      );
    }
    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          _errorMessage!,
          style: GoogleFonts.poppins(color: AppColors.error, fontSize: 13),
        ),
      );
    }

    final retainedRecents = _recents
        .where((r) => _allStops.any((s) => s.id == r.id) || _allStops.isEmpty)
        .toList();

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      children: [
        // ── Recents ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Recents',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
        ),
        if (retainedRecents.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'No recent destinations yet. Search for a stop and it will '
              'appear here for quick access.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: context.textSecondary,
              ),
            ),
          )
        else
          ...retainedRecents.map(
            (s) => _StopTile(
              icon: Icons.access_time,
              name: s.name,
              subtitle: s.routeName,
              onTap: () => _selectStop(s),
            ),
          ),
        const SizedBox(height: 12),
        Divider(height: 1, color: context.divider),
        const SizedBox(height: 8),

        // ── Available Stops ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Available Stops',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
        ),
        ..._allStops.map(
          (s) => _StopTile(
            icon: Icons.location_on_outlined,
            name: s.name,
            subtitle: s.routeName,
            onTap: () => _selectStop(s),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _StopTile extends StatelessWidget {
  final IconData icon;
  final String name;
  final String subtitle;
  final VoidCallback onTap;

  const _StopTile({
    required this.icon,
    required this.name,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 38,
              height: 38,
              child: Container(
                decoration: BoxDecoration(
                  color: context.fieldFill,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: context.textSecondary, size: 20),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: context.textPrimary,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
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
          ],
        ),
      ),
    );
  }
}
