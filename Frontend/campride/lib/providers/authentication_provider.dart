import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/mock_auth_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthenticationProvider extends ChangeNotifier {
  final MockAuthService _authService = MockAuthService();

  AuthState _state = AuthState.initial;
  UserModel? _user;
  String? _errorMessage;

  AuthState get state => _state;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthState.authenticated;

  Future<bool> signInWithGoogle(String role) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.signInWithGoogle(role);
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'Google sign-in failed. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithEmail(String email, String password, String role) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.signInWithEmail(email, password, role);
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'Sign-in failed. Please check your credentials.';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_state == AuthState.error) _state = AuthState.unauthenticated;
    notifyListeners();
  }
}
