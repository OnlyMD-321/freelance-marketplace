// filepath: Mobile/lib/services/application_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart'; // Import the base URL
import '../models/application.dart';
import 'secure_storage_service.dart'; // To get the token

class ApplicationService {
  final SecureStorageService _storageService = SecureStorageService();

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

  // Apply for a Job (Worker)
  Future<Application?> applyForJob(String jobId) async {
    final url = Uri.parse('$apiBaseUrl/applications');
    try {
      final headers = await _getHeaders();
      final body = jsonEncode({'jobId': jobId});

      final response = await http.post(url, headers: headers, body: body);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return Application.fromJson(responseData);
      } else {
        print(
          'Failed to apply for job: ${response.statusCode} ${response.body}',
        );
        // Throw an exception with the error message from the backend
        throw Exception(responseData['message'] ?? 'Failed to apply for job.');
      }
    } catch (error) {
      print('Error applying for job: $error');
      // Rethrow the exception to be handled by the provider/UI
      rethrow;
    }
  }

  // List Applications (Worker viewing their own, or Client viewing for a specific job)
  Future<List<Application>> listApplications({String? jobId}) async {
    // If jobId is provided, list applications for that job (Client view)
    // If jobId is null, list applications submitted by the current user (Worker view)
    final queryParams = {if (jobId != null) 'jobId': jobId};
    final url = Uri.parse(
      '$apiBaseUrl/applications',
    ).replace(queryParameters: queryParams);

    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        return responseData.map((json) => Application.fromJson(json)).toList();
      } else {
        print(
          'Failed to list applications: ${response.statusCode} ${response.body}',
        );
        throw Exception('Failed to list applications.');
      }
    } catch (error) {
      print('Error listing applications: $error');
      rethrow;
    }
  }

  // Update Application Status (Client)
  Future<Application?> updateApplicationStatus(
    String applicationId,
    ApplicationStatus status,
  ) async {
    final url = Uri.parse('$apiBaseUrl/applications/$applicationId/status');
    try {
      final headers = await _getHeaders();
      // Convert enum status to string expected by backend (e.g., 'Accepted', 'Rejected')
      // Assuming backend expects PascalCase or lowercase - adjust if needed
      final String statusString =
          status.name[0].toUpperCase() + status.name.substring(1);
      // Or simply: final String statusString = status.name; if backend expects lowercase

      final body = jsonEncode({'status': statusString});

      final response = await http.patch(
        url,
        headers: headers,
        body: body,
      ); // Or PUT
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return Application.fromJson(
          responseData['application'],
        ); // Assuming response is { message: '...', application: {...} }
      } else {
        print(
          'Failed to update application status: ${response.statusCode} ${response.body}',
        );
        throw Exception(responseData['message'] ?? 'Failed to update status.');
      }
    } catch (error) {
      print('Error updating application status: $error');
      rethrow;
    }
  }

  // TODO: Add methods for getApplicationDetails and withdrawApplication (Worker) if needed
  // Future<Application?> getApplicationDetails(String applicationId) async { ... }

  // Withdraw Application (Worker)
  Future<bool> withdrawApplication(String applicationId) async {
    final url = Uri.parse('$apiBaseUrl/applications/$applicationId');
    try {
      final headers = await _getHeaders();
      final response = await http.delete(url, headers: headers);

      if (response.statusCode == 200 || response.statusCode == 204) {
        // 200 OK or 204 No Content are typical success statuses for DELETE
        return true;
      } else {
        final responseData = jsonDecode(response.body);
        print(
          'Failed to withdraw application: ${response.statusCode} ${response.body}',
        );
        throw Exception(
          responseData['message'] ?? 'Failed to withdraw application.',
        );
      }
    } catch (error) {
      print('Error withdrawing application: $error');
      rethrow;
    }
  }
}
