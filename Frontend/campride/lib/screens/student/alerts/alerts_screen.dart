import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_colors.dart';

class _AlertItem {
  final String date;
  final String location;
  const _AlertItem({required this.date, required this.location});
}

class _AlertGroup {
  final String monthYear;
  final List<_AlertItem> items;
  const _AlertGroup({required this.monthYear, required this.items});
}

const _pastGroups = [
  _AlertGroup(
    monthYear: 'May 2026',
    items: [
      _AlertItem(date: '25 May , 14:56', location: 'Brunei Complex'),
      _AlertItem(date: '22 May , 08:10', location: 'Tech Junction'),
      _AlertItem(date: '18 May , 17:30', location: 'Unity Hall'),
    ],
  ),
  _AlertGroup(
    monthYear: 'April 2026',
    items: [
      _AlertItem(date: '30 Apr , 09:45', location: 'Kotei Bus Stop'),
      _AlertItem(date: '15 Apr , 13:22', location: 'Brunei Complex'),
    ],
  ),
];

const _upcomingGroups = [
  _AlertGroup(
    monthYear: 'June 2026',
    items: [
      _AlertItem(date: '26 Jun , 07:00', location: 'Brunei Complex'),
      _AlertItem(date: '28 Jun , 12:30', location: 'Main Gate'),
    ],
  ),
];

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final groups = _tab == 0 ? _pastGroups : _upcomingGroups;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Row(
                children: [
                  Text(
                    'Alerts',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.info_outline,
                      size: 22, color: Colors.black54),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Tab switcher
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _Tab(
                    label: 'Past',
                    isActive: _tab == 0,
                    onTap: () => setState(() => _tab = 0),
                  ),
                  const SizedBox(width: 24),
                  _Tab(
                    label: 'Upcoming',
                    isActive: _tab == 1,
                    onTap: () => setState(() => _tab = 1),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey[200]),
            const SizedBox(height: 8),
            // Alert list
            Expanded(
              child: groups.isEmpty
                  ? Center(
                      child: Text(
                        'No alerts',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: groups.length,
                      itemBuilder: (_, gi) {
                        final group = groups[gi];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            Text(
                              group.monthYear,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...group.items.map((item) => _AlertTile(item: item)),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _Tab(
      {required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? AppColors.primaryGreenLight : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 2,
            width: label.length * 8.5,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primaryGreenLight : Colors.transparent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final _AlertItem item;
  const _AlertTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.directions_bus,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.date,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  item.location,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.replay, size: 22, color: Colors.black87),
        ],
      ),
    );
  }
}
