import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_constants.dart';
import '../../routes/route_names.dart';
import '../../theme/app_colors.dart';
import '../../theme/text_styles.dart';

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

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    Future.delayed(AppConstants.splashDuration, () {
      if (mounted) context.go(RouteNames.welcome);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: const _CamprideLogo(),
        ),
      ),
    );
  }
}

class _CamprideLogo extends StatelessWidget {
  const _CamprideLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'CAMPRIDE',
          style: AppTextStyles.splashBrand(),
        ),
        const SizedBox(width: 6),
        Stack(
          alignment: Alignment.topRight,
          children: [
            const Icon(
              Icons.directions_bus,
              size: 36,
              color: AppColors.splashIcon,
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.splashBackground,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi,
                  size: 14,
                  color: AppColors.splashIcon,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}