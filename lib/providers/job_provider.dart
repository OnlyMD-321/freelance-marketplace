// filepath: Mobile/lib/providers/job_provider.dart
import 'package:flutter/material.dart';
import '../services/job_service.dart';
import '../models/job.dart';

class JobProvider with ChangeNotifier {
  final JobService _jobService = JobService();

  List<Job> _jobs = []; // For general job feed
  List<Job> _myJobs = []; // For client's posted jobs
  bool _isLoading = false;
  String? _errorMessage; // For general feed errors
  String? _myJobsErrorMessage; // For client's jobs errors
  Job? _selectedJob; // For job details view

  // Getters
  List<Job> get jobs => [..._jobs]; // Return a copy
  List<Job> get myJobs => [..._myJobs]; // Return a copy
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage; // General feed error
  String? get myJobsErrorMessage => _myJobsErrorMessage; // MyJobs error
  Job? get selectedJob => _selectedJob;

  // Fetch the list of all available jobs (job feed)
  Future<void> fetchJobs({String? status, String? search}) async {
    _isLoading = true;
    _errorMessage = null; // Clear general error
    // Don't clear _myJobsErrorMessage here
    notifyListeners();

    try {
      _jobs = await _jobService.listJobs(status: status, search: search);
    } catch (error) {
      _errorMessage = "Failed to fetch jobs: $error";
      _jobs = []; // Clear jobs on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch the list of jobs posted by the current client user
  Future<void> fetchMyJobs() async {
    _isLoading = true;
    _myJobsErrorMessage = null; // Clear myJobs error
    // Don't clear _errorMessage here
    notifyListeners();

    try {
      // Assume JobService has a method or listJobs supports filtering by current user
      // If listJobs needs the user ID, it should get it from SecureStorage via AuthService/StorageService
      // For simplicity, let's assume listJobs handles this if no clientId is passed, OR
      // we add a dedicated service method.
      // Let's add a placeholder for a dedicated service call:
      _myJobs = await _jobService.listMyJobs();
    } catch (error) {
      _myJobsErrorMessage = "Failed to fetch your jobs: $error";
      _myJobs = []; // Clear myJobs on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch details for a single job
  Future<void> fetchJobDetails(String jobId) async {
    _isLoading = true;
    _selectedJob = null; // Clear previous selection
    _errorMessage = null; // Clear potential error from list view
    _myJobsErrorMessage = null; // Clear potential error from list view
    notifyListeners();

    try {
      _selectedJob = await _jobService.getJobDetails(jobId);
      if (_selectedJob == null) {
        _errorMessage =
            "Job not found."; // Set general error for details screen
      }
    } catch (error) {
      _errorMessage = "Failed to fetch job details: $error";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new job (for clients)
  Future<bool> createJob({
    required String title,
    required String description,
    double? budget,
    DateTime? deadline,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _myJobsErrorMessage = null;
    notifyListeners();

    try {
      final newJob = await _jobService.createJob(
        title: title,
        description: description,
        budget: budget,
        deadline: deadline,
      );
      if (newJob != null) {
        // Refetch BOTH lists to ensure consistency, or just myJobs if that's the primary view after creation
        await fetchMyJobs(); // More likely view after posting
        // await fetchJobs(); // If needed immediately in main feed
        return true;
      } else {
        _errorMessage =
            "Failed to create job."; // Or maybe _myJobsErrorMessage?
        return false;
      }
    } catch (error) {
      _errorMessage =
          "Error creating job: $error"; // Or maybe _myJobsErrorMessage?
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear selected job when leaving details screen
  void clearSelectedJob() {
    _selectedJob = null;
    // notifyListeners(); // Optional: notify if needed elsewhere
  }
}
