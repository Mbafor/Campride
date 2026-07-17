import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../providers/authentication_provider.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/welcome/welcome_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/student/dashboard/student_dashboard.dart';
import '../screens/driver/dashboard/driver_dashboard.dart';
import '../screens/fleet/dashboard/fleet_dashboard.dart';
import '../screens/admin/dashboard/admin_dashboard_screen.dart';
import 'route_names.dart';

GoRouter createRouter(BuildContext context) {
  final authProvider = Provider.of<AuthenticationProvider>(context, listen: false);

  return GoRouter(
    initialLocation: RouteNames.splash,
    redirect: (context, state) {
      final isAuthenticated = authProvider.isAuthenticated;
      final isOnSplash = state.matchedLocation == RouteNames.splash;
      final isOnWelcome = state.matchedLocation == RouteNames.welcome;
      final isOnLogin = state.matchedLocation == RouteNames.login;

      if (!isAuthenticated && !isOnSplash && !isOnWelcome && !isOnLogin) {
        return RouteNames.welcome;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        pageBuilder: (context, state) => _fadePage(state, const SplashScreen()),
      ),
      GoRoute(
        path: RouteNames.welcome,
        pageBuilder: (context, state) => _slidePage(state, const WelcomeScreen()),
      ),
      GoRoute(
        path: RouteNames.login,
        pageBuilder: (context, state) {
          final role = state.uri.queryParameters['role'] ?? AppConstants.studentRole;
          return _slidePage(state, LoginScreen(role: role));
        },
      ),
      GoRoute(
        path: RouteNames.studentDashboard,
        pageBuilder: (context, state) => _fadePage(state, const StudentDashboard()),
      ),
      GoRoute(
        path: RouteNames.driverDashboard,
        pageBuilder: (context, state) => _fadePage(state, const DriverDashboard()),
      ),
      GoRoute(
        path: RouteNames.fleetDashboard,
        pageBuilder: (context, state) => _fadePage(state, const FleetDashboard()),
      ),
      GoRoute(
        path: RouteNames.adminDashboard,
        pageBuilder: (context, state) => _fadePage(state, const AdminDashboardScreen()),
      ),
    ],
  );
}

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppConstants.pageTransitionDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

CustomTransitionPage<void> _slidePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppConstants.pageTransitionDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
        child: child,
      );
    },
  );
}
