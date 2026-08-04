import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../routes/route_names.dart';
import '../../theme/app_colors.dart';
import '../../widgets/auth/google_signin_button.dart';

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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              'CAMPRIDE',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryGreenLight,
                letterSpacing: 0.5,
              ),
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
                        : Colors.grey[300],
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
                        side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mail_outline,
                              size: 20, color: Colors.grey[700]),
                          const SizedBox(width: 12),
                          Text(
                            'Continue with Email',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
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
                        color: AppColors.textSecondaryLight,
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
