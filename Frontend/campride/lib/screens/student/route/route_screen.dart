import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Mock data ────────────────────────────────────────────────────────────────

class _Location {
  final String name;
  final String subtitle;
  final String distance;
  const _Location(this.name, this.subtitle, this.distance);
}

const _allLocations = [
  _Location('Brunei - Katanga', 'TEK Credit', '1.1 km'),
  _Location("Chancellor's Hall Area", 'MCF', '1.2 km'),
  _Location('Brunei Complex', 'Brunei Hall, KNUST', '1.1 km'),
  _Location('Unity Hall', 'KNUST, Kumasi', '0.8 km'),
  _Location('Tech Junction', 'KNUST, Kumasi', '0.5 km'),
  _Location('Main Gate', 'KNUST, Kumasi', '0.3 km'),
  _Location('KNUST Hospital', 'KNUST, Kumasi', '1.0 km'),
  _Location('Kotei', 'Kumasi', '2.3 km'),
  _Location('Kumasi City Mall', 'Asokwa, Kumasi', '3.5 km'),
  _Location('Kejetia Market', 'Kejetia, Kumasi', '4.2 km'),
  _Location('Adum', 'Kumasi', '4.8 km'),
];

// ─── Full-screen route page ───────────────────────────────────────────────────

class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  final _pickupCtrl = TextEditingController(text: 'KNUST');
  final _dropoffCtrl = TextEditingController();
  final _dropoffFocus = FocusNode();
  bool _dropoffFocused = false;
  List<_Location> _suggestions = _allLocations;

  @override
  void initState() {
    super.initState();
    _dropoffCtrl.addListener(_filter);
    _dropoffFocus.addListener(() {
      setState(() => _dropoffFocused = _dropoffFocus.hasFocus);
    });
  }

  void _filter() {
    final q = _dropoffCtrl.text.toLowerCase();
    setState(() {
      _suggestions = q.isEmpty
          ? _allLocations
          : _allLocations
              .where((l) =>
                  l.name.toLowerCase().contains(q) ||
                  l.subtitle.toLowerCase().contains(q))
              .toList();
    });
  }

  void _swap() {
    final tmp = _pickupCtrl.text;
    _pickupCtrl.text = _dropoffCtrl.text;
    _dropoffCtrl.text = tmp;
    _filter();
  }

  void _selectLocation(_Location loc) {
    _dropoffCtrl.text = loc.name;
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _dropoffCtrl.dispose();
    _dropoffFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: X | Route (centered) ─────────────────────────
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
                      color: Colors.black,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close,
                          size: 24, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),

            // ── Input section ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                children: [
                  // Pickup: grey rounded container, blue dot left, + right
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
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
                                child: TextField(
                                  controller: _pickupCtrl,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    hintText: 'Pickup location',
                                    hintStyle: GoogleFonts.poppins(
                                        fontSize: 15,
                                        color: Colors.grey[500]),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.add, size: 22, color: Colors.black45),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Dropoff: bordered container (grey → green on focus),
                  // search icon left, map pin right, ↑↓ outside right
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _dropoffFocused
                                  ? const Color(0xFF4CAF50)
                                  : Colors.grey[300]!,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search,
                                  color: Colors.grey[500], size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _dropoffCtrl,
                                  focusNode: _dropoffFocus,
                                  autofocus: true,
                                  style: GoogleFonts.poppins(
                                      fontSize: 15, color: Colors.black87),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    hintText: 'Dropoff location',
                                    hintStyle: GoogleFonts.poppins(
                                      fontSize: 15,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.location_on,
                                  color: Colors.grey[500], size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _swap,
                        child: const Icon(Icons.swap_vert,
                            size: 24, color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey[200]),

            // ── Suggestions ───────────────────────────────────────────
            Expanded(
              child: _suggestions.isEmpty
                  ? Center(
                      child: Text(
                        'No locations found',
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.grey[500]),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 4),
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: Colors.grey[100]),
                      itemBuilder: (_, i) => _SuggestionTile(
                        location: _suggestions[i],
                        onTap: () => _selectLocation(_suggestions[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Suggestion tile ──────────────────────────────────────────────────────────

class _SuggestionTile extends StatelessWidget {
  final _Location location;
  final VoidCallback onTap;
  const _SuggestionTile({required this.location, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(Icons.access_time, color: Colors.grey[400], size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    location.subtitle,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Text(
              location.distance,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
