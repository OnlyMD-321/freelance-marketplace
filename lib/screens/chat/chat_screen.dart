import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart'; // For UserInfo
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart'; // To get current user ID
import '../../services/chat_service.dart'; // Import ChatService for join/leave

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final UserInfo recipient;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.recipient,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController(); // To scroll to bottom
  // Access ChatService directly for non-state-changing actions like join/leave
  // It's often better practice for the provider to manage this, but for simplicity:
  final ChatService _chatService =
      ChatService(); // Assuming ChatService is a singleton or easily accessible

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMessages();
      _joinChatRoom();
      _markAsRead(); // Mark as read when entering screen
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _leaveChatRoom();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    if (!mounted) return;
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    // Fetch messages for the *current* conversation
    await chatProvider.fetchMessages(widget.conversationId);
    _scrollToBottom();
  }

  void _joinChatRoom() {
    // Call ChatService method to emit 'joinRoom'
    _chatService.joinRoom(widget.conversationId);
  }

  void _leaveChatRoom() {
    // Call ChatService method to emit 'leaveRoom'
    _chatService.leaveRoom(widget.conversationId);
  }

  void _markAsRead() {
    if (!mounted) return;
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.markAsRead(
      widget.conversationId,
    ); // Call provider's markAsRead
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    final messageContent = _messageController.text.trim(); // Store content
    _messageController.clear(); // Clear immediately

    // Schedule scroll after clearing, slightly delayed to allow build cycle
    Future.delayed(const Duration(milliseconds: 50), () => _scrollToBottom());

    if (!mounted) return; // Check mounted *after* clearing

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider
        .sendMessage(
          conversationId: widget.conversationId,
          recipientId: widget.recipient.userId,
          content: messageContent, // Use stored content
        )
        .catchError((error) {
          // Show error if sending fails
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Send failed: $error"),
                backgroundColor: Colors.red,
              ),
            );
            // Optionally restore text: _messageController.text = messageContent;
          }
        });

    // Removed clear from here
    // _messageController.clear();
  }

  void _scrollToBottom({bool immediate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final maxExtent = _scrollController.position.maxScrollExtent;
        if (immediate) {
          _scrollController.jumpTo(maxExtent);
        } else {
          _scrollController.animateTo(
            maxExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.userId;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipient.username), // Show recipient name
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (ctx, chatProvider, child) {
                final messages = chatProvider.messagesForConversation(
                  widget.conversationId,
                );
                final isLoading = chatProvider.isLoadingMessages;
                final error = chatProvider.errorMessageMessages;

                // ---- START DEBUG PRINT ----
                if (messages.isNotEmpty) {
                  print("--- ChatScreen Build ---");
                  print("Message Count: ${messages.length}");
                  print(
                    "First (Expected Oldest): ${messages.first.content} @ ${messages.first.sentAt}",
                  );
                  print(
                    "Last (Expected Newest): ${messages.last.content} @ ${messages.last.sentAt}",
                  );
                  print("----------------------");
                }
                // ---- END DEBUG PRINT ----

                // Schedule scroll after the build phase is complete
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (messages.isNotEmpty && _scrollController.hasClients) {
                    _scrollToBottom();
                  }
                });

                if (isLoading && messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Show error overlaying the list if loading failed but some messages exist
                if (error != null && messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Error: $error"),
                        ElevatedButton(
                          onPressed: _fetchMessages,
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  );
                }
                if (messages.isEmpty && !isLoading) {
                  return const Center(
                    child: Text("No messages yet. Send one!"),
                  );
                }

                // Display messages
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  itemCount: messages.length,
                  itemBuilder: (ctx, index) {
                    // List is sorted oldest-to-newest, access directly
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;
                    // Basic message bubble UI
                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              isMe
                                  ? Theme.of(context).primaryColorLight
                                  : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(message.content),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Message Input Area
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  blurRadius: 4,
                  color: Colors.black12,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Enter message...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    minLines: 1,
                    maxLines: 5,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
