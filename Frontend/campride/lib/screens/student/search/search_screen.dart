import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/route_model.dart';
import '../../../services/mock_route_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/common/empty_state_widget.dart';
import '../../../widgets/common/section_header.dart';

class SearchRouteScreen extends StatefulWidget {
  const SearchRouteScreen({super.key});

  @override
  State<SearchRouteScreen> createState() => _SearchRouteScreenState();
}

class _SearchRouteScreenState extends State<SearchRouteScreen> {
  final _routeService = MockRouteService();
  final _searchController = TextEditingController();
  List<RouteModel> _routes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRoutes([String query = '']) async {
    setState(() => _loading = true);
    final data = await _routeService.searchRoutes(query);
    if (mounted) setState(() { _routes = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search routes or stops...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _loadRoutes();
                      },
                    )
                  : null,
            ),
            onChanged: (value) => _loadRoutes(value),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _routes.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.search_off_outlined,
                      title: 'No Routes Found',
                      subtitle: 'Try a different search term',
                      action: TextButton(
                        onPressed: () { _searchController.clear(); _loadRoutes(); },
                        child: const Text('Clear Search'),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        SectionHeader(title: '${_routes.length} Route${_routes.length != 1 ? "s" : ""} Found'),
                        const SizedBox(height: 12),
                        ..._routes.map((r) => _RouteCard(route: r)),
                      ],
                    ),
        ),
      ],
    );
  }
}

class _RouteCard extends StatelessWidget {
  final RouteModel route;
  const _RouteCard({required this.route});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
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
                      color: route.isActive
                          ? AppColors.primaryGreen.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.route_outlined,
                      color: route.isActive ? AppColors.primaryGreen : Colors.grey,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      route.name,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: route.isActive
                          ? AppColors.success.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      route.isActive ? 'Active' : 'Inactive',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: route.isActive ? AppColors.success : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _StopsList(stops: route.stops),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: AppColors.textSecondaryLight),
                  const SizedBox(width: 4),
                  Text(
                    '${route.startTime} - ${route.endTime}',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.refresh, size: 14, color: AppColors.textSecondaryLight),
                  const SizedBox(width: 4),
                  Text(
                    'Every ${route.frequency} min',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StopsList extends StatelessWidget {
  final List<String> stops;
  const _StopsList({required this.stops});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: stops.asMap().entries.map((e) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              e.value,
              style: GoogleFonts.poppins(fontSize: 11, color: AppColors.primaryGreen),
            ),
          ),
          if (e.key < stops.length - 1)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: Icon(Icons.chevron_right, size: 14, color: AppColors.textSecondaryLight),
            ),
        ],
      )).toList(),
    );
  }
}
