// filepath: Mobile/lib/providers/chat_provider.dart
import 'dart:async';
import 'dart:math'; // For random number
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/user.dart'; // For UserInfo
import '../screens/chat/chat_screen.dart'; // Import ChatScreen
import 'auth_provider.dart'; // Import AuthProvider
// Import WebSocket service later
// import '../services/websocket_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  final AuthProvider authProvider; // Needs AuthProvider for current user ID
  StreamSubscription<ChatMessage>? _messageSubscription; // Store subscription
  // TODO: Integrate WebSocketService
  // final WebSocketService _webSocketService = WebSocketService();

  List<Conversation> _conversations = [];
  // Store messages per conversation ID
  final Map<String, List<ChatMessage>> _messages = {};
  String? _selectedConversationId;

  bool _isLoadingConversations = false;
  bool _isLoadingMessages = false;
  String? _errorMessageConversations;
  String? _errorMessageMessages;

  // --- Getters ---
  List<Conversation> get conversations => [..._conversations];
  // Method to get messages for a specific conversation ID
  List<ChatMessage> messagesForConversation(String conversationId) => [
    ...(_messages[conversationId] ?? []),
  ];
  // Getter for currently selected conversation's messages (if needed)
  List<ChatMessage> get currentMessages =>
      _selectedConversationId != null
          ? messagesForConversation(_selectedConversationId!)
          : [];
  String? get selectedConversationId => _selectedConversationId;
  bool get isLoadingConversations => _isLoadingConversations;
  bool get isLoadingMessages => _isLoadingMessages;
  // Use specific error messages
  String? get errorMessageConversations => _errorMessageConversations;
  String? get errorMessageMessages => _errorMessageMessages;

  ChatProvider(this.authProvider) {
    _initializeChatService();
  }

  void _initializeChatService() async {
    print(
      "[ChatProvider] Initializing Chat Service and subscribing to messages...",
    );
    // Subscribe to the message stream from the service
    _messageSubscription = _chatService.messageStream.listen(
      (message) {
        // This is called whenever a new message is added to the stream
        print(
          "[ChatProvider] Received message via stream for convo: ${message.conversationId}",
        );
        _handleIncomingMessage(message);
      },
      onError: (error) {
        print("[ChatProvider] Error in message stream: $error");
        // Handle stream errors if necessary
      },
      onDone: () {
        print("[ChatProvider] Message stream closed.");
        // Handle stream closure if necessary
      },
    );

    // Connect the socket
    await _chatService.connect();
  }

  @override
  void dispose() {
    print("[ChatProvider] Disposing and cancelling message subscription.");
    _messageSubscription
        ?.cancel(); // Cancel subscription when provider is disposed
    _chatService.disconnect(); // Disconnect socket
    super.dispose();
  }

  void _handleIncomingMessage(ChatMessage message) {
    final convoId = message.conversationId;
    bool messageListChanged = false;
    bool conversationListChanged = false;

    // --- 1. Update Message List for the specific conversation ---
    if (_messages.containsKey(convoId)) {
      final tempMessageIndex = _messages[convoId]!.indexWhere(
        (m) => m.messageId.startsWith('temp_') && m.content == message.content,
      );

      if (tempMessageIndex != -1) {
        _messages[convoId]![tempMessageIndex] = message;
        print(
          "[ChatProvider] Replaced temp message with actual ${message.messageId}",
        );
        messageListChanged = true;
      } else if (!(_messages[convoId]?.any(
            (m) => m.messageId == message.messageId,
          ) ??
          false)) {
        _messages[convoId]!.add(message);
        print("[ChatProvider] Added non-temp message ${message.messageId}");
        messageListChanged = true;
      }

      if (messageListChanged) {
        _messages[convoId]!.sort((a, b) => a.sentAt.compareTo(b.sentAt));
        print("[ChatProvider] Sorted messages for $convoId (Oldest first).");
      }
    } else {
      print(
        "[ChatProvider] Received message for convo $convoId, but messages not currently loaded in map.",
      );
      // Optionally add the message even if the list wasn't loaded
      // _messages[convoId] = [message];
      // messageListChanged = true; // If you add it
    }

    // --- 2. Update Conversation Preview List ---
    final index = _conversations.indexWhere((c) => c.conversationId == convoId);
    if (index != -1) {
      final currentConversation = _conversations[index];
      // Check if the incoming message is newer than the current preview
      if (message.sentAt.isAfter(
        currentConversation.lastMessageTimestamp ?? DateTime(0),
      )) {
        final bool shouldIncrementUnread = convoId != _selectedConversationId;
        final updatedConversation = currentConversation.copyWith(
          lastMessage: message.content, // Update content
          lastMessageTimestamp: message.sentAt, // Update timestamp
          unreadCount:
              shouldIncrementUnread
                  ? (currentConversation.unreadCount + 1)
                  : currentConversation.unreadCount,
        );
        _conversations[index] = updatedConversation;
        _conversations.sort(
          (a, b) => (b.lastMessageTimestamp ?? DateTime(0)).compareTo(
            a.lastMessageTimestamp ?? DateTime(0),
          ),
        );
        conversationListChanged = true;
        print("[ChatProvider] Updated conversation list preview for $convoId");
      } else {
        print(
          "[ChatProvider] Received older/same timestamp message for convo $convoId, not updating preview.",
        );
      }
    } else {
      print(
        "[ChatProvider] Received message for convo $convoId not in list. Consider refreshing list view.",
      );
      // Optionally trigger fetchConversations() later or add a placeholder conversation
    }

    // --- 3. Notify Listeners ---
    if (messageListChanged || conversationListChanged) {
      print("[ChatProvider] Notifying listeners due to incoming message.");
      notifyListeners();
    }
  }

  // --- Fetching Data ---
  Future<void> fetchConversations() async {
    _isLoadingConversations = true;
    _errorMessageConversations = null;
    notifyListeners();

    try {
      _conversations = await _chatService.listConversations();
      // Sort conversations by last message timestamp (newest first)
      _conversations.sort((a, b) {
        if (a.lastMessageTimestamp == null && b.lastMessageTimestamp == null)
          return 0;
        if (a.lastMessageTimestamp == null) return 1; // Put nulls last
        if (b.lastMessageTimestamp == null) return -1;
        return b.lastMessageTimestamp!.compareTo(a.lastMessageTimestamp!);
      });
    } catch (error) {
      _errorMessageConversations = "Failed to fetch conversations: $error";
      _conversations = [];
    } finally {
      _isLoadingConversations = false;
      notifyListeners();
    }
  }

  Future<void> fetchMessages(
    String conversationId, {
    bool loadMore = false,
  }) async {
    // TODO: Implement pagination (cursor based on oldest message)
    if (_isLoadingMessages) return; // Prevent concurrent loading

    _isLoadingMessages = true;
    _errorMessageMessages = null;
    if (!loadMore) {
      _messages[conversationId] =
          []; // Clear existing messages on initial fetch
    }
    notifyListeners();

    try {
      final fetchedMessages = await _chatService.getMessages(conversationId);
      if (_messages[conversationId] == null) {
        _messages[conversationId] = [];
      }
      _messages[conversationId]!.addAll(fetchedMessages);
      // Sort messages: Oldest first
      _messages[conversationId]!.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      print(
        "[ChatProvider] Fetched and sorted messages for $conversationId (Oldest first)",
      );
    } catch (error) {
      _errorMessageMessages = "Failed to fetch messages: $error";
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  // --- State Management ---
  void selectConversation(String conversationId) {
    if (_selectedConversationId == conversationId) return; // No change

    _selectedConversationId = conversationId;
    _errorMessageMessages = null; // Clear previous errors
    notifyListeners();

    // Fetch messages for the selected conversation if not already loaded
    if (_messages[conversationId] == null ||
        _messages[conversationId]!.isEmpty) {
      fetchMessages(conversationId);
    }
    // Mark as read (can be done optimistically or after fetch)
    markAsRead(conversationId);
  }

  void clearSelectedConversation() {
    _selectedConversationId = null;
    // Optionally clear messages map for memory management, or keep cache
    // _messages.remove(_selectedConversationId);
    notifyListeners();
  }

  // --- Actions ---
  Future<void> markAsRead(String conversationId) async {
    final index = _conversations.indexWhere(
      (c) => c.conversationId == conversationId,
    );
    if (index != -1 && _conversations[index].unreadCount > 0) {
      // Optimistically update UI
      // Create a new instance to ensure change notification works
      final oldConversation = _conversations[index];
      _conversations[index] = Conversation(
        conversationId: oldConversation.conversationId,
        participants: oldConversation.participants,
        lastMessage: oldConversation.lastMessage,
        lastMessageTimestamp: oldConversation.lastMessageTimestamp,
        unreadCount: 0, // Set unread count to 0
        relatedJobId: oldConversation.relatedJobId,
        relatedJobTitle: oldConversation.relatedJobTitle,
      );
      notifyListeners();

      // Call the service
      await _chatService.markAsRead(conversationId);
      // No need to refetch/notify again unless the API call fails and needs rollback
    }
  }

  // --- WebSocket Integration (Placeholders) ---

  // void _initializeWebSocket() {
  //   _webSocketService.connect();
  //   _webSocketService.messages.listen((message) {
  //     _handleIncomingMessage(message);
  //   });
  //   // Listen for other events like conversation updates, errors etc.
  // }

  // Future<void> sendMessage(String conversationId, String content) async {
  //   // Optimistically add message to UI?
  //   // final tempMessage = ChatMessage(...);
  //   // addMessage(tempMessage);

  //   _webSocketService.sendMessage(conversationId, content);
  //   // Handle potential errors from WebSocket send
  // }

  // void _handleIncomingMessage(ChatMessage message) {
  //   addMessage(message);
  //   // Update conversation list preview?
  //   final index = _conversations.indexWhere((c) => c.conversationId == message.conversationId);
  //   if (index != -1) {
  //      // Update last message, timestamp, unread count etc.
  //      // ... complex logic to update Conversation object ...
  //      notifyListeners();
  //   } else {
  //      // New conversation? Fetch conversation list again?
  //      fetchConversations();
  //   }
  // }

  // Add a message to the local state (used by WebSocket handler)
  void addMessage(ChatMessage message) {
    final conversationId = message.conversationId;
    if (_messages[conversationId] == null) {
      _messages[conversationId] = [];
    }
    // Avoid adding duplicates if received via HTTP and WebSocket
    if (!_messages[conversationId]!.any(
      (m) => m.messageId == message.messageId,
    )) {
      _messages[conversationId]!.add(message);
      _messages[conversationId]!.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      notifyListeners(); // Notify if the message belongs to the selected conversation
    }
  }

  // --- New Method for Initiating Chat ---
  // Renamed from startConversationAndNavigate
  Future<String?> getOrCreateConversationId({
    // Return Future<String?>
    // REMOVED BuildContext context
    required String recipientId,
    required String recipientUsername, // Still useful for logging maybe
    String? jobId,
    String? applicationId,
  }) async {
    print(
      "[ChatProvider] Getting/Creating conversation with $recipientId (Username: $recipientUsername)",
    );

    try {
      // Call service to get/create conversation via Socket.IO
      final result = await _chatService.getOrCreateConversation(
        recipientId: recipientId,
        jobId: jobId,
        applicationId: applicationId,
      );

      final conversationId = result['conversationId'] as String?;

      if (conversationId != null) {
        print("[ChatProvider] Conversation ready: $conversationId.");
        return conversationId; // Return the ID
      } else {
        // Throw error with message from service
        throw Exception(result['message'] ?? "Failed to start conversation.");
      }
    } catch (error) {
      print("[ChatProvider] Error getting/creating conversation: $error");
      // Rethrow the error to be caught by the calling widget
      rethrow;
    }
  }

  // Implement sendMessage with Optimistic Update
  Future<void> sendMessage({
    required String conversationId,
    required String recipientId,
    required String content,
  }) async {
    if (content.trim().isEmpty) return;
    final String currentUserId =
        authProvider.currentUser!.userId; // Get current user ID

    // 1. Create Optimistic Message
    final tempId =
        'temp_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
    final optimisticMessage = ChatMessage(
      messageId: tempId,
      conversationId: conversationId,
      senderId: currentUserId, // Use actual sender ID
      content: content.trim(),
      sentAt: DateTime.now().toUtc(), // Use UTC time for consistency
      isRead: false, // Assume unread initially
    );

    // 2. Add Optimistic Message to State & Notify
    if (_messages[conversationId] == null) {
      _messages[conversationId] = [];
    }
    _messages[conversationId]!.add(optimisticMessage);
    _messages[conversationId]!.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    print("[ChatProvider] Optimistically added message $tempId");

    // --- Optimistically update conversation preview ---
    final index = _conversations.indexWhere(
      (c) => c.conversationId == conversationId,
    );
    if (index != -1) {
      _conversations[index] = _conversations[index].copyWith(
        lastMessage: optimisticMessage.content,
        lastMessageTimestamp: optimisticMessage.sentAt,
        // Don't change unread count when sending
      );
      // Re-sort conversation list
      _conversations.sort(
        (a, b) => (b.lastMessageTimestamp ?? DateTime(0)).compareTo(
          a.lastMessageTimestamp ?? DateTime(0),
        ),
      );
      print(
        "[ChatProvider] Optimistically updated conversation preview for $conversationId",
      );
    }
    // --- End optimistic preview update ---

    notifyListeners(); // Update UI immediately

    // 3. Send Actual Message via Service
    print(
      "[ChatProvider] Attempting to send message via service to $recipientId...",
    );
    try {
      await _chatService.sendMessage(
        conversationId: conversationId,
        recipientId: recipientId,
        content: content.trim(),
      );
      print(
        "[ChatProvider] sendMessage call to service succeeded for temp ID $tempId.",
      );
      // Actual message replaces temp via _handleIncomingMessage
    } catch (error) {
      print("[ChatProvider] Error sending message: $error for temp ID $tempId");
      // Remove optimistic message if sending failed
      _messages[conversationId]?.removeWhere((m) => m.messageId == tempId);
      _messages[conversationId]?.sort((a, b) => a.sentAt.compareTo(b.sentAt));

      // --- Revert optimistic conversation preview ---
      // This is tricky. We need to find the *previous* last message.
      // Easiest might be to refetch the specific conversation or the whole list,
      // or find the new latest message in the _messages map.
      // For simplicity, let's just remove the optimistic one and let the list be potentially stale until next fetch/message.
      if (index != -1) {
        // Find the latest message remaining in the map for this convo
        final remainingMessages = _messages[conversationId] ?? [];
        final newLastMessage =
            remainingMessages.isNotEmpty ? remainingMessages.last : null;
        _conversations[index] = _conversations[index].copyWith(
          lastMessage: newLastMessage?.content,
          lastMessageTimestamp: newLastMessage?.sentAt,
        );
        _conversations.sort(
          (a, b) => (b.lastMessageTimestamp ?? DateTime(0)).compareTo(
            a.lastMessageTimestamp ?? DateTime(0),
          ),
        );
        print(
          "[ChatProvider] Reverted optimistic conversation preview for $conversationId",
        );
      }
      // --- End revert ---

      notifyListeners(); // Update UI to remove the failed message & revert preview
      throw error; // Rethrow to be caught by the UI
    }
  }
}
