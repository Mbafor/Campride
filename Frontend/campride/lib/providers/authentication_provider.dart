import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../services/auth_api_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthenticationProvider extends ChangeNotifier {
  final AuthApiService _apiService = AuthApiService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  AuthState _state = AuthState.initial;
  UserModel? _user;
  String? _errorMessage;
  String? _errorCode;
  String? _accessToken;
  String? _refreshToken;

  AuthState get state => _state;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  String? get errorCode => _errorCode;
  bool get isAuthenticated => _state == AuthState.authenticated;
  String? get accessToken => _accessToken;

  // Register new user with email/password
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    _errorCode = null;
    notifyListeners();

    try {
      final response = await _apiService.register(
        name: name,
        email: email,
        password: password,
      );

      if (response.success) {
        _state = AuthState.unauthenticated;
        notifyListeners();
        return true;
      } else {
        _state = AuthState.error;
        _errorMessage = response.message ?? 'Registration failed';
        _errorCode = response.errorCode;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'Registration error: $e';
      notifyListeners();
      return false;
    }
  }

  // Verify email with code
  Future<bool> verifyEmail({
    required String email,
    required String code,
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    _errorCode = null;
    notifyListeners();

    try {
      final response = await _apiService.verifyEmail(email: email, code: code);

      if (response.success) {
        _state = AuthState.unauthenticated;
        notifyListeners();
        return true;
      } else {
        _state = AuthState.error;
        _errorMessage = response.message ?? 'Verification failed';
        _errorCode = response.errorCode;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'Verification error: $e';
      notifyListeners();
      return false;
    }
  }

  // Resend verification email
  Future<bool> resendVerification({required String email}) async {
    _state = AuthState.loading;
    _errorMessage = null;
    _errorCode = null;
    notifyListeners();

    try {
      final response = await _apiService.resendVerification(email: email);

      if (response.success) {
        _state = AuthState.unauthenticated;
        notifyListeners();
        return true;
      } else {
        _state = AuthState.error;
        _errorMessage = response.message ?? 'Resend failed';
        _errorCode = response.errorCode;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'Resend error: $e';
      notifyListeners();
      return false;
    }
  }

  // Login with email/password
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    _errorCode = null;
    notifyListeners();

    try {
      final response = await _apiService.login(email: email, password: password);

      if (response.success && response.data != null) {
        _accessToken = response.data!['access_token'];
        _refreshToken = response.data!['refresh_token'];

        // Store tokens securely
        await _secureStorage.write(key: 'access_token', value: _accessToken);
        await _secureStorage.write(key: 'refresh_token', value: _refreshToken);

        // Fetch user info
        final userResponse = await _apiService.getCurrentUser(accessToken: _accessToken!);
        if (userResponse.success && userResponse.data != null) {
          _user = userResponse.data;
          _state = AuthState.authenticated;
        } else {
          _state = AuthState.error;
          _errorMessage = 'Failed to load user info';
        }
        notifyListeners();
        return userResponse.success;
      } else {
        _state = AuthState.error;
        _errorMessage = response.message ?? 'Login failed';
        _errorCode = response.errorCode;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'Login error: $e';
      notifyListeners();
      return false;
    }
  }

  // Google Sign-In
  Future<bool> googleSignIn({required String idToken}) async {
    _state = AuthState.loading;
    _errorMessage = null;
    _errorCode = null;
    notifyListeners();

    try {
      final response = await _apiService.googleSignIn(idToken: idToken);

      if (response.success && response.data != null) {
        _accessToken = response.data!['access_token'];
        _refreshToken = response.data!['refresh_token'];

        // Store tokens securely
        await _secureStorage.write(key: 'access_token', value: _accessToken);
        await _secureStorage.write(key: 'refresh_token', value: _refreshToken);

        // Fetch user info
        final userResponse = await _apiService.getCurrentUser(accessToken: _accessToken!);
        if (userResponse.success && userResponse.data != null) {
          _user = userResponse.data;
          _state = AuthState.authenticated;
        } else {
          _state = AuthState.error;
          _errorMessage = 'Failed to load user info';
        }
        notifyListeners();
        return userResponse.success;
      } else {
        _state = AuthState.error;
        _errorMessage = response.message ?? 'Google sign-in failed';
        _errorCode = response.errorCode;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'Google sign-in error: $e';
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      // Clear secure storage
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');

      _user = null;
      _accessToken = null;
      _refreshToken = null;
      _state = AuthState.unauthenticated;
      _errorMessage = null;
      _errorCode = null;
      notifyListeners();
    } catch (e) {
      _state = AuthState.error;
      _errorMessage = 'Sign out error: $e';
      notifyListeners();
    }
  }

  // Initialize auth state on app start (restore tokens if they exist)
  Future<void> initializeAuth() async {
    try {
      final token = await _secureStorage.read(key: 'access_token');
      if (token != null) {
        _accessToken = token;
        _refreshToken = await _secureStorage.read(key: 'refresh_token');

        // Verify token is still valid
        final userResponse = await _apiService.getCurrentUser(accessToken: token);
        if (userResponse.success && userResponse.data != null) {
          _user = userResponse.data;
          _state = AuthState.authenticated;
        } else {
          // Token expired or invalid
          await signOut();
        }
      } else {
        _state = AuthState.unauthenticated;
      }
    } catch (e) {
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _errorCode = null;
    if (_state == AuthState.error) _state = AuthState.unauthenticated;
    notifyListeners();
  }
}
