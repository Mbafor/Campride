import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/firebase_config.dart';
import 'providers/authentication_provider.dart';
import 'providers/theme_provider.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with web config
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: FirebaseConfig.apiKey,
      authDomain: FirebaseConfig.authDomain,
      projectId: FirebaseConfig.projectId,
      storageBucket: FirebaseConfig.storageBucket,
      messagingSenderId: FirebaseConfig.messagingSenderId,
      appId: FirebaseConfig.appId,
      measurementId: FirebaseConfig.measurementId,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthenticationProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
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
