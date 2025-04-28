// filepath: Mobile/freelancers_mobile_app/lib/screens/applications/application_details_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../../models/application.dart'; // Import Application model
import '../../providers/auth_provider.dart'; // Import AuthProvider
import '../../providers/chat_provider.dart'; // Import ChatProvider
import 'package:intl/intl.dart'; // Import intl for date formatting
import '../../models/user.dart'; // Import UserInfo
import '../chat/chat_screen.dart'; // Import ChatScreen

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

  @override
  Widget build(BuildContext context) {
    // Access widget property using 'widget.'
    final Application application = widget.application;

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

    String chatButtonLabel = "Chat";
    if (isWorkerViewingOwn) {
      chatButtonLabel = "Chat with Client";
    } else if (isClientViewing) {
      chatButtonLabel = "Chat with Applicant";
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Application Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Job: ${application.job?.title ?? application.jobId}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            if (application.worker != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundImage:
                      application.worker!.profilePictureUrl != null
                          ? NetworkImage(application.worker!.profilePictureUrl!)
                          : null,
                  child:
                      application.worker!.profilePictureUrl == null
                          ? const Icon(Icons.person)
                          : null,
                ),
                title: Text('Applicant: ${application.worker!.username}'),
              )
            else
              Text('Applicant ID: ${application.workerId}'),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Text('Status: ${application.status.name}'),
            const SizedBox(height: 8),
            Text(
              'Submitted: ${DateFormat.yMd().add_jm().format(application.submissionDate.toLocal())}',
            ),
            const Spacer(),
            if (shouldShowChatButton)
              Center(
                child:
                    _isInitiatingChat
                        ? const CircularProgressIndicator()
                        : ElevatedButton.icon(
                          icon: const Icon(Icons.message),
                          label: Text(chatButtonLabel),
                          onPressed:
                              _isInitiatingChat
                                  ? null
                                  : () {
                                    _initiateChat(context);
                                  },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(200, 50),
                          ),
                        ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
