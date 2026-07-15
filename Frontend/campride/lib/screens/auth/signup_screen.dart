import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as google_sign_in_web;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/authentication_provider.dart';
import '../../providers/user_role_provider.dart';
import '../../routes/route_names.dart';
import '../../theme/app_colors.dart';
import 'otp_screen.dart';

class SignupScreen extends StatefulWidget {
  final String role;
  const SignupScreen({super.key, required this.role});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _googleLoading = false;
  String? _emailError;
  String? _passwordError;

  bool get _isStudent => widget.role == 'student';

  @override
  void initState() {
    super.initState();
    // Initialize GoogleSignIn and set up authentication event listener on web
    if (kIsWeb) {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['openid', 'email', 'profile'],
      );

      // Initialize the plugin so renderButton() can be called safely
      googleSignIn.signInSilently().then((_) {
        developer.log('GoogleSignIn initialized on web', name: 'GoogleSignIn');
      }).catchError((e) {
        developer.log('GoogleSignIn init note: $e', name: 'GoogleSignIn');
      });

      // Listen for GIS authentication events (credential responses)
      GoogleSignIn.instance.authenticationEvents.listen(
        (AuthenticationEvent event) async {
          // User completed authentication - we have the credential (idToken)
          developer.log(
            'GIS authentication completed, idToken: ${event.idToken}',
            name: 'GoogleSignIn',
          );

          // Send the idToken to our backend
          await _handleGISCredential(event.idToken);
        },
        onError: (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Google Sign-In error: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    }
  }

  Future<void> _handleGISCredential(String idToken) async {
    try {
      // Show loading indicator
      setState(() => _googleLoading = true);

      final auth = context.read<AuthenticationProvider>();
      final role = context.read<UserRoleProvider>();
      role.setRole(widget.role);

      // Send idToken to backend
      final ok = await auth.googleSignIn(idToken: idToken);

      if (mounted) {
        setState(() => _googleLoading = false);

        if (ok) {
          // Successful authentication - navigate to dashboard
          context.go(
              _isStudent ? RouteNames.studentDashboard : RouteNames.driverDashboard);
        } else {
          // Backend rejected the token
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
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    String? emailErr;
    String? passErr;

    final validEmail =
        RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(email);
    if (!validEmail) emailErr = 'Enter a valid email address';

    if (password.length < 8) {
      passErr = 'Password must be at least 8 characters';
    } else if (password != confirm) {
      passErr = 'Passwords do not match';
    }

    setState(() {
      _emailError = emailErr;
      _passwordError = passErr;
    });

    if (emailErr != null || passErr != null) return;

    // Call the real register endpoint
    final auth = context.read<AuthenticationProvider>();
    final ok = await auth.register(
      name: name,
      email: email,
      password: password,
    );

    if (mounted) {
      if (ok) {
        // Navigate to verification code screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OtpScreen(email: email)),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? 'Registration failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (kIsWeb) {
      // Web: renderButton() is rendered in UI and handles click + auth flow
      // Authentication happens via Google's GIS library
      // User will see the official Google button and click it directly
      developer.log(
        'GIS renderButton() shown on web - user interaction handled by Google',
        name: 'GoogleSignIn',
      );
    } else {
      // Mobile: Use traditional signIn() flow
      await _handleMobileGoogleSignIn();
    }
  }

  Future<void> _handleMobileGoogleSignIn() async {
    setState(() => _googleLoading = true);

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['openid', 'email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

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

      developer.log(
        'Google Auth - idToken: ${googleAuth.idToken}, accessToken: ${googleAuth.accessToken}',
        name: 'GoogleSignIn',
      );

      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        if (mounted) {
          setState(() => _googleLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Failed to get Google ID token - accessToken: ${googleAuth.accessToken != null}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final auth = context.read<AuthenticationProvider>();
      final role = context.read<UserRoleProvider>();
      role.setRole(widget.role);

      final ok = await auth.googleSignIn(idToken: idToken);

      if (mounted) {
        setState(() => _googleLoading = false);
        if (ok) {
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
                  onTap: () => Navigator.pop(context),
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
                  'Create account',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 28),

                // Full name
                _GreyField(
                  controller: _nameCtrl,
                  hint: 'Full name',
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: 12),

                // Email
                _GreyField(
                  controller: _emailCtrl,
                  hint: 'Email address',
                  keyboardType: TextInputType.emailAddress,
                  errorText: _emailError,
                ),
                const SizedBox(height: 12),

                // Password
                _GreyField(
                  controller: _passwordCtrl,
                  hint: 'Password',
                  obscureText: _obscurePassword,
                  errorText: _passwordError,
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
                const SizedBox(height: 12),

                // Confirm password
                _GreyField(
                  controller: _confirmCtrl,
                  hint: 'Confirm password',
                  obscureText: _obscureConfirm,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey[500],
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                const SizedBox(height: 28),

                // Create account button
                _PrimaryButton(
                    label: 'Create account', onPressed: _handleCreate),
                const SizedBox(height: 24),

                // OR divider
                _OrDivider(),
                const SizedBox(height: 24),

                // Continue with Google
                _GoogleButton(
                  isLoading: _googleLoading,
                  onPressed: _googleLoading ? null : _handleGoogleSignIn,
                ),
                const SizedBox(height: 32),

                // Sign in link
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: Colors.grey[600]),
                        children: [
                          const TextSpan(text: 'Already have an account? '),
                          TextSpan(
                            text: 'Sign in',
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

// ─── Shared widgets (local copies) ───────────────────────────────────────────

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
              hintStyle:
                  GoogleFonts.poppins(fontSize: 15, color: Colors.grey[500]),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              style:
                  GoogleFonts.poppins(fontSize: 12, color: Colors.red[600]),
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
  const _PrimaryButton({required this.label, this.onPressed});

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
        child: Text(
          label,
          style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
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
        Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
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
        Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  const _GoogleButton({required this.isLoading, this.onPressed});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Web: Render Google's official GIS button with customization
      // Button handles authentication internally via authenticationEvents stream
      return SizedBox(
        width: double.infinity,
        child: google_sign_in_web.renderButton(
          configuration: google_sign_in_web.GSIButtonConfiguration(
            theme: 'outline',              // Outline theme matches app design
            size: 'large',                 // Large button for prominence
            shape: 'rectangular',          // Rectangular to match other buttons
            text: 'continue_with',         // "Continue with Google" text
            type: 'standard',              // Full button (not icon-only)
            logoAlignment: 'left',         // Google logo on left side
            minimumWidth: 280,             // Minimum width for consistency
          ),
        ),
      );
    } else {
      // Mobile: Use custom button with traditional flow
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey[300]!, width: 1.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
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
        width: 22,
        height: 22,
        child: CustomPaint(painter: _GIconPainter()));
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
      Rect.fromLTWH(
          c.dx, c.dy - size.height * 0.1, r * 0.95, size.height * 0.2),
      Paint()..color = AppColors.googleBlue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
