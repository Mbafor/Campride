import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class UserRoleProvider extends ChangeNotifier {
  String _role = AppConstants.studentRole;

  String get role => _role;
  bool get isStudent => _role == AppConstants.studentRole;
  bool get isDriver => _role == AppConstants.driverRole;

  void setRole(String role) {
    _role = role;
    notifyListeners();
  }
}
