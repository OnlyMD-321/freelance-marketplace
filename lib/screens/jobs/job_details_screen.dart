// filepath: Mobile/freelancers_mobile_app/lib/screens/jobs/job_details_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/auth_provider.dart'; // To check user type
import '../../providers/application_provider.dart'; // Import ApplicationProvider
import '../../models/job.dart';
// For UserType enum
import '../applications/application_list_screen.dart'; // Import ApplicationListScreen

class JobDetailsScreen extends StatefulWidget {
  final String jobId;
  const JobDetailsScreen({super.key, required this.jobId});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  bool _isApplying = false; // Local state for apply button loading

  @override
  void initState() {
    super.initState();
    // Fetch job details when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDetails();
    });
  }

  Future<void> _fetchDetails() async {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    await jobProvider.fetchJobDetails(widget.jobId);
  }

  @override
  void dispose() {
    // Clear the selected job in the provider when leaving the screen
    // Do this in a post-frame callback to avoid issues during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if mounted before accessing provider
      if (mounted) {
        Provider.of<JobProvider>(context, listen: false).clearSelectedJob();
      }
    });
    super.dispose();
  }

  Future<void> _applyForJob() async {
    if (_isApplying) return; // Prevent double taps

    setState(() {
      _isApplying = true;
    });

    final appProvider = Provider.of<ApplicationProvider>(
      context,
      listen: false,
    );
    final success = await appProvider.applyForJob(widget.jobId);

    // Check if mounted before showing SnackBar or changing state
    if (!mounted) return;

    setState(() {
      _isApplying = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      // Optionally disable the button or change its text after successful application
      // You might need to add state to track if the user has already applied
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appProvider.errorMessage ?? 'Failed to submit application.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _viewApplications() {
    // Navigate to ApplicationListScreen filtered by this jobId
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ApplicationListScreen(jobId: widget.jobId),
      ),
    );
    // Or using named routes if you set up onGenerateRoute:
    // Navigator.of(context).pushNamed(AppRoutes.applications, arguments: widget.jobId);
  }

  @override
  Widget build(BuildContext context) {
    // Use Consumer for JobProvider and AuthProvider
    return Scaffold(
      appBar: AppBar(title: const Text('Job Details')),
      body: Consumer2<JobProvider, AuthProvider>(
        // Consume both providers
        builder: (ctx, jobProvider, authProvider, child) {
          final job = jobProvider.selectedJob;
          final isLoading = jobProvider.isLoading;
          final errorMessage = jobProvider.errorMessage;

          if (isLoading && job == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (errorMessage != null && job == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: $errorMessage'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _fetchDetails,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (job == null) {
            // Should ideally not happen if loading/error states are handled
            return const Center(child: Text('Job details not available.'));
          }

          // Determine if the current user is the client who posted the job
          // This requires AuthProvider to hold the current user's ID and type
          bool isOwner =
              false; // Replace with: authProvider.currentUser?.userId == job.clientId;
          bool isWorker =
              true; // Replace with: authProvider.currentUser?.userType == UserType.worker;

          // TODO: Add logic to check if the worker has *already* applied for this job
          bool hasAlreadyApplied = false; // Placeholder

          return RefreshIndicator(
            onRefresh: _fetchDetails,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Posted by: ${job.client?.username ?? 'Unknown'}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Status: ${job.status.name}',
                    style: TextStyle(color: _getStatusColor(job.status)),
                  ),
                  if (job.budget != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Budget: \$${job.budget!.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                  if (job.deadline != null) ...[
                    const SizedBox(height: 8),
                    // TODO: Format date nicely
                    Text('Deadline: ${job.deadline.toString()}'),
                  ],
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(job.description),
                  const SizedBox(height: 32),

                  // Action Buttons (Conditional)
                  if (isWorker &&
                      job.status == JobStatus.open &&
                      !hasAlreadyApplied)
                    Center(
                      child:
                          _isApplying
                              ? const CircularProgressIndicator() // Show loading on button
                              : ElevatedButton.icon(
                                icon: const Icon(Icons.send),
                                label: const Text('Apply Now'),
                                onPressed:
                                    _applyForJob, // Use the updated method
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 30,
                                    vertical: 15,
                                  ),
                                ),
                              ),
                    ),
                  if (isWorker &&
                      hasAlreadyApplied) // Show message if already applied
                    const Center(
                      child: Text(
                        "You have already applied for this job.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  if (isOwner)
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.list_alt),
                        label: const Text('View Applications'),
                        onPressed: _viewApplications,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper function for status color
  Color _getStatusColor(JobStatus status) {
    switch (status) {
      case JobStatus.open:
        return Colors.green;
      case JobStatus.inProgress:
        return Colors.blue;
      case JobStatus.completed:
        return Colors.grey;
      case JobStatus.cancelled:
        return Colors.red;
      default:
        return Colors.black;
    }
  }
}
