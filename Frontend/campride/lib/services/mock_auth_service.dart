import '../models/user_model.dart';
import '../constants/app_constants.dart';

class MockAuthService {
  Future<UserModel> signInWithGoogle(String role) async {
    await Future.delayed(AppConstants.mockAuthDelay);
    return role == AppConstants.studentRole
        ? UserModel.mockStudent()
        : UserModel.mockDriver();
  }

  Future<UserModel> signInWithEmail(String email, String password, String role) async {
    await Future.delayed(AppConstants.mockAuthDelay);
    return role == AppConstants.studentRole
        ? UserModel.mockStudent()
        : UserModel.mockDriver();
  }

  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  bool validateEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool validatePassword(String password) {
    return password.length >= 8;
  }
}
