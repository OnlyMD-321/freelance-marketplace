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
    print("[AuthProvider] Attempting auto-login...");
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _token = await _storageService.getToken();
      print(
        "[AuthProvider] Token from storage: ${_token != null ? 'Found' : 'Not Found'}",
      );

      if (_token != null) {
        // Token exists, try fetching user profile
        try {
          print("[AuthProvider] Fetching user profile...");
          _currentUser = await _authService.getCurrentUserProfile();
          print("[AuthProvider] Profile fetched: ${_currentUser?.toJson()}");

          if (_currentUser == null) {
            print(
              "[AuthProvider] Profile fetch returned null, clearing token.",
            );
            _token = null;
            await _storageService.deleteToken();
            _errorMessage =
                "Session invalid or profile fetch failed. Please sign in again.";
          } else {
            print("[AuthProvider] Auto-login successful.");
          }
        } catch (error) {
          print(
            "[AuthProvider] Error fetching profile during auto-login: $error",
          );
          _token = null;
          _currentUser = null;
          await _storageService
              .deleteToken(); // Ensure invalid token is cleared
          _errorMessage =
              "Session expired or invalid ($error). Please sign in again.";
        }
      } else {
        print("[AuthProvider] No token found, clearing user.");
        _currentUser = null; // Ensure user is null if no token
      }
    } catch (e) {
      print(
        "[AuthProvider] Unexpected error during auto-login storage/logic: $e",
      );
      _token = null;
      _currentUser = null;
      _errorMessage = "An unexpected error occurred during login check.";
      // Ensure token is cleared if storage fails too
      try {
        await _storageService.deleteToken();
      } catch (_) {}
    } finally {
      print("[AuthProvider] Auto-login finished. Setting isLoading=false.");
      _isLoading = false;
      notifyListeners();
    }
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
