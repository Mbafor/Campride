import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_colors.dart';
import '../route/route_screen.dart';

class LiveMapScreen extends StatelessWidget {
  const LiveMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: _MapCanvas()),
        Positioned(
          right: 16,
          bottom: 220,
          child: _NavArrowButton(),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _BottomCard(),
        ),
      ],
    );
  }
}

// ─── Bottom card (always visible, no "Recents" label) ────────────────────────

class _BottomCard extends StatelessWidget {
  const _BottomCard();

  void _openRouteScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RouteScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 16, offset: Offset(0, -3)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // "Where to?" pill — opens draggable route sheet
          GestureDetector(
            onTap: () => _openRouteScreen(context),
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 18),
                  Icon(Icons.search, color: Colors.grey[600], size: 22),
                  const SizedBox(width: 12),
                  Text(
                    'Where to ?',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Recent items — no label, just the rows
          const _RecentItem(label: 'Brunei Bus Stop'),
          const SizedBox(height: 12),
          const _RecentItem(label: 'Kotei Bus Stop'),
        ],
      ),
    );
  }
}

class _RecentItem extends StatelessWidget {
  final String label;
  const _RecentItem({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.access_time, color: Colors.grey[600], size: 20),
        ),
        const SizedBox(width: 14),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87),
        ),
      ],
    );
  }
}

// ─── Map canvas (unchanged) ───────────────────────────────────────────────────

class _MapCanvas extends StatelessWidget {
  const _MapCanvas();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.mapBackground,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: CustomPaint(painter: _RoadPainter())),
          Positioned(
            left: 0,
            top: 0,
            width: 200,
            height: 300,
            child: Container(color: AppColors.mapPark.withValues(alpha: 0.5)),
          ),
          Positioned(
            left: 18,
            top: 110,
            child: Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: AppColors.mapPark,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green[300]!, width: 1),
              ),
              child: Center(
                child: Icon(Icons.sports, size: 20, color: Colors.green[800]),
              ),
            ),
          ),
          Positioned(
            left: 18,
            top: 150,
            child: Text(
              'KWAME\nNKRUMAH\nUNIVERSITY OF\nSCIENCE AND\nTECHNOLOGY',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ),
          Positioned(
            left: 30,
            top: 30,
            child: _MapMarker(color: Colors.blue[700]!, label: 'Unity Hall'),
          ),
          Positioned(
            right: 70,
            top: 55,
            child: _RoundMarker(color: Colors.orange, icon: Icons.restaurant),
          ),
          Positioned(
            right: 30,
            top: 95,
            child: _RoundMarker(
                color: Colors.blue, icon: Icons.local_grocery_store),
          ),
          Positioned(
            right: 55,
            top: 160,
            child: _RoundMarker(color: Colors.orange, icon: Icons.restaurant),
          ),
          Positioned(
            right: 85,
            top: 25,
            child: Text(
              'Mango Rd',
              style: GoogleFonts.poppins(fontSize: 9, color: Colors.black45),
            ),
          ),
          Positioned(
            left: 130,
            top: 78,
            child: RotationTransition(
              turns: const AlwaysStoppedAnimation(-0.05),
              child: Text(
                'Ayeduase Rd',
                style:
                    GoogleFonts.poppins(fontSize: 9, color: Colors.black45),
              ),
            ),
          ),
          Positioned(
            right: 40,
            top: 240,
            child: RotationTransition(
              turns: const AlwaysStoppedAnimation(0.12),
              child: Text(
                'Kotei Rd',
                style:
                    GoogleFonts.poppins(fontSize: 9, color: Colors.black45),
              ),
            ),
          ),
          Positioned(
            left: 50,
            bottom: 130,
            child: Text(
              'Emena Community',
              style: GoogleFonts.poppins(fontSize: 9, color: Colors.black45),
            ),
          ),
          Positioned(
            left: 18,
            bottom: 155,
            child:
                _RoundMarker(color: Colors.red[400]!, icon: Icons.place),
          ),
          Positioned(
            right: 10,
            top: 290,
            child: Text(
              'KOTEI',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.black45,
                letterSpacing: 1,
              ),
            ),
          ),
          Positioned(
            left: 100,
            bottom: 200,
            child: _MapMarker(
                color: Colors.green[700]!, label: 'Kotei AstroTurf'),
          ),
        ],
      ),
    );
  }
}

class _RoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final main = Paint()
      ..color = Colors.white
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final minor = Paint()
      ..color = Colors.white
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
        Offset(0, size.height * 0.32),
        Offset(size.width, size.height * 0.28),
        main);
    canvas.drawLine(
        Offset(0, size.height * 0.55),
        Offset(size.width, size.height * 0.60),
        minor);
    canvas.drawLine(
        Offset(size.width * 0.44, 0),
        Offset(size.width * 0.41, size.height),
        main);
    canvas.drawLine(
        Offset(size.width * 0.76, 0),
        Offset(size.width * 0.74, size.height),
        minor);
    canvas.drawLine(
        Offset(size.width * 0.30, 0),
        Offset(size.width * 0.50, size.height * 0.35),
        minor);
    canvas.drawLine(
        Offset(0, size.height * 0.80),
        Offset(size.width, size.height * 0.78),
        minor);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapMarker extends StatelessWidget {
  final Color color;
  final String label;
  const _MapMarker({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: const Icon(Icons.location_on, color: Colors.white, size: 12),
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 9, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

class _RoundMarker extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _RoundMarker({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: Colors.white, size: 13),
    );
  }
}

class _NavArrowButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.navigation, color: Colors.white, size: 22),
    );
  }
}
