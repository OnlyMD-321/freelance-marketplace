// filepath: Mobile/lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'secure_storage_service.dart';
import '../models/user.dart'; // Import User model
import 'dart:async';

class AuthService {
  final SecureStorageService _storageService = SecureStorageService();
  final String _authUrl = '$apiBaseUrl/auth';
  final String _usersUrl = '$apiBaseUrl/users'; // Add users endpoint base

  // Sign In
  Future<Map<String, dynamic>> signIn(String email, String password) async {
    final url = Uri.parse('$_authUrl/signin');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['accessToken'] != null) {
        await _storageService.saveToken(responseData['accessToken']);
        return {'success': true, 'token': responseData['accessToken']};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Sign in failed',
        };
      }
    } catch (error) {
      print('Sign in error: $error');
      return {'success': false, 'message': 'An error occurred during sign in.'};
    }
  }

  // Sign Up
  Future<Map<String, dynamic>> signUp({
    required String username,
    required String email,
    required String password,
    required String userType, // e.g., "Worker" or "Client"
  }) async {
    final url = Uri.parse('$_authUrl/signup');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'userType': userType,
        }),
      );
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Sign up successful',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Sign up failed',
        };
      }
    } catch (error) {
      print('Sign up error: $error');
      return {'success': false, 'message': 'An error occurred during sign up.'};
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _storageService.deleteToken();
      print("[AuthService] signOut: Token deleted.");
    } catch (error) {
      print("Error deleting token during sign out: $error");
    }
  }

  // Helper to get authenticated headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await _storageService.getToken();
    if (token == null) {
      throw Exception('Authentication token not found.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Fetch Current User Profile
  Future<User?> getCurrentUserProfile() async {
    final url = Uri.parse('$_usersUrl/me'); // Assumes endpoint /api/v1/users/me
    print(
      "[AuthService] getCurrentUserProfile: Attempting GET $url",
    ); // Added log
    try {
      print(
        "[AuthService] getCurrentUserProfile: Getting headers...",
      ); // Added log
      final headers = await _getHeaders();
      print(
        "[AuthService] getCurrentUserProfile: Headers obtained. Making request...",
      ); // Added log

      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10)); // Added timeout

      print(
        "[AuthService] getCurrentUserProfile: Response status: ${response.statusCode}",
      ); // Added log
      // print("[AuthService] getCurrentUserProfile: Response body: ${response.body}"); // Optional: Uncomment for full body

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print(
          "[AuthService] getCurrentUserProfile: Success (200). Parsing user.",
        ); // Added log
        return User.fromJson(responseData);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        print("[AuthService] getCurrentUserProfile: Unauthorized (401/403).");
        await signOut(); // Clear local token if unauthorized
        return null;
      } else {
        print(
          '[AuthService] getCurrentUserProfile: Failed. Status: ${response.statusCode}, Body: ${response.body}', // Enhanced log
        );
        throw Exception('Failed to load user profile');
      }
    } on TimeoutException catch (e) {
      // Specific catch for timeout
      print(
        '[AuthService] getCurrentUserProfile: Error - Request timed out: $e',
      );
      throw Exception('Request timed out while fetching profile.');
    } catch (error) {
      print(
        '[AuthService] getCurrentUserProfile: Error - $error',
      ); // Enhanced log
      // Consider specific error handling (e.g., network error vs. timeout)
      return null; // Or rethrow depending on desired behavior
    }
  }

  Future<Map<String, dynamic>?> updateUserProfile(
    Map<String, dynamic> updates,
  ) async {
    final url = Uri.parse('$_usersUrl/me'); // Endpoint for updating profile
    print("[AuthService] updateUserProfile: Attempting PATCH $url");
    try {
      final headers = await _getHeaders();
      final response = await http
          .put(url, headers: headers, body: jsonEncode(updates))
          .timeout(const Duration(seconds: 15));

      print(
        "[AuthService] updateUserProfile: Response status: ${response.statusCode}",
      );
      // print("[AuthService] updateUserProfile: Response body: ${response.body}"); // Uncomment for debugging

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("[AuthService] updateUserProfile: Success (200).");
        // IMPORTANT: Extract the 'user' object from the response
        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('user')) {
          return responseData['user'] as Map<String, dynamic>;
        } else {
          print(
            "[AuthService] updateUserProfile: Error - 'user' object missing in response.",
          );
          throw Exception('Invalid response format from server');
        }
      } else {
        // Try to parse error message from backend
        String errorMessage = 'Failed to update profile.';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map<String, dynamic> &&
              errorData.containsKey('message')) {
            errorMessage = errorData['message'];
          }
        } catch (_) {
          /* Ignore parsing errors */
        }
        print(
          "[AuthService] updateUserProfile: Failed. Status: ${response.statusCode}, Message: $errorMessage",
        );
        throw Exception(errorMessage); // Throw exception with backend message
      }
    } catch (error) {
      print("[AuthService] updateUserProfile: Error: $error");
      // Rethrow the specific error message or a generic one
      throw Exception(
        error is Exception
            ? error.toString() // Use toString() for general exceptions
            : 'Failed to update profile due to an unexpected error.',
      );
    }
  }
}
