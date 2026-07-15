import 'dart:developer' as developer;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
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

  bool get _isStudent => widget.role == AppConstants.studentRole;

  @override
  void initState() {
    super.initState();
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
        // Login successful, navigate to dashboard
        context.go(_isStudent
            ? RouteNames.studentDashboard
            : RouteNames.driverDashboard);
      } else if (auth.errorCode == 'AUTH_007') {
        // Email not verified, navigate to verification screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OtpScreen(email: email)),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'Login failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _googleLoading = true);

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['openid', 'email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      // DEBUG: Credential received
      print('[DEBUG] Google credential received: ${googleUser?.email}');
      developer.log('[DEBUG] Google credential received: ${googleUser?.email}', name: 'GoogleSignIn');

      if (googleUser == null) {
        if (mounted) setState(() => _googleLoading = false);
        return;
      }

      await _processGoogleSignIn(googleUser);
    } catch (e) {
      if (mounted) {
        setState(() => _googleLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in error: $e')),
        );
      }
    }
  }

Future<void> _processGoogleSignIn(GoogleSignInAccount googleUser) async {
    try {
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Detailed token type logging
      print('[DEBUG] idToken: ${googleAuth.idToken?.substring(0, 30) ?? "null"}');
      print('[DEBUG] accessToken: ${googleAuth.accessToken?.substring(0, 30) ?? "null"}');
      developer.log(
        'Google Auth - idToken: ${googleAuth.idToken?.substring(0, 30) ?? "null"}, accessToken: ${googleAuth.accessToken?.substring(0, 30) ?? "null"}',
        name: 'GoogleSignIn',
      );

      // Prioritize idToken (JWT starting with "eyJ"), only use accessToken as last resort
      final String? token = googleAuth.idToken;

      if (token == null) {
        print('[DEBUG] WARNING: idToken is null! Cannot proceed without a real ID token.');
        print('[DEBUG] accessToken available: ${googleAuth.accessToken != null}');
        if (mounted) {
          setState(() => _googleLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google Sign-In returned access token but not ID token. This is not supported.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final auth = context.read<AuthenticationProvider>();
      final role = context.read<UserRoleProvider>();
      role.setRole(widget.role);

      // DEBUG: Before API call
      print('[DEBUG] Token type check: starts with "eyJ"? ${token.startsWith("eyJ")}');
      print('[DEBUG] Calling auth.googleSignIn() with token: ${token.substring(0, 30)}...');
      developer.log('[DEBUG] Calling auth.googleSignIn()', name: 'GoogleSignIn');

      final ok = await auth.googleSignIn(idToken: token);

      // DEBUG: After API response
      print('[DEBUG] API response received: ok=$ok, errorMessage=${auth.errorMessage}, errorCode=${auth.errorCode}');
      developer.log('[DEBUG] API response received: ok=$ok, errorCode=${auth.errorCode}', name: 'GoogleSignIn');

      if (mounted) {
        setState(() => _googleLoading = false);
        if (ok) {
          print('[DEBUG] Navigation: navigating to ${_isStudent ? 'studentDashboard' : 'driverDashboard'}');
          context.go(_isStudent
              ? RouteNames.studentDashboard
              : RouteNames.driverDashboard);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing sign-in: $e')),
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
                // Back arrow
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

                // Title
                Text(
                  'Sign in to Campride',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 28),

                // Email field
                _GreyField(
                  controller: _emailCtrl,
                  hint: 'Email address',
                  keyboardType: TextInputType.emailAddress,
                  errorText: _emailError,
                ),
                const SizedBox(height: 12),

                // Password field
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

                // Continue button
                _PrimaryButton(
                  label: 'Continue',
                  onPressed: _isLoading ? null : _handleContinue,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),

                // OR divider
                _OrDivider(),
                const SizedBox(height: 24),

                // Continue with Google
                _GoogleButton(
                  isLoading: _googleLoading,
                  onPressed: _googleLoading ? null : _handleGoogleSignIn,
                ),
                const SizedBox(height: 36),

                // Terms & conditions
                Center(child: _TermsText()),
                const SizedBox(height: 20),

                // Sign up link
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

// ─── Grey input field ─────────────────────────────────────────────────────────

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

// ─── Primary green button ─────────────────────────────────────────────────────

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

// ─── OR divider ───────────────────────────────────────────────────────────────

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

// ─── Continue with Google button ──────────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  const _GoogleButton({required this.isLoading, this.onPressed});

  @override
  Widget build(BuildContext context) {
    // Use custom button for all platforms - modern design with your branding
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
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

// ─── Google "G" icon ──────────────────────────────────────────────────────────

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

// ─── Terms & conditions text ──────────────────────────────────────────────────

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
