import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';
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

  void _navigateToLogin(String role) {
    context.go('${RouteNames.login}?role=$role');
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
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          AppConstants.appTagline,
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreenDark,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppConstants.appSubtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: AppColors.textSecondaryLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 36),
                        CustomButton(
                          label: 'I am a Student',
                          icon: const Icon(Icons.school_outlined),
                          onPressed: () => _navigateToLogin(AppConstants.studentRole),
                        ),
                        const SizedBox(height: 16),
                        CustomButton(
                          label: 'I am a Driver',
                          variant: ButtonVariant.outline,
                          icon: const Icon(Icons.directions_bus_outlined),
                          onPressed: () => _navigateToLogin(AppConstants.driverRole),
                        ),
                        const Spacer(),
                        Text(
                          AppConstants.poweredBy,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
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

class _HeroIllustration extends StatelessWidget {
  final Size size;
  const _HeroIllustration({required this.size});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background circles
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
        // Road
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
        // Logo + campus icon
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
        // Decorative dots
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
