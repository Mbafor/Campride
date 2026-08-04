import 'package:flutter/material.dart';
import '../../theme/theme_extensions.dart';

/// The CampRide logo artwork, switching automatically between the
/// light-background and dark-background versions based on the app's
/// active theme (not the device's — the app's own light/dark mode).
class AppLogoImage extends StatelessWidget {
  final double? height;
  const AppLogoImage({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      context.isDark
          ? 'assets/images/app_logo_dark.png'
          : 'assets/images/app_logo_light.png',
      height: height,
      fit: BoxFit.contain,
    );
  }
}
