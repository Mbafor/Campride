import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../routes/route_names.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth/google_signin_button.dart';
import '../../widgets/common/app_logo.dart';

const _kOnboardingImages = [
  'assets/images/welcome.png',
  'assets/images/welcome.png',
  'assets/images/welcome.png',
];

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'CAMPRIDE',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryGreenLight,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                const AppLogo(size: 30, color: AppColors.primaryGreenLight),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _kOnboardingImages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Image.asset(
                    _kOnboardingImages[i],
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _kOnboardingImages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _page == i
                        ? AppColors.primaryGreenLight
                        : context.divider,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
              child: Column(
                children: [
                  const GoogleSignInButton(role: 'student'),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      onPressed: () => context.go(RouteNames.login),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: context.fieldBorder, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mail_outline,
                              size: 20, color: context.textSecondary),
                          const SizedBox(width: 12),
                          Text(
                            'Continue with Email',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: context.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Joining our app means you agree with our terms of use and Privacy Policy',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: context.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
