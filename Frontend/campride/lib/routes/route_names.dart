class RouteNames {
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String studentDashboard = '/student';
  static const String driverDashboard = '/driver';
  static const String fleetDashboard = '/fleet';
  static const String adminDashboard = '/admin';

  static String dashboardForRole(String role) {
    switch (role) {
      case 'student':
        return studentDashboard;
      case 'driver':
        return driverDashboard;
      case 'fleet_manager':
        return fleetDashboard;
      case 'super_admin':
        return adminDashboard;
      default:
        return studentDashboard;
    }
  }
}
