import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RidesScreen extends StatelessWidget {
  const RidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Text(
                'Your Rides',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: const [
                  _RideCard(
                    from: 'Brunei Bus Stop',
                    to: 'Unity Hall',
                    date: 'Today, 10:30 AM',
                    fare: 'GH₵ 2.00',
                  ),
                  _RideCard(
                    from: 'KSB',
                    to: 'Paa Joe Stadium',
                    date: 'Yesterday, 2:15 PM',
                    fare: 'GH₵ 2.00',
                  ),
                  _RideCard(
                    from: 'Unity Hall',
                    to: 'Kotei',
                    date: 'Mon, Jun 20, 9:00 AM',
                    fare: 'GH₵ 3.00',
                  ),
                  _RideCard(
                    from: 'Emena Community',
                    to: 'KNUST Main Gate',
                    date: 'Sat, Jun 18, 7:45 AM',
                    fare: 'GH₵ 2.50',
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

class _RideCard extends StatelessWidget {
  final String from;
  final String to;
  final String date;
  final String fare;

  const _RideCard({
    required this.from,
    required this.to,
    required this.date,
    required this.fare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.directions_bus_outlined, size: 22, color: Colors.grey[700]),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$from → $to',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            fare,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
