import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/authentication_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_role_provider.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';

// Global reference to Google Sign-In button container (used on web)
late html.DivElement _googleSignInButtonContainer;

void main() {
  // Register platform view factory for Google Sign-In button (web only)
  if (kIsWeb) {
    _registerGoogleSignInButtonFactory();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthenticationProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserRoleProvider()),
      ],
      child: const CamprideApp(),
    ),
  );
}

void _registerGoogleSignInButtonFactory() {
  // Create the container element once at app startup
  _googleSignInButtonContainer = html.DivElement()..id = 'google_signin_button';

  // Register with Flutter's platform view system
  // This connects HtmlElementView(viewType: 'google_signin_button') to this element
  ui.platformViewRegistry.registerViewFactory(
    'google_signin_button',
    (int viewId) => _googleSignInButtonContainer,
  );

  print('[DEBUG-MAIN] Platform view factory registered: google_signin_button');
}

class CamprideApp extends StatefulWidget {
  const CamprideApp({super.key});

  @override
  State<CamprideApp> createState() => _CamprideAppState();
}

class _CamprideAppState extends State<CamprideApp> {
  late final _router = createRouter(context);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp.router(
          title: 'KNUST Shuttle Finder',
          debugShowCheckedModeBanner: false,
          theme: lightTheme(),
          darkTheme: darkTheme(),
          themeMode: themeProvider.themeMode,
          routerConfig: _router,
        );
      },
    );
  }
}
