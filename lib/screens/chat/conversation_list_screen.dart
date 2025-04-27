// filepath: Mobile/freelancers_mobile_app/lib/screens/chat/conversation_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart'; // To get current user ID
import '../../models/conversation.dart';
// For UserInfo
import 'chat_message_screen.dart'; // For navigation

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  late Future<void> _fetchConversationsFuture;

  @override
  void initState() {
    super.initState();
    // Fetch conversations when the screen is first loaded
    // Use addPostFrameCallback if provider access is needed immediately
    _fetchConversationsFuture = _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    // Ensure context is available and widget is mounted
    if (!mounted) return;
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.fetchConversations();
  }

  void _navigateToMessages(Conversation conversation) {
    // Select the conversation in the provider *before* navigating
    Provider.of<ChatProvider>(
      context,
      listen: false,
    ).selectConversation(conversation.conversationId);

    // Navigate to the message screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => ChatMessageScreen(
              conversationId: conversation.conversationId,
              // Pass participant info for app bar title
              // otherParticipant: conversation.getOtherParticipant(
              //   Provider.of<AuthProvider>(context, listen: false).currentUser!.userId
              // ),
            ),
      ),
    );
  }

  // Helper to format timestamp (consider using 'intl' package for better formatting)
  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0 && timestamp.day == now.day) {
      // Today: Show time HH:mm
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7 && timestamp.weekday < now.weekday) {
      // This week: Show weekday name (e.g., 'Mon', 'Tue')
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[timestamp.weekday - 1];
    } else {
      // Older: Show date MM/DD/YY
      return '${timestamp.month}/${timestamp.day}/${timestamp.year.toString().substring(2)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.userId;

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: FutureBuilder(
        future: _fetchConversationsFuture,
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
                  Text('Error loading conversations: ${snapshot.error}'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed:
                        () => setState(() {
                          _fetchConversationsFuture = _fetchConversations();
                        }),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Data loaded or subsequent changes, use Consumer
          return Consumer<ChatProvider>(
            builder: (ctx, chatProvider, child) {
              // Handle errors reported by provider after initial load
              if (chatProvider.errorMessageConversations != null &&
                  chatProvider.conversations.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${chatProvider.errorMessageConversations}'),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed:
                            () => setState(() {
                              _fetchConversationsFuture = _fetchConversations();
                            }),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              // Handle loading state from provider (e.g., during refresh)
              if (chatProvider.isLoadingConversations &&
                  chatProvider.conversations.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              // Handle empty list state
              if (chatProvider.conversations.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No conversations yet.'),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed:
                            () => setState(() {
                              _fetchConversationsFuture = _fetchConversations();
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
                  await _fetchConversations();
                  if (mounted) setState(() {}); // Ensure rebuild after refresh
                },
                child: ListView.builder(
                  itemCount: chatProvider.conversations.length,
                  itemBuilder: (ctx, index) {
                    final conversation = chatProvider.conversations[index];
                    final otherParticipant =
                        currentUserId != null
                            ? conversation.getOtherParticipant(currentUserId)
                            : null;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            otherParticipant?.profilePictureUrl != null
                                ? NetworkImage(
                                  otherParticipant!.profilePictureUrl!,
                                )
                                : null,
                        child:
                            otherParticipant?.profilePictureUrl == null
                                ? const Icon(Icons.person)
                                : null,
                      ),
                      title: Text(
                        otherParticipant?.username ?? 'Unknown User',
                        style: TextStyle(
                          fontWeight:
                              conversation.unreadCount > 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        conversation.lastMessage ?? 'No messages yet',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight:
                              conversation.unreadCount > 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                          color:
                              conversation.unreadCount > 0
                                  ? Theme.of(context).textTheme.bodyLarge?.color
                                  : Colors.grey,
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatTimestamp(conversation.lastMessageTimestamp),
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color:
                                  conversation.unreadCount > 0
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey,
                            ),
                          ),
                          if (conversation.unreadCount > 0) ...[
                            const SizedBox(height: 4),
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: Theme.of(context).primaryColor,
                              child: Text(
                                conversation.unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      onTap: () => _navigateToMessages(conversation),
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
