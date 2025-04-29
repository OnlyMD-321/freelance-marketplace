// filepath: Mobile/freelancers_mobile_app/lib/screens/jobs/job_list_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For currency formatting
import 'package:provider/provider.dart';
import 'dart:async'; // Import Timer for debouncing
import '../../providers/job_provider.dart';
import '../../models/job.dart'; // Import Job model for type hinting
import 'job_details_screen.dart';
import '../../providers/auth_provider.dart';
import '../../utils/routes.dart';
// import '../../models/user.dart'; // Import UserType if needed for strict check

class JobListScreen extends StatefulWidget {
  // Add the showMyJobs parameter
  final bool showMyJobs;

  const JobListScreen({super.key, this.showMyJobs = false}); // Default to false

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  // Keep track if initial fetch is happening
  bool _isInitialLoading = true;
  // Search controller now potentially managed by HomeScreen or passed down
  // For simplicity, let's keep search logic triggering here for now,
  // even though the UI will be in HomeScreen.
  // This isn't ideal architecture but avoids complex state lifting for this fix.
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Remove search controller listener if search is handled by HomeScreen
    // _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fetch initial jobs based on the new parameter
      _fetchJobs(isInitial: true);
    });
  }

  @override
  void dispose() {
    // Remove search controller listener if search is handled by HomeScreen
    // _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // This might be redundant if search is fully managed by HomeScreen
  // void _onSearchChanged() {
  //   if (_debounce?.isActive ?? false) _debounce?.cancel();
  //   _debounce = Timer(const Duration(milliseconds: 500), () {
  //     // Trigger fetch based on internal controller state or passed search term
  //     _fetchJobs();
  //   });
  // }

  Future<void> _fetchJobs({bool isInitial = false}) async {
    if (!mounted) return;
    if (isInitial ||
        Provider.of<JobProvider>(context, listen: false).jobs.isEmpty) {
      setState(() {
        _isInitialLoading = true;
      });
    }
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    // Determine which fetch method to call based on the widget parameter
    final String searchTerm = _searchController.text;
    try {
      if (widget.showMyJobs) {
        print("[JobListScreen] Fetching MY jobs...");
        await jobProvider
            .fetchMyJobs(); // Call the new method for client's own jobs
      } else {
        print("[JobListScreen] Fetching ALL jobs (search: '$searchTerm')...");
        await jobProvider.fetchJobs(search: searchTerm);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load jobs: ${jobProvider.errorMessage ?? error.toString()}',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  void _navigateToDetails(Job job) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => JobDetailsScreen(jobId: job.jobId),
      ),
    );
  }

  // This function is now managed by HomeScreen
  // void _navigateToCreateJob() { ... }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Consumer<JobProvider>(
      builder: (ctx, jobProvider, child) {
        // Use the correct list based on the screen's purpose
        final jobs = widget.showMyJobs ? jobProvider.myJobs : jobProvider.jobs;
        final showLoading =
            jobProvider.isLoading && (_isInitialLoading || jobs.isEmpty);

        if (showLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Use the correct error message source if they differ
        final errorMessage =
            widget.showMyJobs
                ? jobProvider.myJobsErrorMessage
                : jobProvider.errorMessage;

        if (!jobProvider.isLoading && errorMessage != null && jobs.isEmpty) {
          return _buildErrorState(
            context,
            errorMessage,
            () => _fetchJobs(), // Retry fetch
          );
        }

        final bool isSearching =
            !widget.showMyJobs && _searchController.text.isNotEmpty;
        final String emptyMessage =
            widget.showMyJobs
                ? 'You haven\'t posted any jobs yet.'
                : isSearching
                ? 'No jobs found matching your search criteria.'
                : 'There are currently no jobs available.';

        if (!jobProvider.isLoading && jobs.isEmpty) {
          return _buildEmptyState(
            context,
            emptyMessage,
            () => _fetchJobs(), // Refresh fetch
            isSearching,
          );
        }

        return RefreshIndicator(
          onRefresh: () => _fetchJobs(), // Refresh fetch
          color: theme.colorScheme.primary,
          child: ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: jobs.length, // Use the correct list
            itemBuilder: (ctx, index) {
              final job = jobs[index]; // Use the correct list
              return _JobListItem(
                job: job,
                onTap: () => _navigateToDetails(job),
              );
            },
          ),
        );
      },
    );
  }

  // Helper widget for Error State
  Widget _buildErrorState(
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
              'Failed to Load Jobs',
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

  // Helper widget for Empty State (modified to accept isSearching)
  Widget _buildEmptyState(
    BuildContext context,
    String message,
    VoidCallback onRefresh,
    bool isSearching, // Added parameter
  ) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearching ? Icons.search_off : Icons.work_off_outlined,
              color: theme.colorScheme.secondary,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'No Jobs Found',
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
            // Only show refresh button if not actively searching
            if (!isSearching)
              ElevatedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Feed'),
              ),
          ],
        ),
      ),
    );
  }
}

// --- Custom Widget for Job List Item ---
class _JobListItem extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;

  const _JobListItem({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    // Formatting for currency
    final currencyFormat = NumberFormat.currency(
      locale: 'en_US', // Adjust locale as needed
      symbol: '\$', // Adjust symbol as needed
      decimalDigits: 2,
    );

    return Card(
      elevation: 2.0, // Subtle elevation
      margin: const EdgeInsets.only(bottom: 12.0), // Spacing between cards
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Add client name if available
              if (job.client?.username != null)
                Row(
                  children: [
                    Icon(
                      Icons.business_center_outlined,
                      size: 16,
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      job.client!.username!,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              if (job.client?.username != null) const SizedBox(height: 6),
              Text(
                job.description,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 3, // Limit description lines
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Budget Info
                  if (job.budget != null)
                    Chip(
                      avatar: Icon(
                        Icons.attach_money,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      label: Text(
                        currencyFormat.format(job.budget),
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                      backgroundColor: colorScheme.primaryContainer.withOpacity(
                        0.3,
                      ),
                      side: BorderSide.none,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  // Placeholder if no budget
                  if (job.budget == null) const SizedBox(),
                  // Status Chip
                  Chip(
                    label: Text(
                      job.status.name.toUpperCase(), // Example: OPEN
                      style: textTheme.labelSmall?.copyWith(
                        color: Colors.white, // Text color on chip
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor:
                        job.status == JobStatus.open
                            ? Colors
                                .green
                                .shade600 // Green for open
                            : Colors.grey.shade600, // Grey for closed/other
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
