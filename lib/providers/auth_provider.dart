// filepath: Mobile/lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/secure_storage_service.dart';
import '../models/user.dart'; // Import User model

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final SecureStorageService _storageService = SecureStorageService();

  String? _token;
  User? _currentUser; // Store the current user details
  bool _isLoading = true; // Start loading initially to check token/profile
  String? _errorMessage;

  AuthProvider() {
    _tryAutoLogin();
  }

  bool get isAuthenticated => _token != null && _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser; // Getter for the current user

  // --- Ensure this method is public ---
  Future<void> refreshUserProfile() async {
    // This public method calls the private logic to refresh/re-validate the user
    await _tryAutoLogin();
  }

  // Private method for internal use (login check, refresh)
  Future<void> _tryAutoLogin() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _token = await _storageService.getToken();
    if (_token != null) {
      // Token exists, try fetching user profile
      try {
        _currentUser = await _authService.getCurrentUserProfile();
        if (_currentUser == null) {
          // Profile fetch failed (e.g., token expired), clear token
          _token = null;
          await _storageService.deleteToken();
          _errorMessage =
              "Session invalid. Please sign in again."; // Set error message
        }
      } catch (error) {
        // Handle specific errors, e.g., unauthorized
        print("Auto-login/refresh profile fetch failed: $error");
        _token = null;
        _currentUser = null;
        await _storageService.deleteToken(); // Ensure invalid token is cleared
        _errorMessage = "Session expired or invalid. Please sign in again.";
      }
    } else {
      _currentUser = null; // Ensure user is null if no token
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.signIn(email, password);
      if (result['success']) {
        _token = result['token'];
        // Fetch user profile after successful sign-in
        _currentUser = await _authService.getCurrentUserProfile();
        if (_currentUser == null) {
          // Handle case where profile fetch fails immediately after login
          _token = null;
          await _storageService.deleteToken();
          _errorMessage = "Failed to load user profile after sign in.";
          return {'success': false, 'message': _errorMessage};
        }
        return {'success': true};
      } else {
        _errorMessage = result['message'];
        return {'success': false, 'message': _errorMessage};
      }
    } catch (error) {
      _errorMessage = "Sign in failed: $error";
      return {'success': false, 'message': _errorMessage};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> signUp({
    required String username,
    required String email,
    required String password,
    required String userType,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _authService.signUp(
        username: username,
        email: email,
        password: password,
        userType: userType,
      );
      _errorMessage = result['message']; // Store message regardless of success
      return result; // Return the whole result map
    } catch (error) {
      _errorMessage = "Sign up failed: $error";
      return {'success': false, 'message': _errorMessage};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    _token = null;
    _currentUser = null; // Clear user data
    await _authService.signOut(); // Calls storageService.deleteToken()
    _isLoading = false;
    notifyListeners();
  }
}
