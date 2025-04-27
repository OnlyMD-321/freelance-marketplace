// filepath: Mobile/freelancers_mobile_app/lib/screens/chat/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/message.dart';
import '../../models/conversation.dart'; // To potentially get participant info
// For UserInfo

class ChatMessageScreen extends StatefulWidget {
  final String conversationId;
  // Optional: Pass participant info for immediate display in AppBar
  // final UserInfo? otherParticipant;

  const ChatMessageScreen({
    super.key,
    required this.conversationId,
    // this.otherParticipant,
  });

  @override
  State<ChatMessageScreen> createState() => _ChatMessageScreenState();
}

class _ChatMessageScreenState extends State<ChatMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false; // Local state for send button

  @override
  void initState() {
    super.initState();
    // Optional: Scroll to bottom when messages load initially or change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
      // Listen for provider updates to scroll when new messages arrive
      Provider.of<ChatProvider>(
        context,
        listen: false,
      ).addListener(_scrollToBottom);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // Remove listener when the widget is disposed
    // Check if provider still exists before removing listener
    try {
      Provider.of<ChatProvider>(
        context,
        listen: false,
      ).removeListener(_scrollToBottom);
    } catch (e) {
      // Provider might already be disposed if navigating away quickly
      print("Error removing ChatProvider listener: $e");
    }
    // Clear selected conversation when leaving the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Check if still mounted
        Provider.of<ChatProvider>(
          context,
          listen: false,
        ).clearSelectedConversation();
      }
    });
    super.dispose();
  }

  void _scrollToBottom() {
    // Ensure scroll controller is attached and has clients
    if (_scrollController.hasClients) {
      // Delay slightly to allow layout to complete
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          // Check again after delay
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    // TODO: Replace with WebSocket sending via ChatProvider
    print("Sending message (placeholder): $content");
    // final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    // final success = await chatProvider.sendMessage(widget.conversationId, content);

    // Simulate sending delay
    await Future.delayed(const Duration(seconds: 1));
    final success = true; // Placeholder success

    if (!mounted) return;

    if (success) {
      _messageController.clear();
      _scrollToBottom(); // Scroll after sending
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to send message.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
    setState(() {
      _isSending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.userId;

    // Find the conversation details from the provider's list
    final conversation = chatProvider.conversations.firstWhere(
      (c) => c.conversationId == widget.conversationId,
      orElse:
          () => Conversation(
            // Fallback if not found (shouldn't happen ideally)
            conversationId: widget.conversationId,
            participants: [],
          ),
    );
    final otherParticipant =
        currentUserId != null
            ? conversation.getOtherParticipant(currentUserId)
            : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(otherParticipant?.username ?? 'Chat'),
        // Optional: Add avatar
        // leading: Padding(
        //   padding: const EdgeInsets.all(8.0),
        //   child: CircleAvatar(
        //     backgroundImage: otherParticipant?.profilePictureUrl != null
        //         ? NetworkImage(otherParticipant!.profilePictureUrl!)
        //         : null,
        //     child: otherParticipant?.profilePictureUrl == null ? const Icon(Icons.person) : null,
        //   ),
        // ),
      ),
      body: Column(
        children: [
          // --- Message List ---
          Expanded(
            child: Consumer<ChatProvider>(
              // Use Consumer specifically for messages
              builder: (ctx, provider, _) {
                if (provider.isLoadingMessages &&
                    provider.currentMessages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.errorMessageMessages != null &&
                    provider.currentMessages.isEmpty) {
                  return Center(
                    child: Text('Error: ${provider.errorMessageMessages}'),
                  );
                }
                if (provider.currentMessages.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Start the conversation!'),
                  );
                }

                final messages = provider.currentMessages;
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: messages.length,
                  itemBuilder: (ctx, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;
                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),
          // --- Message Input Area ---
          _buildMessageInputArea(),
        ],
      ),
    );
  }

  // Widget to build individual message bubbles
  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75, // Max width 75%
        ),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).primaryColor : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12.0),
            topRight: const Radius.circular(12.0),
            bottomLeft: isMe ? const Radius.circular(12.0) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(12.0),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(color: isMe ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              // TODO: Format time nicely
              '${message.sentAt.toLocal().hour}:${message.sentAt.toLocal().minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.black54,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget for the text input field and send button
  Widget _buildMessageInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 10.0,
                ),
              ),
              minLines: 1,
              maxLines: 5, // Allow multiline input
              onSubmitted: (_) => _sendMessage(), // Send on keyboard submit
            ),
          ),
          const SizedBox(width: 8.0),
          _isSending
              ? const Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
              : IconButton(
                icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
                onPressed: _sendMessage,
              ),
        ],
      ),
    );
  }
}
