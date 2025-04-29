// filepath: Mobile/freelancers_mobile_app/lib/screens/jobs/job_details_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // For formatting
import '../../providers/job_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/application_provider.dart';
import '../../models/job.dart';
import '../../models/user.dart'; // For UserType enum
import '../applications/application_list_screen.dart';

class JobDetailsScreen extends StatefulWidget {
  final String jobId;
  const JobDetailsScreen({super.key, required this.jobId});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDetails();
    });
  }

  Future<void> _fetchDetails() async {
    // Added try-catch for better error handling during fetch
    try {
      final jobProvider = Provider.of<JobProvider>(context, listen: false);
      await jobProvider.fetchJobDetails(widget.jobId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load job details: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<JobProvider>(context, listen: false).clearSelectedJob();
      }
    });
    super.dispose();
  }

  Future<void> _applyForJob() async {
    if (_isApplying) return;
    setState(() {
      _isApplying = true;
    });

    final appProvider = Provider.of<ApplicationProvider>(
      context,
      listen: false,
    );
    bool success = false;
    try {
      success = await appProvider.applyForJob(widget.jobId);
    } catch (e) {
      success = false;
      print("Error applying for job: $e");
    }

    if (!mounted) return;

    setState(() {
      _isApplying = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Application submitted successfully!'
              : appProvider.errorMessage ?? 'Failed to submit application.',
        ),
        backgroundColor:
            success ? Colors.green : Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _viewApplications() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ApplicationListScreen(jobId: widget.jobId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        // AppBar styling is inherited from main.dart
        title: const Text('Job Details'), // Keep a simple title
      ),
      body: Consumer2<JobProvider, AuthProvider>(
        builder: (ctx, jobProvider, authProvider, child) {
          final job = jobProvider.selectedJob;
          final isLoadingJob = jobProvider.isLoading;
          final errorMessageJob = jobProvider.errorMessage;
          final currentUser = authProvider.currentUser;

          // --- Loading State ---
          if ((isLoadingJob) && job == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // --- Error State ---
          if (errorMessageJob != null && job == null) {
            return _buildErrorWidget(context, errorMessageJob, _fetchDetails);
          }

          // --- Job Not Found State ---
          if (job == null) {
            return _buildErrorWidget(
              context,
              'Job details not found.',
              _fetchDetails,
            );
          }

          // Determine user roles relative to the job
          final bool isOwner = currentUser?.userId == job.clientId;
          final bool isWorker = currentUser?.userType == UserType.worker;
          // Application button states are now handled by _isApplying

          return RefreshIndicator(
            onRefresh: _fetchDetails,
            color: colorScheme.primary,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Job Title and Client ---
                  Text(
                    job.title,
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.business_center_outlined,
                        size: 18,
                        color: colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Posted by: ${job.client?.username ?? 'Client ID: ${job.clientId}'}',
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),

                  // --- Key Information Section ---
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          context,
                          Icons.label_important_outline,
                          'Status',
                          job.status.name,
                          color: _getStatusColor(job.status, colorScheme),
                        ),
                        if (job.budget != null)
                          _buildInfoRow(
                            context,
                            Icons.attach_money,
                            'Budget',
                            NumberFormat.currency(
                              locale: 'en_US',
                              symbol: '\$',
                            ).format(job.budget!),
                          ),
                        _buildInfoRow(
                          context,
                          Icons.calendar_today_outlined,
                          'Posted',
                          DateFormat.yMMMd().format(job.postedDate.toLocal()),
                        ),
                        if (job.deadline != null)
                          _buildInfoRow(
                            context,
                            Icons.timer_outlined,
                            'Deadline',
                            DateFormat.yMMMd().format(job.deadline!.toLocal()),
                          ),
                      ],
                    ),
                  ),
                  const Divider(),

                  // --- Description Section ---
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          job.description,
                          style: textTheme.bodyLarge?.copyWith(height: 1.5),
                        ), // Improved line height
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- Action Button Area ---
                  _buildActionButtons(context, isOwner, isWorker, job.status),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Helper Widget for Info Row ---
  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widget for Action Buttons ---
  Widget _buildActionButtons(
    BuildContext context,
    bool isOwner,
    bool isWorker,
    JobStatus jobStatus,
  ) {
    final theme = Theme.of(context);

    // Case 1: Worker viewing an open job
    if (isWorker && jobStatus == JobStatus.open) {
      return Center(
        child:
            _isApplying
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: const Text('Apply Now'),
                  onPressed: _isApplying ? null : _applyForJob,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    backgroundColor:
                        _isApplying ? Colors.grey : theme.colorScheme.primary,
                  ),
                ),
      );
    }
    // Case 2: Owner viewing their job (any status)
    else if (isOwner) {
      return Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.list_alt),
          label: const Text('View Applications'),
          onPressed: _viewApplications,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
        ),
      );
    }
    // Case 3: Worker viewing a non-open job or non-worker/non-owner viewing
    else {
      // Optionally show a message or just nothing
      if (isWorker && jobStatus != JobStatus.open) {
        return Center(
          child: Text(
            'Applications are closed for this job.',
            style: theme.textTheme.bodyMedium,
          ),
        );
      }
      return const SizedBox.shrink(); // Show nothing by default
    }
  }

  // Helper function for status color (consistent with list view potentially)
  Color _getStatusColor(JobStatus status, ColorScheme colorScheme) {
    switch (status) {
      case JobStatus.open:
        return Colors.green.shade700;
      case JobStatus.inProgress:
        return Colors.blue.shade700;
      case JobStatus.completed:
        return colorScheme.primary;
      case JobStatus.cancelled:
        return colorScheme.error;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  // --- Helper Widget for Error State ---
  Widget _buildErrorWidget(
    BuildContext context,
    String message,
    VoidCallback onRetry,
  ) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 60),
            const SizedBox(height: 16),
            Text(
              'Could Not Load Job',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.errorContainer,
                foregroundColor: theme.colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
