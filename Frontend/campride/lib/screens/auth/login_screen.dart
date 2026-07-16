import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
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
import 'otp_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _googleLoading = false;
  String? _emailError;

  String _getDashboardRoute(String userRole) {
    switch (userRole) {
      case 'student':
        return RouteNames.studentDashboard;
      case 'driver':
        return RouteNames.driverDashboard;
      case 'fleet_manager':
        return RouteNames.fleetDashboard;
      case 'super_admin':
        return RouteNames.adminDashboard;
      default:
        return RouteNames.studentDashboard;
    }
  }

  @override
  void initState() {
    super.initState();
    // Listen to Google Sign-In stream (works on both web and mobile)
    GoogleSignIn().onCurrentUserChanged.listen((account) {
      if (account != null && mounted) {
        print('[DEBUG] User signed in: ${account.email}');
        developer.log('[DEBUG] User signed in: ${account.email}', name: 'GoogleSignIn');
        _handleGoogleSignInSuccess(account);
      }
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    String? emailErr;

    final validEmail = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(email);
    if (!validEmail) emailErr = 'Enter a valid email address';

    setState(() => _emailError = emailErr);
    if (emailErr != null) return;

    setState(() => _isLoading = true);

    final auth = context.read<AuthenticationProvider>();
    final role = context.read<UserRoleProvider>();
    role.setRole(widget.role);

    final ok = await auth.login(email: email, password: password);

    if (mounted) {
      setState(() => _isLoading = false);
      if (ok) {
        final userRole = auth.user?.role ?? 'student';
        final dashboardRoute = _getDashboardRoute(userRole);
        context.go(dashboardRoute);
      } else if (auth.errorCode == 'AUTH_007') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OtpScreen(email: email)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'Login failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignInSuccess(GoogleSignInAccount account) async {
    setState(() => _googleLoading = true);

    try {
      final googleAuth = await account.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Failed to get ID token from Google');
      }

      print('[DEBUG] ID token received (first 10 chars): ${idToken.substring(0, 10)}');
      print('[DEBUG] Token type: ${idToken.substring(0, 4)}');
      developer.log('[DEBUG] ID token starts with: ${idToken.substring(0, 4)}', name: 'GoogleSignIn');

      final auth = context.read<AuthenticationProvider>();
      final role = context.read<UserRoleProvider>();
      role.setRole(widget.role);

      final ok = await auth.googleSignIn(idToken: idToken);

      if (mounted) {
        setState(() => _googleLoading = false);
        if (ok) {
          final userRole = auth.user?.role ?? 'student';
          final dashboardRoute = _getDashboardRoute(userRole);
          print('[DEBUG] Navigation to $dashboardRoute');
          context.go(dashboardRoute);
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
        setState(() => _googleLoading = false);
        print('[DEBUG] Error in Google sign-in: $e');
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => context.go(RouteNames.welcome),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back,
                        size: 20, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 36),
                Text(
                  'Sign in to Campride',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 28),
                _GreyField(
                  controller: _emailCtrl,
                  hint: 'Email address',
                  keyboardType: TextInputType.emailAddress,
                  errorText: _emailError,
                ),
                const SizedBox(height: 12),
                _GreyField(
                  controller: _passwordCtrl,
                  hint: 'Password',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey[500],
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 28),
                _PrimaryButton(
                  label: 'Continue',
                  onPressed: _isLoading ? null : _handleContinue,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),
                _OrDivider(),
                const SizedBox(height: 24),
                _GoogleButton(
                  isLoading: _googleLoading,
                ),
                const SizedBox(height: 36),
                Center(child: _TermsText()),
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => SignupScreen(role: widget.role)),
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: Colors.grey[600]),
                        children: [
                          const TextSpan(text: "Don't have an account? "),
                          TextSpan(
                            text: 'Sign up',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreenLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GreyField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? errorText;

  const _GreyField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!, width: 1.5),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                  fontSize: 15, color: Colors.grey[500]),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
              suffixIcon: suffixIcon,
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              errorText!,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.red[600]),
            ),
          ),
        ],
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  const _PrimaryButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreenDark,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Divider(color: Colors.grey[300], thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'OR',
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[500]),
          ),
        ),
        Expanded(
            child: Divider(color: Colors.grey[300], thickness: 1)),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final bool isLoading;
  const _GoogleButton({required this.isLoading});

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
          onPressed: isLoading
              ? null
              : () async {
                  GoogleSignIn().signIn();
                },
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey[300]!, width: 1.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(27)),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _GoogleIcon(),
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

class _TermsText extends StatefulWidget {
  const _TermsText();

  @override
  State<_TermsText> createState() => _TermsTextState();
}

class _TermsTextState extends State<_TermsText> {
  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()..onTap = () {};
    _privacyTap = TapGestureRecognizer()..onTap = () {};
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]);
    final link = GoogleFonts.poppins(
      fontSize: 12,
      color: AppColors.primaryGreenLight,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.primaryGreenLight,
    );

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: base,
        children: [
          const TextSpan(text: 'By continuing, you agree to our '),
          TextSpan(
              text: 'Terms & Conditions',
              style: link,
              recognizer: _termsTap),
          const TextSpan(text: ' and '),
          TextSpan(
              text: 'Privacy Policy', style: link, recognizer: _privacyTap),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }
}
