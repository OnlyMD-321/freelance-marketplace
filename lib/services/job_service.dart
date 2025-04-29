// filepath: Mobile/lib/services/job_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart'; // Import the base URL
import '../models/job.dart';
import 'secure_storage_service.dart'; // To get the token

class JobService {
  final SecureStorageService _storageService = SecureStorageService();

  // Helper to get authenticated headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await _storageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', // Include the token
    };
  }

  // List Jobs
  Future<List<Job>> listJobs({
    String? status,
    String? search,
    int limit = 10,
    int offset = 0,
  }) async {
    final queryParams = {
      'limit': limit.toString(),
      'offset': offset.toString(),
      if (status != null) 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final url = Uri.parse(
      '$apiBaseUrl/jobs',
    ).replace(queryParameters: queryParams);

    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // Assuming the API returns { "jobs": [...], "pagination": {...} }
        final List<dynamic> jobListJson = responseData['jobs'];
        return jobListJson.map((json) => Job.fromJson(json)).toList();
      } else {
        print('Failed to list jobs: ${response.statusCode} ${response.body}');
        // Consider throwing a custom exception
        return []; // Return empty list on failure
      }
    } catch (error) {
      print('Error listing jobs: $error');
      return []; // Return empty list on error
    }
  }

  // List Jobs Posted by the Current (Client) User
  Future<List<Job>> listMyJobs({int limit = 10, int offset = 0}) async {
    // Assuming backend route /jobs/my or /jobs filters by authenticated user
    final queryParams = {
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    // Option 1: Use a dedicated route like /jobs/my
    // final url = Uri.parse('$apiBaseUrl/jobs/my').replace(queryParameters: queryParams);
    // Option 2: Assume /jobs filters by auth if no specific client ID is given
    final url = Uri.parse(
      '$apiBaseUrl/jobs',
    ).replace(queryParameters: queryParams);
    // Choose ONE of the above URL options based on backend implementation

    try {
      final headers = await _getHeaders(); // Use authenticated headers
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // Check if the response structure is the same as listJobs
        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('jobs')) {
          final List<dynamic> jobListJson = responseData['jobs'];
          return jobListJson.map((json) => Job.fromJson(json)).toList();
        } else if (responseData is List) {
          // Handle if backend just returns a list for /my route
          return responseData
              .map((json) => Job.fromJson(json as Map<String, dynamic>))
              .toList();
        } else {
          print(
            'Failed to list user jobs: Unexpected response format ${response.body}',
          );
          return [];
        }
      } else {
        print(
          'Failed to list user jobs: ${response.statusCode} ${response.body}',
        );
        return []; // Return empty list on failure
      }
    } catch (error) {
      print('Error listing user jobs: $error');
      return []; // Return empty list on error
    }
  }

  // Get Job Details
  Future<Job?> getJobDetails(String jobId) async {
    final url = Uri.parse('$apiBaseUrl/jobs/$jobId');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return Job.fromJson(responseData);
      } else {
        print(
          'Failed to get job details: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } catch (error) {
      print('Error getting job details: $error');
      return null;
    }
  }

  // Create Job (Only for Clients)
  Future<Job?> createJob({
    required String title,
    required String description,
    double? budget,
    DateTime? deadline,
  }) async {
    final url = Uri.parse('$apiBaseUrl/jobs');
    try {
      final headers = await _getHeaders();
      final body = jsonEncode({
        'title': title,
        'description': description,
        if (budget != null) 'budget': budget,
        if (deadline != null) 'deadline': deadline.toIso8601String(),
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return Job.fromJson(responseData);
      } else {
        print('Failed to create job: ${response.statusCode} ${response.body}');
        // Consider returning error message from response body
        return null;
      }
    } catch (error) {
      print('Error creating job: $error');
      return null;
    }
  }

  // TODO: Add methods for updateJob and deleteJob if needed
  // Future<Job?> updateJob(String jobId, Map<String, dynamic> updateData) async { ... }
  // Future<bool> deleteJob(String jobId) async { ... }
}
