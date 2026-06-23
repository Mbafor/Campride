import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/authentication_provider.dart';
import '../../providers/user_role_provider.dart';
import '../../routes/route_names.dart';
import '../../theme/app_colors.dart';
import '../../widgets/buttons/custom_button.dart';
import '../../widgets/common/error_banner.dart';
import '../../widgets/inputs/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _googleLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  bool get isStudent => widget.role == AppConstants.studentRole;

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  void _navigateToDashboard() {
    context.go(isStudent ? RouteNames.studentDashboard : RouteNames.driverDashboard);
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _googleLoading = true);
    final authProvider = context.read<AuthenticationProvider>();
    final roleProvider = context.read<UserRoleProvider>();
    roleProvider.setRole(widget.role);
    final success = await authProvider.signInWithGoogle(widget.role);
    if (mounted) {
      setState(() => _googleLoading = false);
      if (success) _navigateToDashboard();
    }
  }

  Future<void> _handleEmailSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = context.read<AuthenticationProvider>();
    final roleProvider = context.read<UserRoleProvider>();
    roleProvider.setRole(widget.role);
    final success = await authProvider.signInWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
      widget.role,
    );
    if (mounted && success) _navigateToDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: Theme.of(context).colorScheme.onSurface,
          onPressed: () => context.go(RouteNames.welcome),
        ),
      ),
      body: Consumer<AuthenticationProvider>(
        builder: (context, auth, _) {
          return LoadingOverlaySimple(
            isLoading: auth.state == AuthState.loading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        isStudent ? 'Student Login' : 'Driver Login',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Welcome back to KNUST Shuttle Finder',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (auth.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ErrorBanner(
                            message: auth.errorMessage!,
                            onDismiss: auth.clearError,
                          ),
                        ),
                      // Google Sign-In
                      _GoogleSignInButton(
                        isLoading: _googleLoading,
                        onTap: auth.state == AuthState.loading ? null : _handleGoogleSignIn,
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          AppConstants.signInWithGoogle,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _OrDivider(),
                      const SizedBox(height: 24),
                      CustomTextField(
                        label: 'Email Address',
                        hint: 'you@knust.edu.gh',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined),
                        validator: _validateEmail,
                        enabled: auth.state != AuthState.loading,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Password',
                        hint: 'Min. 8 characters',
                        controller: _passwordController,
                        isPassword: true,
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        validator: _validatePassword,
                        enabled: auth.state != AuthState.loading,
                      ),
                      const SizedBox(height: 32),
                      CustomButton(
                        label: 'Sign In',
                        isLoading: auth.state == AuthState.loading && !_googleLoading,
                        onPressed: auth.state == AuthState.loading ? null : _handleEmailSignIn,
                        icon: const Icon(Icons.login_rounded),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onTap;

  const _GoogleSignInButton({required this.isLoading, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.dividerLight, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isLoading
            ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
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
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(painter: _GoogleIconPainter()),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Blue arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.5,
      3.8,
      false,
      Paint()..color = AppColors.googleBlue..style = PaintingStyle.stroke..strokeWidth = size.width * 0.18,
    );
    // Red arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.3,
      1.6,
      false,
      Paint()..color = AppColors.googleRed..style = PaintingStyle.stroke..strokeWidth = size.width * 0.18,
    );
    // Yellow arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.0,
      1.3,
      false,
      Paint()..color = AppColors.googleYellow..style = PaintingStyle.stroke..strokeWidth = size.width * 0.18,
    );
    // Horizontal line for the G
    canvas.drawRect(
      Rect.fromLTWH(center.dx, center.dy - size.height * 0.1, radius * 0.95, size.height * 0.2),
      Paint()..color = AppColors.googleBlue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Theme.of(context).dividerColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
        Expanded(child: Divider(color: Theme.of(context).dividerColor)),
      ],
    );
  }
}

class LoadingOverlaySimple extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlaySimple({super.key, required this.isLoading, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          const Positioned.fill(
            child: IgnorePointer(
              child: SizedBox.shrink(),
            ),
          ),
      ],
    );
  }
}
