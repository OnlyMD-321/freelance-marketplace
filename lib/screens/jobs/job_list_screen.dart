// filepath: Mobile/freelancers_mobile_app/lib/screens/jobs/job_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/job_provider.dart';
import 'job_details_screen.dart'; // For navigation
import '../../providers/auth_provider.dart'; // Import AuthProvider
// Import UserType
import '../../utils/routes.dart'; // Import AppRoutes

class JobListScreen extends StatefulWidget {
  const JobListScreen({super.key});

  @override
  State<JobListScreen> createState() => _JobListScreenState();
}

class _JobListScreenState extends State<JobListScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch jobs when the screen is first loaded
    // Use addPostFrameCallback to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchJobs();
    });
  }

  Future<void> _fetchJobs() async {
    // Access the provider without listening in initState/methods
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    // TODO: Add error handling UI based on provider's errorMessage
    await jobProvider.fetchJobs();
  }

  void _navigateToDetails(String jobId) {
    // Option 1: Using MaterialPageRoute
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => JobDetailsScreen(jobId: jobId)),
    );

    // Option 2: Using Named Routes (if defined in main.dart and AppRoutes)
    // Navigator.of(context).pushNamed(AppRoutes.jobDetails, arguments: jobId);
  }

  void _navigateToCreateJob() {
    // --- Check if user is a Client ---
    // This requires AuthProvider to expose user details
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Replace placeholder with actual check
    // final bool isClient = authProvider.currentUser?.userType == UserType.client;
    final bool isClient = true; // Placeholder

    if (isClient) {
      Navigator.of(context).pushNamed(AppRoutes.createJob);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only clients can post jobs.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- Also update the FloatingActionButton visibility ---
    // Replace placeholder with actual check
    // final bool isClient = Provider.of<AuthProvider>(context, listen: false).currentUser?.userType == UserType.client;
    final bool isClient = true; // Placeholder

    // Use Consumer to listen for changes in JobProvider
    return Scaffold(
      // AppBar might be part of HomeScreen if using BottomNavBar
      // appBar: AppBar(title: const Text('Available Jobs')),
      body: Consumer<JobProvider>(
        builder: (ctx, jobProvider, child) {
          if (jobProvider.isLoading && jobProvider.jobs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (jobProvider.errorMessage != null && jobProvider.jobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${jobProvider.errorMessage}'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _fetchJobs,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (jobProvider.jobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No jobs found.'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _fetchJobs,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          // Use RefreshIndicator for pull-to-refresh
          return RefreshIndicator(
            onRefresh: _fetchJobs,
            child: ListView.builder(
              itemCount: jobProvider.jobs.length,
              itemBuilder: (ctx, index) {
                final job = jobProvider.jobs[index];
                return ListTile(
                  title: Text(job.title),
                  subtitle: Text(
                    'Posted by: ${job.client?.username ?? 'Unknown'} - ${job.status.name}',
                  ),
                  trailing:
                      job.budget != null
                          ? Text('\$${job.budget?.toStringAsFixed(2)}')
                          : null,
                  onTap: () => _navigateToDetails(job.jobId),
                );
              },
            ),
          );
        },
      ),
      // FloatingActionButton might be conditional based on user type (Client)
      floatingActionButton:
          isClient
              ? FloatingActionButton(
                onPressed: _navigateToCreateJob,
                tooltip: 'Post New Job',
                child: const Icon(Icons.add),
              )
              : null, // Hide FAB if not a client
    );
  }
}
