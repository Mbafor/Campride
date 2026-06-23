import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/authentication_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_role_provider.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';

void main() {
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
