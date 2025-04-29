import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Import intl for formatting
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/conversation.dart';
import '../../models/user.dart'; // Import UserInfo
import 'chat_screen.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  late Future<void> _fetchConversationsFuture;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _fetchConversationsFuture = _fetchConversations(isInitial: true);
        });
      }
    });
  }

  Future<void> _fetchConversations({bool isInitial = false}) async {
    if (!mounted) return;
    if (isInitial) {
      setState(() {
        _isInitialLoading = true;
      });
    }
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    try {
      print("[ConvList] Fetching conversations...");
      await chatProvider.fetchConversations();
    } catch (error) {
      print("[ConvList] Error fetching conversations: $error");
      if (mounted && !isInitial) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error refreshing conversations: ${chatProvider.errorMessageConversations ?? error.toString()}',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      rethrow;
    } finally {
      if (mounted && isInitial) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  void _navigateToChatScreen(Conversation conversation) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.userId;

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Could not identify current user.'),
        ),
      );
      return;
    }
    final otherParticipant = conversation.getOtherParticipant(currentUserId);
    if (otherParticipant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Could not identify recipient.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => ChatScreen(
              conversationId: conversation.conversationId,
              recipient: otherParticipant,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.userId;

    // This screen doesn't need its own AppBar
    return FutureBuilder(
      future: _fetchConversationsFuture,
      builder: (ctx, snapshot) {
        // Initial Loading
        if (snapshot.connectionState == ConnectionState.waiting &&
            _isInitialLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        // Initial Error
        if (snapshot.hasError) {
          return _buildErrorState(context, snapshot.error.toString(), () {
            setState(() {
              _fetchConversationsFuture = _fetchConversations(isInitial: true);
            });
          });
        }

        // Use Consumer for data and subsequent states
        return Consumer<ChatProvider>(
          builder: (ctx, chatProvider, child) {
            // Error after initial load
            if (!chatProvider.isLoadingConversations &&
                chatProvider.errorMessageConversations != null &&
                chatProvider.conversations.isEmpty) {
              return _buildErrorState(
                context,
                chatProvider.errorMessageConversations!,
                () {
                  setState(() {
                    _fetchConversationsFuture = _fetchConversations();
                  });
                },
              );
            }

            // Empty State
            if (!chatProvider.isLoadingConversations &&
                chatProvider.conversations.isEmpty) {
              return _buildEmptyState(context, () {
                setState(() {
                  _fetchConversationsFuture = _fetchConversations();
                });
              });
            }

            // List View
            return RefreshIndicator(
              onRefresh: () => _fetchConversations(),
              color: Theme.of(context).colorScheme.primary,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                ), // Add some vertical padding
                itemCount: chatProvider.conversations.length,
                itemBuilder: (ctx, index) {
                  final conversation = chatProvider.conversations[index];
                  final otherParticipant =
                      currentUserId != null
                          ? conversation.getOtherParticipant(currentUserId)
                          : null;

                  return _ConversationListItem(
                    participant: otherParticipant,
                    lastMessage: conversation.lastMessage,
                    lastMessageTimestamp: conversation.lastMessageTimestamp,
                    unreadCount: conversation.unreadCount,
                    onTap: () => _navigateToChatScreen(conversation),
                  );
                },
                separatorBuilder:
                    (ctx, index) => Divider(
                      height: 1,
                      thickness: 0.5,
                      indent: 80, // Indent divider past avatar
                      endIndent: 16,
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.5),
                    ),
              ),
            );
          },
        );
      },
    );
  }

  // --- Helper Widgets for States (similar to previous screens) ---
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
              'Failed to Load Messages',
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

  Widget _buildEmptyState(BuildContext context, VoidCallback onRefresh) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              color: theme.colorScheme.secondary,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'No Conversations Yet',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation by contacting a client or worker.',
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

// --- Custom Widget for Conversation List Item ---
class _ConversationListItem extends StatelessWidget {
  final UserInfo? participant;
  final String? lastMessage;
  final DateTime? lastMessageTimestamp;
  final int unreadCount;
  final VoidCallback onTap;

  const _ConversationListItem({
    required this.participant,
    required this.lastMessage,
    required this.lastMessageTimestamp,
    required this.unreadCount,
    required this.onTap,
  });

  // Helper to format timestamp nicely using intl
  String _formatTimestamp(BuildContext context, DateTime? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    if (messageDate == today) {
      return DateFormat.jm(
        Localizations.localeOf(context).toString(),
      ).format(timestamp); // e.g., 5:30 PM
    } else if (today.difference(messageDate).inDays == 1) {
      return 'Yesterday';
    } else if (today.difference(messageDate).inDays < 7) {
      return DateFormat.E(
        Localizations.localeOf(context).toString(),
      ).format(timestamp); // e.g., 'Tue'
    } else {
      return DateFormat.yMd(
        Localizations.localeOf(context).toString(),
      ).format(timestamp); // e.g., 10/15/2024
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final bool isUnread = unreadCount > 0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: colorScheme.secondaryContainer,
              backgroundImage:
                  participant?.profilePictureUrl != null
                      ? NetworkImage(participant!.profilePictureUrl!)
                      : null,
              child:
                  participant?.profilePictureUrl == null
                      ? Text(
                        participant?.username.substring(0, 1).toUpperCase() ??
                            '?',
                        style: textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                        ),
                      )
                      : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    participant?.username ?? 'Unknown User',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight:
                          isUnread ? FontWeight.bold : FontWeight.normal,
                      color:
                          isUnread
                              ? colorScheme.onSurface
                              : colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage ?? '...',
                    style: textTheme.bodyMedium?.copyWith(
                      color:
                          isUnread
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.onSurfaceVariant.withOpacity(0.7),
                      fontWeight:
                          isUnread ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatTimestamp(context, lastMessageTimestamp),
                  style: textTheme.bodySmall?.copyWith(
                    color:
                        isUnread
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant.withOpacity(0.7),
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (isUnread) ...[
                  const SizedBox(height: 4),
                  Badge(
                    label: Text(unreadCount.toString()),
                    backgroundColor: colorScheme.primary,
                    // Customize badge further if needed
                  ),
                ] else ...[
                  // Reserve space so layout doesn't jump when badge appears/disappears
                  const SizedBox(
                    height: 4 + 18,
                  ), // Adjust height based on Badge size
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
