import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart';
import 'package:provider/provider.dart';
import '../../providers/authentication_provider.dart';
import '../../providers/user_role_provider.dart';
import '../../routes/route_names.dart';
import '../../theme/app_colors.dart';

/// Reusable Google Sign-In entry point shared by the Welcome and Login
/// screens, so the (finicky, previously buggy) web button rendering and
/// sign-in handling only lives in one place.
class GoogleSignInButton extends StatefulWidget {
  final String role;

  const GoogleSignInButton({super.key, required this.role});

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    GoogleSignIn().onCurrentUserChanged.listen((account) {
      if (account != null && mounted) {
        developer.log('[DEBUG] User signed in: ${account.email}', name: 'GoogleSignIn');
        _handleGoogleSignInSuccess(account);
      }
    });
  }

  Future<void> _handleGoogleSignInSuccess(GoogleSignInAccount account) async {
    setState(() => _isLoading = true);

    try {
      final googleAuth = await account.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Failed to get ID token from Google');
      }

      developer.log('[DEBUG] ID token starts with: ${idToken.substring(0, 4)}', name: 'GoogleSignIn');

      final auth = context.read<AuthenticationProvider>();
      final role = context.read<UserRoleProvider>();
      role.setRole(widget.role);

      final ok = await auth.googleSignIn(idToken: idToken);

      if (mounted) {
        setState(() => _isLoading = false);
        if (ok) {
          final userRole = auth.user?.role ?? 'student';
          context.go(RouteNames.dashboardForRole(userRole));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(auth.errorMessage ?? 'Google sign-in failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: renderButton(
          configuration: GSIButtonConfiguration(
            theme: GSIButtonTheme.outline,
            size: GSIButtonSize.large,
            shape: GSIButtonShape.pill,
            text: GSIButtonText.continueWith,
            type: GSIButtonType.standard,
          ),
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: OutlinedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  GoogleSignIn().signIn();
                },
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey[300]!, width: 1.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(27)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _GoogleIcon(),
                    const SizedBox(width: 12),
                    Text(
                      'Continue with Google',
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87),
                    ),
                  ],
                ),
        ),
      );
    }
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 22, height: 22, child: CustomPaint(painter: _GIconPainter()));
  }
}

class _GIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final sw = size.width * 0.18;

    void arc(double start, double sweep, Color color) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        start, sweep, false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw,
      );
    }

    arc(-0.5, 3.8, AppColors.googleBlue);
    arc(3.3, 1.6, AppColors.googleRed);
    arc(2.0, 1.3, AppColors.googleYellow);
    canvas.drawRect(
      Rect.fromLTWH(c.dx, c.dy - size.height * 0.1, r * 0.95, size.height * 0.2),
      Paint()..color = AppColors.googleBlue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
