// filepath: Mobile/lib/providers/application_provider.dart
import 'package:flutter/material.dart';
import '../services/application_service.dart';
import '../models/application.dart';
// For UserType

class ApplicationProvider with ChangeNotifier {
  final ApplicationService _applicationService = ApplicationService();

  List<Application> _myApplications =
      []; // Applications submitted by the current user (Worker)
  List<Application> _jobApplications =
      []; // Applications for a specific job (Client view)
  bool _isLoading = false;
  String? _errorMessage;

  List<Application> get myApplications => [..._myApplications];
  List<Application> get jobApplications => [..._jobApplications];
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fetch applications submitted by the current user (Worker)
  Future<void> fetchMyApplications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myApplications =
          await _applicationService
              .listApplications(); // No jobId means fetch user's own
    } catch (error) {
      _errorMessage = "Failed to fetch your applications: $error";
      _myApplications = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch applications for a specific job (Client)
  Future<void> fetchJobApplications(String jobId) async {
    _isLoading = true;
    _errorMessage = null;
    _jobApplications = []; // Clear previous job's applications
    notifyListeners();

    try {
      _jobApplications = await _applicationService.listApplications(
        jobId: jobId,
      );
    } catch (error) {
      _errorMessage = "Failed to fetch applications for job $jobId: $error";
      _jobApplications = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Apply for a job (Worker)
  Future<bool> applyForJob(String jobId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newApplication = await _applicationService.applyForJob(jobId);
      if (newApplication != null) {
        // Optionally add to myApplications list or refetch
        // _myApplications.insert(0, newApplication);
        await fetchMyApplications(); // Refetch to be sure
        return true;
      }
      // If service throws, it's caught below
      return false; // Should not be reached if service throws on failure
    } catch (error) {
      _errorMessage = "Failed to apply: ${error.toString()}";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update application status (Client)
  Future<bool> updateApplicationStatus(
    String applicationId,
    ApplicationStatus status,
    String jobId,
  ) async {
    _isLoading = true; // Consider a more granular loading state if needed
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedApplication = await _applicationService
          .updateApplicationStatus(applicationId, status);
      if (updatedApplication != null) {
        // Update the list of job applications
        final index = _jobApplications.indexWhere(
          (app) => app.applicationId == applicationId,
        );
        if (index != -1) {
          _jobApplications[index] = updatedApplication;
        } else {
          // If not found, maybe refetch? Or handle as error?
          await fetchJobApplications(jobId); // Refetch for consistency
        }
        return true;
      }
      return false;
    } catch (error) {
      _errorMessage = "Failed to update status: ${error.toString()}";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Withdraw an application (Worker)
  Future<bool> withdrawApplication(String applicationId) async {
    _isLoading = true; // Consider more granular loading state if needed
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _applicationService.withdrawApplication(
        applicationId,
      );
      if (success) {
        // Remove the application from the local list
        _myApplications.removeWhere(
          (app) => app.applicationId == applicationId,
        );
      }
      return success;
    } catch (error) {
      _errorMessage = "Failed to withdraw application: ${error.toString()}";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear job-specific applications when leaving a view
  void clearJobApplications() {
    _jobApplications = [];
    // notifyListeners(); // Optional
  }
}
