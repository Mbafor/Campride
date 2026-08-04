import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/authentication_provider.dart';
import '../../routes/route_names.dart';
import '../../theme/app_theme.dart';

/// Shows a "Log out of CampRide?" confirmation popup. Signs the user out
/// and navigates to the welcome screen if confirmed.
Future<void> showLogoutDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (dialogContext) => _LogoutDialog(rootContext: context),
  );
}

class _LogoutDialog extends StatefulWidget {
  final BuildContext rootContext;
  const _LogoutDialog({required this.rootContext});

  @override
  State<_LogoutDialog> createState() => _LogoutDialogState();
}

class _LogoutDialogState extends State<_LogoutDialog> {
  bool _isLoading = false;

  Future<void> _confirmLogout() async {
    setState(() => _isLoading = true);
    final auth = widget.rootContext.read<AuthenticationProvider>();
    await auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pop();
    if (!widget.rootContext.mounted) return;
    widget.rootContext.go(RouteNames.welcome);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.logout, color: Colors.red[600], size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Log out of CampRide?',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        "You'll need to sign in again to use CampRide.",
        style: GoogleFonts.poppins(fontSize: 14, color: context.textSecondary),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: context.textPrimary),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _confirmLogout,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[600],
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text('Log out', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
