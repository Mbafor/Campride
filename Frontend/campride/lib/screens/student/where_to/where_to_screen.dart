import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/authentication_provider.dart';
import '../../../services/recent_searches_service.dart';
import '../../../services/stops_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/theme_extensions.dart';
import '../../../widgets/common/empty_state_widget.dart';
import '../route/route_confirm_screen.dart';

/// "Where to?" search screen — the entry point reached by tapping the
/// home search bar. Shows recent destinations and lets the student search
/// all campus stops, matching the "WHERE TO?" mockup panel.
class WhereToScreen extends StatefulWidget {
  const WhereToScreen({super.key});

  @override
  State<WhereToScreen> createState() => _WhereToScreenState();
}

class _WhereToScreenState extends State<WhereToScreen> {
  final _stopsRepository = StopsRepository();
  final _recentSearches = RecentSearchesService();
  final _searchCtrl = TextEditingController();

  bool _isLoadingStops = true;
  String? _errorMessage;
  List<StopInfo> _allStops = [];
  List<StopInfo> _recents = [];
  List<StopInfo> _results = [];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final recents = await _recentSearches.getRecents();
    if (mounted) setState(() => _recents = recents);

    try {
      final auth = context.read<AuthenticationProvider>();
      if (auth.accessToken == null) {
        throw Exception('Not authenticated');
      }
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
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _results = q.isEmpty
          ? []
          : _allStops.where((s) => s.name.toLowerCase().contains(q)).toList();
    });
  }

  void _selectStop(StopInfo stop) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RouteConfirmScreen(initialDropoff: stop),
      ),
    );
  }

  bool get _isSearching => _searchCtrl.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: context.fieldFill,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: context.fieldFill,
                        borderRadius: BorderRadius.circular(24),
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
                              controller: _searchCtrl,
                              autofocus: true,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: context.textPrimary,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                hintText: 'Where to ?',
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: context.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          if (_isSearching)
                            GestureDetector(
                              onTap: () => _searchCtrl.clear(),
                              child: Icon(
                                Icons.close,
                                color: context.textSecondary,
                                size: 18,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
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
      if (_results.isEmpty) {
        return EmptyStateWidget(
          icon: Icons.search_off,
          title: 'No matching stops',
          subtitle:
              'We couldn\'t find a stop matching "${_searchCtrl.text.trim()}". '
              'Try a different name or check the spelling.',
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _results.length,
        separatorBuilder: (_, _) => Divider(height: 1, color: context.divider),
        itemBuilder: (_, i) => _StopTile(
          icon: Icons.location_on_outlined,
          name: _results[i].name,
          subtitle: _results[i].routeName,
          onTap: () => _selectStop(_results[i]),
        ),
      );
    }

    // Recents view
    if (_recents.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.history,
        title: 'No recent destinations',
        subtitle:
            'Search for a stop above and it will be saved here for quick access next time.',
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
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
        ..._recents.map(
          (s) => _StopTile(
            icon: Icons.access_time,
            name: s.name,
            subtitle: s.routeName,
            onTap: () => _selectStop(s),
          ),
        ),
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
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.fieldFill,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: context.textSecondary, size: 20),
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
