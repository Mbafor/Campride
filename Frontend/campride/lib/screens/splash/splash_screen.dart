import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/authentication_provider.dart';
import '../../routes/route_names.dart';
import '../../theme/theme_extensions.dart';
import '../../widgets/common/app_logo_image.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    _initialize();
  }

  Future<void> _initialize() async {
    final auth = context.read<AuthenticationProvider>();

    // Run the minimum splash duration and the token check in parallel so
    // a fast/slow auth check doesn't shorten/lengthen the splash beyond it.
    await Future.wait([
      auth.initializeAuth(),
      Future.delayed(AppConstants.splashDuration),
    ]);
    if (!mounted) return;

    if (auth.isAuthenticated) {
      final role = auth.user?.role ?? 'student';
      context.go(RouteNames.dashboardForRole(role));
    } else {
      context.go(RouteNames.welcome);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: const AppLogoImage(height: 72),
        ),
      ),
    );
  }
}
