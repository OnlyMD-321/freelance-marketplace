// filepath: Mobile/lib/providers/job_provider.dart
import 'package:flutter/material.dart';
import '../services/job_service.dart';
import '../models/job.dart';

class JobProvider with ChangeNotifier {
  final JobService _jobService = JobService();

  List<Job> _jobs = [];
  bool _isLoading = false;
  String? _errorMessage;
  Job? _selectedJob; // For job details view

  List<Job> get jobs => [..._jobs]; // Return a copy
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Job? get selectedJob => _selectedJob;

  // Fetch the list of jobs
  Future<void> fetchJobs({String? status, String? search}) async {
    _isLoading = true;
    _errorMessage = null;
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

  // Fetch details for a single job
  Future<void> fetchJobDetails(String jobId) async {
    _isLoading = true;
    _selectedJob = null; // Clear previous selection
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedJob = await _jobService.getJobDetails(jobId);
      if (_selectedJob == null) {
         _errorMessage = "Job not found.";
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
    notifyListeners();

    try {
      final newJob = await _jobService.createJob(
        title: title,
        description: description,
        budget: budget,
        deadline: deadline,
      );
      if (newJob != null) {
        // Optionally add to the list or refetch
        // _jobs.insert(0, newJob); // Add to beginning
        await fetchJobs(); // Refetch the list to include the new job
        return true;
      } else {
        _errorMessage = "Failed to create job.";
        return false;
      }
    } catch (error) {
      _errorMessage = "Error creating job: $error";
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