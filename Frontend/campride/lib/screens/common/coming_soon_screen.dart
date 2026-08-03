import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/common/empty_state_widget.dart';

/// Generic placeholder for drawer destinations that don't have a real
/// feature built yet. Honest about status instead of a dead-end or crash.
class ComingSoonScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String message;

  const ComingSoonScreen({
    super.key,
    required this.title,
    required this.icon,
    this.message = 'This feature is coming soon.',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      body: EmptyStateWidget(
        icon: icon,
        title: '$title coming soon',
        subtitle: message,
      ),
    );
  }
}
