import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../providers/authentication_provider.dart';
import '../../../services/shuttle_service.dart';
import '../../../theme/app_colors.dart';
import '../../fleet/map/live_map_screen.dart';
import '../staff/staff_management_screen.dart';
import '../../fleet/shuttles/shuttles_list_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthenticationProvider>(
      builder: (context, auth, _) {
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Premium header with gradient
              SliverAppBar(
                expandedHeight: 220,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primaryGreenDark, AppColors.primaryGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome, ${auth.user?.name ?? "Admin"}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'System administration and oversight',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.security, size: 16, color: Colors.white),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Super Admin',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Content
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Stats overview
                    _StatsRow(),
                    const SizedBox(height: 32),

                    // Quick Navigation
                    Text(
                      'Management',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    _NavigationCard(
                      icon: Icons.people,
                      title: 'Drivers & Staff',
                      subtitle: 'Manage drivers and fleet managers',
                      onTap: () => _navigateTo(context, 'staff'),
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 10),
                    _NavigationCard(
                      icon: Icons.airport_shuttle,
                      title: 'Shuttles',
                      subtitle: 'View and manage all shuttles',
                      onTap: () => _navigateTo(context, 'shuttles'),
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 10),
                    _NavigationCard(
                      icon: Icons.route_outlined,
                      title: 'Routes & Stops',
                      subtitle: 'Manage routes and stops',
                      onTap: () => _navigateTo(context, 'routes'),
                      color: Colors.purple,
                    ),
                    const SizedBox(height: 10),
                    _NavigationCard(
                      icon: Icons.location_on_outlined,
                      title: 'Live Map',
                      subtitle: 'Track fleet location (Phase 5)',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LiveMapScreen()),
                        );
                      },
                      isPlaceholder: true,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateTo(BuildContext context, String section) {
    if (section == 'staff') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const StaffManagementScreen()),
      );
    } else if (section == 'shuttles') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ShuttlesListScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$section coming soon')),
      );
    }
  }
}

class _StatsRow extends StatefulWidget {
  @override
  State<_StatsRow> createState() => _StatsRowState();
}

class _StatsRowState extends State<_StatsRow> {
  final _shuttleService = ShuttleService();
  int _totalStudents = 0;
  int _totalShuttles = 0;
  int _totalRoutes = 0;
  int _totalDrivers = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final auth = context.read<AuthenticationProvider>();
    if (auth.accessToken == null) {
      setState(() => _loading = false);
      return;
    }

    final driversResult = await _shuttleService.listDrivers(accessToken: auth.accessToken!);
    final shuttlesResult = await _shuttleService.listShuttles(accessToken: auth.accessToken!);
    final routesResult = await _shuttleService.listRoutes(accessToken: auth.accessToken!);

    final statsResult = await _getAdminStats(auth.accessToken!);

    if (mounted) {
      setState(() {
        _totalDrivers = driversResult.data?.length ?? 0;
        _totalShuttles = shuttlesResult.data?.length ?? 0;
        _totalRoutes = routesResult.data?.length ?? 0;
        _totalStudents = statsResult['students'] ?? 0;
        _loading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _getAdminStats(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/stats'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'students': data['users_by_role']?['student'] ?? 0,
        };
      }
      return {'students': 0};
    } catch (e) {
      return {'students': 0};
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              child: _StatCard(
                icon: Icons.school_outlined,
                label: 'Students',
                value: '$_totalStudents',
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 90,
              child: _StatCard(
                icon: Icons.people_outline,
                label: 'Drivers',
                value: '$_totalDrivers',
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 90,
              child: _StatCard(
                icon: Icons.directions_bus_outlined,
                label: 'Shuttles',
                value: '$_totalShuttles',
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 90,
              child: _StatCard(
                icon: Icons.route_outlined,
                label: 'Routes',
                value: '$_totalRoutes',
                color: AppColors.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondaryLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isPlaceholder;
  final Color color;

  const _NavigationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isPlaceholder = false,
    this.color = AppColors.primaryGreen,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isPlaceholder ? Colors.grey : color;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isPlaceholder ? Colors.grey[200] : effectiveColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isPlaceholder ? AppColors.textSecondaryLight : effectiveColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isPlaceholder ? AppColors.textSecondaryLight : effectiveColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
