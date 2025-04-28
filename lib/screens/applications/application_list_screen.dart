// filepath: Mobile/freelancers_mobile_app/lib/screens/applications/application_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/application_provider.dart';
import '../../models/application.dart';
import '../../utils/routes.dart'; // For navigation to details

class ApplicationListScreen extends StatefulWidget {
  final String?
  jobId; // Optional: If viewing applications for a specific job (Client)

  const ApplicationListScreen({super.key, this.jobId});

  @override
  State<ApplicationListScreen> createState() => _ApplicationListScreenState();
}

class _ApplicationListScreenState extends State<ApplicationListScreen> {
  // Use late initialization for the future
  late Future<void> _fetchApplicationsFuture;
  bool _isClientView = false;

  @override
  void initState() {
    super.initState();
    _isClientView = widget.jobId != null;
    // Initialize the future in initState. Provider call needs context, so use addPostFrameCallback.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Assign the future here to trigger the FutureBuilder
      if (mounted) {
        // Ensure widget is still mounted
        setState(() {
          _fetchApplicationsFuture = _fetchApplications();
        });
      }
    });
  }

  Future<void> _fetchApplications() async {
    // Ensure context is available and widget is mounted
    if (!mounted) return;
    final appProvider = Provider.of<ApplicationProvider>(
      context,
      listen: false,
    );
    try {
      if (_isClientView) {
        await appProvider.fetchJobApplications(widget.jobId!);
      } else {
        await appProvider.fetchMyApplications();
      }
    } catch (error) {
      // Error is stored in the provider, FutureBuilder snapshot will also catch it
      // Rethrow to ensure FutureBuilder snapshot.hasError is true
      rethrow;
    }
  }

  void _navigateToDetails(Application application) {
    Navigator.of(
      context,
    ).pushNamed(AppRoutes.applicationDetails, arguments: application).then((_) {
      // Refresh list when returning from details, especially for client view
      // where status might have changed.
      // Simply calling _fetchApplications should trigger the provider update,
      // which the Consumer will pick up.
      if (_isClientView && mounted) {
        print(
          "[AppListScreen] Returned from details, refetching client view applications...",
        );
        _fetchApplications(); // Call fetch directly, provider will notify
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final String title = _isClientView ? 'Job Applications' : 'My Applications';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder(
        future: _fetchApplicationsFuture,
        builder: (ctx, snapshot) {
          // Initial loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Initial error state
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error loading: ${snapshot.error}'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed:
                        () => setState(() {
                          _fetchApplicationsFuture = _fetchApplications();
                        }),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Data loaded successfully or subsequent state changes, use Consumer
          return Consumer<ApplicationProvider>(
            builder: (ctx, appProvider, child) {
              // Handle errors reported by the provider after initial load
              final applications =
                  _isClientView
                      ? appProvider.jobApplications
                      : appProvider.myApplications;
              if (appProvider.errorMessage != null && applications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${appProvider.errorMessage}'),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed:
                            () => setState(() {
                              _fetchApplicationsFuture = _fetchApplications();
                            }),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              // Handle loading state from provider (e.g., during refresh)
              if (appProvider.isLoading && applications.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              // Handle empty list state
              if (applications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No applications found.'),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed:
                            () => setState(() {
                              _fetchApplicationsFuture = _fetchApplications();
                            }),
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                );
              }

              // Display the list
              return RefreshIndicator(
                onRefresh: () async {
                  // Re-assign future on refresh to ensure UI updates correctly
                  await _fetchApplications();
                  if (mounted) {
                    setState(() {}); // Ensure rebuild after refresh completes
                  }
                },
                child: ListView.builder(
                  itemCount: applications.length,
                  itemBuilder: (ctx, index) {
                    final app = applications[index];
                    String listTitle = 'Application ID: ${app.applicationId}';
                    String listSubtitle = 'Status: ${app.status.name}';

                    if (_isClientView && app.worker != null) {
                      listTitle = 'Applicant: ${app.worker!.username}';
                      listSubtitle = 'Status: ${app.status.name}';
                    } else {
                      // TODO: Show Job Title for worker view (requires data)
                      listTitle = 'Job ID: ${app.jobId}';
                      listSubtitle = 'Status: ${app.status.name}';
                    }

                    return ListTile(
                      leading:
                          _isClientView && app.worker?.profilePictureUrl != null
                              ? CircleAvatar(
                                backgroundImage: NetworkImage(
                                  app.worker!.profilePictureUrl!,
                                ),
                              )
                              : (_isClientView
                                  ? const CircleAvatar(
                                    child: Icon(Icons.person),
                                  )
                                  : null),
                      title: Text(listTitle),
                      subtitle: Text(listSubtitle),
                      trailing: Text(
                        // TODO: Format date nicely
                        app.submissionDate.toLocal().toString().split(' ')[0],
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
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
}
