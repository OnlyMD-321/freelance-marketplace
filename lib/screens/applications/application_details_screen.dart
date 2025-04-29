// filepath: Mobile/freelancers_mobile_app/lib/screens/applications/application_details_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../../models/application.dart'; // Import Application model
import '../../providers/auth_provider.dart'; // Import AuthProvider
import '../../providers/chat_provider.dart'; // Import ChatProvider
import 'package:intl/intl.dart'; // Import intl for date formatting
import '../../models/user.dart'; // Import UserInfo
import '../chat/chat_screen.dart'; // Import ChatScreen
// Hypothetical navigation to applicant profile
import '../../providers/application_provider.dart'; // Need this for accept/reject

// Convert to StatefulWidget
class ApplicationDetailsScreen extends StatefulWidget {
  // Accept the full Application object
  final Application application;
  const ApplicationDetailsScreen({super.key, required this.application});

  @override
  State<ApplicationDetailsScreen> createState() =>
      _ApplicationDetailsScreenState();
}

class _ApplicationDetailsScreenState extends State<ApplicationDetailsScreen> {
  bool _isInitiatingChat = false; // Local loading state for the button
  bool _isUpdatingStatus = false; // Combined loading state for accept/reject

  // Helper function to initiate chat
  Future<void> _initiateChat(BuildContext context) async {
    print("[_initiateChat] Button pressed."); // Log start
    if (_isInitiatingChat) {
      print("[_initiateChat] Already initiating, returning.");
      return;
    }

    setState(() {
      _isInitiatingChat = true;
    });
    print("[_initiateChat] Loading state SET to true.");

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    String? recipientId;
    String? recipientUsername;
    String? errorMsg;
    String? conversationId;

    if (currentUser == null) {
      errorMsg = 'Error: Not logged in.';
      print("[_initiateChat] Error: Not logged in.");
    } else {
      // Determine recipient ID and username
      if (currentUser.userId == widget.application.workerId) {
        recipientId = widget.application.job?.clientId;
        recipientUsername = "Client";
        print(
          "[_initiateChat] User is Worker. Recipient (Client) ID: $recipientId",
        );
      } else {
        recipientId = widget.application.workerId;
        recipientUsername = widget.application.worker?.username;
        print(
          "[_initiateChat] User is Client/Other. Recipient (Worker) ID: $recipientId, Username: $recipientUsername",
        );
      }

      if (recipientId == null) {
        errorMsg = 'Error: Could not determine recipient ID.';
        print("[_initiateChat] Error: Recipient ID is null.");
      } else {
        print(
          "[_initiateChat] Attempting to get/create conversation with: $recipientId",
        );
        try {
          conversationId = await chatProvider.getOrCreateConversationId(
            recipientId: recipientId,
            recipientUsername: recipientUsername ?? 'Unknown User',
            jobId: widget.application.jobId,
            applicationId: widget.application.applicationId,
          );
          print(
            "[_initiateChat] Successfully received conversationId: $conversationId",
          );
        } catch (error, stackTrace) {
          // Catch stack trace too
          errorMsg = "Could not get/create conversation: $error";
          print(
            "[_initiateChat] Error during getOrCreateConversationId: $error",
          );
          print(stackTrace); // Print stack trace for detailed debugging
        }
      }
    }

    // Ensure mounted before proceeding (especially before navigation or setState)
    if (!mounted) {
      print("[_initiateChat] Widget unmounted, exiting.");
      return;
    }

    print("[_initiateChat] Setting loading state to false.");
    setState(() {
      _isInitiatingChat = false;
    });

    if (errorMsg != null) {
      print("[_initiateChat] Displaying error SnackBar: $errorMsg");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMsg)));
    } else if (conversationId != null) {
      print(
        "[_initiateChat] Navigating to ChatScreen with convoId: $conversationId",
      );
      final recipientInfo = UserInfo(
        userId: recipientId!,
        username: recipientUsername ?? 'Unknown User',
        profilePictureUrl:
            (currentUser?.userId == widget.application.workerId)
                ? null
                : widget.application.worker?.profilePictureUrl,
      );
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (_) => ChatScreen(
                conversationId: conversationId!,
                recipient: recipientInfo,
              ),
        ),
      );
    } else {
      print(
        "[_initiateChat] Error: conversationId is null but no error message was set.",
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to start chat. Unknown error.')),
      );
    }
    print("[_initiateChat] Function finished.");
  }

  // --- Accept/Reject Logic (New) ---
  Future<void> _updateApplicationStatus(ApplicationStatus newStatus) async {
    if (_isUpdatingStatus) return;
    setState(() {
      _isUpdatingStatus = true;
    });

    final appProvider = Provider.of<ApplicationProvider>(
      context,
      listen: false,
    );
    bool success = false;
    String? resultMessage;

    try {
      // Placeholder: Assume provider has a method like this
      // success = await appProvider.updateApplicationStatus(widget.application.applicationId, newStatus);
      print("Placeholder: Attempting to set status to ${newStatus.name}");
      // Simulate network delay and success for UI demo
      await Future.delayed(const Duration(seconds: 1));
      success = true; // Assume success for now
      resultMessage = 'Application ${newStatus.name}.';

      if (success && mounted) {
        // IMPORTANT: To see the status change reflected immediately,
        // the Application object itself needs to be updated.
        // This might involve:
        // 1. Refetching the application details.
        // 2. The provider updating its internal state and notifying listeners.
        // 3. Passing an updated Application object back from this screen.
        // For now, we just show a message and rely on list refresh when popping.
        print(
          "Status update simulated successfully. Screen state won't update without refetch/provider update.",
        );
      }
    } catch (e) {
      success = false;
      resultMessage = appProvider.errorMessage ?? 'Failed to update status: $e';
      print("Error updating status: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resultMessage ??
                (success ? 'Status updated.' : 'Failed to update status.'),
          ),
          backgroundColor:
              success ? Colors.green : Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Optionally pop screen on success if desired
      // if (success) Navigator.of(context).pop();
    }
  }

  // --- Withdraw Logic (New) ---
  Future<void> _withdrawApplication() async {
    if (_isUpdatingStatus) return; // Reuse loading flag or create a new one

    // Show confirmation dialog
    final bool confirm =
        await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Confirm Withdrawal'),
                content: const Text(
                  'Are you sure you want to withdraw this application? This action cannot be undone.',
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(ctx).pop(false),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: const Text('Withdraw'),
                    onPressed: () => Navigator.of(ctx).pop(true),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirm || !mounted) return;

    setState(() {
      _isUpdatingStatus = true; // Indicate loading
    });

    final appProvider = Provider.of<ApplicationProvider>(
      context,
      listen: false,
    );
    bool success = false;
    String? resultMessage;

    try {
      success = await appProvider.withdrawApplication(
        widget.application.applicationId,
      );
      if (success) {
        resultMessage = 'Application withdrawn successfully.';
      } else {
        resultMessage =
            appProvider.errorMessage ?? 'Failed to withdraw application.';
      }
    } catch (error) {
      success = false;
      resultMessage = 'An unexpected error occurred: ${error.toString()}';
      print("Error withdrawing application: $error");
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultMessage!),
          backgroundColor:
              success ? Colors.green : Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Pop the screen on successful withdrawal
      if (success) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access widget property using 'widget.'
    final Application application = widget.application;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final dateFormat = DateFormat.yMd().add_jm();

    // Get current user and auth provider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    final currentUserId = currentUser?.userId;

    // Determine roles for UI logic
    final bool isWorkerViewingOwn =
        currentUserId != null && currentUserId == application.workerId;
    final bool isClientViewing =
        currentUserId != null && currentUserId == application.job?.clientId;
    final bool shouldShowChatButton = currentUser != null;
    final bool canClientUpdateStatus =
        isClientViewing && application.status == ApplicationStatus.submitted;
    final bool canWorkerWithdraw =
        isWorkerViewingOwn && application.status == ApplicationStatus.submitted;

    String chatButtonLabel = "Chat";
    if (isWorkerViewingOwn) {
      chatButtonLabel = "Chat with Client";
    } else if (isClientViewing) {
      chatButtonLabel = "Chat with Applicant";
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Details'),
        // Consider adding context actions like 'View Job' or 'View Profile'?
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Job Info --- (Less prominent than applicant info here)
            Text(
              'Applied for:',
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              application.job?.title ?? 'Job ID: ${application.jobId}',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            // Optional: Add GestureDetector to navigate to Job Details?
            const SizedBox(height: 16),
            const Divider(),

            // --- Applicant Info ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: colorScheme.secondaryContainer,
                    backgroundImage:
                        application.worker?.profilePictureUrl != null
                            ? NetworkImage(
                              application.worker!.profilePictureUrl!,
                            )
                            : null,
                    child:
                        application.worker?.profilePictureUrl == null
                            ? Icon(
                              Icons.person,
                              size: 30,
                              color: colorScheme.onSecondaryContainer,
                            )
                            : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Applicant:',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          application.worker?.username ??
                              'Worker ID: ${application.workerId}',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Optional: Add GestureDetector to navigate to Profile?
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),

            // --- Application Details ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                children: [
                  _buildInfoRow(
                    context,
                    Icons.calendar_today_outlined,
                    'Submitted',
                    dateFormat.format(application.submissionDate.toLocal()),
                  ),
                  _buildInfoRow(
                    context,
                    Icons.label_important_outline,
                    'Status',
                    application.status.name.toUpperCase(),
                    color: _getStatusColor(application.status, colorScheme),
                  ),
                  // Add more application details here if available (e.g., cover letter snippet?)
                ],
              ),
            ),
            const Divider(),
            const SizedBox(height: 32),

            // --- Action Buttons --- Conditionally rendered
            if (_isUpdatingStatus)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              // Client Actions (Accept/Reject)
              if (canClientUpdateStatus)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                      ),
                      onPressed:
                          () => _updateApplicationStatus(
                            ApplicationStatus.accepted,
                          ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                      ),
                      onPressed:
                          () => _updateApplicationStatus(
                            ApplicationStatus.rejected,
                          ),
                    ),
                  ],
                ),

              // Worker Action (Withdraw) --- VVV
              if (canWorkerWithdraw)
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.cancel_schedule_send_outlined),
                    label: const Text('Withdraw Application'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.errorContainer,
                      foregroundColor: colorScheme.onErrorContainer,
                      minimumSize: const Size(
                        double.infinity,
                        40,
                      ), // Make it wider
                    ),
                    onPressed: _withdrawApplication,
                  ),
                ),

              // General Action (Chat)
              if (shouldShowChatButton)
                Padding(
                  padding: const EdgeInsets.only(
                    top: 16.0,
                  ), // Space above chat button
                  child: Center(
                    child:
                        _isInitiatingChat
                            ? const CircularProgressIndicator()
                            : ElevatedButton.icon(
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: Text(chatButtonLabel),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(
                                  double.infinity,
                                  40,
                                ), // Make it wider
                              ),
                              onPressed: () => _initiateChat(context),
                            ),
                  ),
                ),
            ],
            const SizedBox(height: 20), // Bottom padding
          ],
        ),
      ),
    );
  }

  // --- Helper Widget for Info Row (similar to job details) ---
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
                color: color ?? theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  // Helper to get status color (from application list screen)
  Color _getStatusColor(ApplicationStatus status, ColorScheme colorScheme) {
    switch (status) {
      case ApplicationStatus.accepted:
        return Colors.green.shade700;
      case ApplicationStatus.rejected:
        return colorScheme.error;
      case ApplicationStatus.submitted:
      case ApplicationStatus.withdrawn:
      default:
        return colorScheme.secondary; // Or a neutral color
    }
  }
}
