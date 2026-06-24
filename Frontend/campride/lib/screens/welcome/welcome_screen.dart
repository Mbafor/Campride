import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../routes/route_names.dart';
import '../../theme/app_colors.dart';
import '../../widgets/buttons/custom_button.dart';
import '../../widgets/common/app_logo.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.primaryGreenDark,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              children: [
                Expanded(
                  flex: 4,
                  child: _HeroIllustration(size: size),
                ),
                Expanded(
                  flex: 5,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final h = constraints.maxHeight;
                        return Padding(
                          padding: EdgeInsets.fromLTRB(32, h * 0.075, 32, h * 0.055),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Welcome to Campride',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryGreenDark,
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: h * 0.055),
                              const _FeatureItem(
                                icon: Icons.gps_fixed,
                                label: 'Real time tracking',
                              ),
                              SizedBox(height: h * 0.032),
                              const _FeatureItem(
                                icon: Icons.notifications_outlined,
                                label: 'Smart notifications',
                              ),
                              SizedBox(height: h * 0.032),
                              const _FeatureItem(
                                icon: Icons.access_time_outlined,
                                label: 'ETA',
                              ),
                              const Spacer(),
                              CustomButton(
                                label: 'Get Started',
                                onPressed: () => context.go(RouteNames.login),
                              ),
                              SizedBox(height: h * 0.037),
                              GestureDetector(
                                onTap: () => context.go(RouteNames.login),
                                child: Text.rich(
                                  TextSpan(
                                    text: 'Already have an account? ',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: AppColors.textSecondaryLight,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Sign in',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryGreenDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryGreenDark.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryGreenDark, size: 20),
        ),
        const SizedBox(width: 14),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryGreenDark,
          ),
        ),
      ],
    );
  }
}

class _HeroIllustration extends StatelessWidget {
  final Size size;
  const _HeroIllustration({required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: -20,
          right: -30,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryGreenLight.withOpacity(0.3),
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          left: -40,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentGold.withOpacity(0.15),
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          child: Container(
            width: size.width * 0.8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.accentGold.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppLogo(size: 100, color: AppColors.accentGold),
            const SizedBox(height: 16),
            Text(
              'KNUST',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.accentGold,
                letterSpacing: 4,
              ),
            ),
          ],
        ),
        ...List.generate(5, (i) => Positioned(
          top: 20.0 + i * 30,
          left: 20.0 + (i % 2) * 40,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentGold.withOpacity(0.4),
            ),
          ),
        )),
      ],
    );
  }
}
