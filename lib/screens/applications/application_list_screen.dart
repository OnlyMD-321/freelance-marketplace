import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../../providers/application_provider.dart';
import '../../providers/auth_provider.dart'; // To determine user type
import '../../models/application.dart';
import '../../utils/routes.dart';
import '../../models/user.dart'; // For UserType enum if used

class ApplicationListScreen extends StatefulWidget {
  final String?
  jobId; // Only provided if a Client is viewing apps for a specific job

  const ApplicationListScreen({super.key, this.jobId});

  @override
  State<ApplicationListScreen> createState() => _ApplicationListScreenState();
}

class _ApplicationListScreenState extends State<ApplicationListScreen> {
  late Future<void> _fetchApplicationsFuture;
  bool _isClientJobView = false;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    // Initial setup of view type, but can be refined in fetch
    _isClientJobView = widget.jobId != null;
    _fetchApplicationsFuture = _fetchApplications(isInitial: true);
  }

  Future<void> _fetchApplications({bool isInitial = false}) async {
    if (isInitial) {
      setState(() {
        _isInitialLoading = true;
      });
    }
    final appProvider = Provider.of<ApplicationProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      if (!authProvider.isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final currentUser = authProvider.currentUser!;
      final isClientUser = currentUser.userType == UserType.client; // Use Enum!

      if (widget.jobId != null) {
        // Always fetch for a specific job if jobId is provided (Client or Worker)
        print("[AppList] Fetching applications for JOB: ${widget.jobId}");
        _isClientJobView = true; // Ensure this view type is set
        await appProvider.fetchJobApplications(widget.jobId!);
      } else {
        // No jobId: Determine if it's Worker's 'My Applications' or Client's 'All Their Job Apps'
        if (isClientUser) {
          print("[AppList] Fetching ALL applications for Client's jobs");
          _isClientJobView = true; // Treat Client's main view as a client view
          // Assuming fetchMyApplications handles fetching all relevant apps for a client when jobId is null
          // OR if backend GET /applications returns client's apps when jobId is null
          await appProvider
              .fetchMyApplications(); // Re-evaluate if this method name/logic is correct for clients
        } else {
          // Worker viewing their own applications
          print("[AppList] Fetching Worker's MY applications");
          _isClientJobView = false;
          await appProvider.fetchMyApplications();
        }
      }
    } catch (error) {
      print("[AppList] Error fetching applications: $error");
      // Error handled by provider and FutureBuilder snapshot
      if (mounted) {
        // Optionally show snackbar for non-initial errors
        if (!isInitial) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error refreshing: ${appProvider.errorMessage ?? error.toString()}',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
      rethrow; // Ensure FutureBuilder snapshot.hasError is true
    } finally {
      if (mounted && isInitial) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  void _navigateToDetails(Application application) {
    Navigator.of(
      context,
    ).pushNamed(AppRoutes.applicationDetails, arguments: application).then((_) {
      // Refresh list when returning from details if status might have changed
      // Primarily needed for client view, but good practice to refresh worker view too.
      if (mounted) {
        print("[AppList] Returned from details, refreshing applications...");
        // Just trigger a refetch, Consumer will update the UI
        _fetchApplications();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine the actual user type for UI logic (needed for title)
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Note: _isClientJobView is set in _fetchApplications and initState
    final String appBarTitle =
        widget.jobId != null
            ? 'Applicants for Job' // Title when viewing specific job applicants
            : (authProvider.currentUser?.userType == UserType.client
                ? 'Applications for My Jobs' // Title for client's main app view (if ever used)
                : 'My Applications'); // Title for worker's main app view

    // --- Structure: Scaffold -> AppBar -> FutureBuilder -> Consumer -> Content ---
    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        // Back button added automatically if pushed onto navigation stack
        // Ensure this screen is PUSHED, not part of IndexedStack if showing specific job apps
      ),
      body: FutureBuilder(
        future: _fetchApplicationsFuture,
        builder: (ctx, snapshot) {
          // Initial Loading State
          if (snapshot.connectionState == ConnectionState.waiting &&
              _isInitialLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Initial Error State (or auth error)
          if (snapshot.hasError) {
            String errorMessage = snapshot.error.toString();
            if (snapshot.error is Exception &&
                snapshot.error.toString().contains('User not authenticated')) {
              errorMessage = 'Please log in to view applications.';
            }
            return _buildErrorState(context, errorMessage, () {
              setState(() {
                _fetchApplicationsFuture = _fetchApplications(isInitial: true);
              });
            });
          }

          // Use Consumer for subsequent states and data
          return Consumer<ApplicationProvider>(
            builder: (ctx, appProvider, child) {
              final applications =
                  _isClientJobView
                      ? appProvider
                          .jobApplications // Use job-specific apps
                      : appProvider.myApplications; // Use worker's apps

              // Loading state during refresh (only show if list is empty)
              if (appProvider.isLoading && applications.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              // Error state after initial load
              if (!appProvider.isLoading &&
                  appProvider.errorMessage != null &&
                  applications.isEmpty) {
                return _buildErrorState(context, appProvider.errorMessage!, () {
                  setState(() {
                    _fetchApplicationsFuture = _fetchApplications();
                  });
                });
              }

              // Empty state
              if (!appProvider.isLoading && applications.isEmpty) {
                final emptyMessage =
                    _isClientJobView
                        ? 'No applications received for this job yet.'
                        : 'You haven\'t applied to any jobs yet.';
                return _buildEmptyState(context, emptyMessage, () {
                  setState(() {
                    _fetchApplicationsFuture = _fetchApplications();
                  });
                });
              }

              // List View (Moved RefreshIndicator and ListView here)
              return RefreshIndicator(
                onRefresh: () => _fetchApplications(),
                color: Theme.of(context).colorScheme.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.all(12.0),
                  itemCount: applications.length,
                  itemBuilder: (ctx, index) {
                    final app = applications[index];
                    return _ApplicationListItem(
                      application: app,
                      isClientView: _isClientJobView, // Pass view type
                      onTap: () => _navigateToDetails(app),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Use common helper widgets from JobListScreen or redefine here if needed
  // Reusing the Error State builder (similar structure)
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
              'Failed to Load Applications',
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

  // Reusing the Empty State builder (similar structure)
  Widget _buildEmptyState(
    BuildContext context,
    String message,
    VoidCallback onRefresh,
  ) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_off_outlined,
              color: theme.colorScheme.secondary,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'No Applications Found',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message, // Use dynamic message
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Custom Widget for Application List Item ---
class _ApplicationListItem extends StatelessWidget {
  final Application application;
  final bool isClientView; // Determines how to display the item
  final VoidCallback onTap;

  const _ApplicationListItem({
    required this.application,
    required this.isClientView,
    required this.onTap,
  });

  // Helper to get status color
  Color _getStatusColor(ApplicationStatus status, ColorScheme colorScheme) {
    switch (status) {
      case ApplicationStatus.accepted:
        return Colors.green.shade700;
      case ApplicationStatus.rejected:
        return colorScheme.error;
      case ApplicationStatus.submitted:
      case ApplicationStatus.withdrawn:
      default:
        return colorScheme
            .secondary; // Or a neutral color like Colors.orange for submitted?
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final dateFormat =
        DateFormat.yMd().add_jm(); // Format like 10/15/2024, 3:30 PM

    Widget leadingWidget;
    String titleText;
    String subtitleText = 'Status: ${application.status.name}';

    if (isClientView) {
      // Client is viewing applications for their job
      leadingWidget = CircleAvatar(
        backgroundColor: colorScheme.secondaryContainer,
        foregroundColor: colorScheme.onSecondaryContainer,
        // TODO: Use actual profile picture URL if available
        // backgroundImage: application.worker?.profilePictureUrl != null
        //     ? NetworkImage(application.worker!.profilePictureUrl!)
        //     : null,
        child:
            application.worker?.profilePictureUrl == null
                ? Icon(Icons.person_outline, size: 24)
                : null,
      );
      titleText = 'Applicant: ${application.worker?.username ?? 'N/A'}';
    } else {
      // Worker is viewing their own applications
      leadingWidget = Icon(
        Icons.work_outline,
        color: colorScheme.primary,
        size: 32,
      );
      titleText = 'Job: ${application.job?.title ?? 'Job N/A'}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              leadingWidget,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleText,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitleText,
                      style: textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Submitted: ${dateFormat.format(application.submissionDate.toLocal())}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status Indicator Chip
              // Align chip to the top right if withdraw button might appear
              Align(
                alignment: Alignment.topCenter,
                child: Chip(
                  label: Text(
                    application.status.name.toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: _getStatusColor(
                    application.status,
                    colorScheme,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
