// filepath: Mobile/lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'secure_storage_service.dart';
import '../models/user.dart'; // Import User model

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

      if (response.statusCode == 200 && responseData['token'] != null) {
        await _storageService.saveToken(responseData['token']);
        return {'success': true, 'token': responseData['token']};
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
      print("Token deleted successfully.");
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
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return User.fromJson(responseData);
      } else {
        print(
          'Failed to fetch profile: ${response.statusCode} ${response.body}',
        );
        // If token is invalid (e.g., 401), might need to trigger sign out
        if (response.statusCode == 401 || response.statusCode == 403) {
          await _storageService.deleteToken(); // Clear invalid token
          throw Exception('Unauthorized. Please sign in again.');
        }
        return null;
      }
    } catch (error) {
      print('Error fetching profile: $error');
      // Rethrow specific errors if needed
      rethrow;
    }
  }
}
