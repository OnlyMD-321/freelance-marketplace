// filepath: Mobile/lib/providers/chat_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../models/conversation.dart';
import '../models/message.dart';
// Import WebSocket service later
// import '../services/websocket_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
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
  List<ChatMessage> get currentMessages => _selectedConversationId != null
      ? [...(_messages[_selectedConversationId] ?? [])]
      : [];
  String? get selectedConversationId => _selectedConversationId;
  bool get isLoadingConversations => _isLoadingConversations;
  bool get isLoadingMessages => _isLoadingMessages;
  String? get errorMessageConversations => _errorMessageConversations;
  String? get errorMessageMessages => _errorMessageMessages;

  ChatProvider() {
    // TODO: Initialize WebSocket connection and listeners
    // _initializeWebSocket();
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
         if (a.lastMessageTimestamp == null && b.lastMessageTimestamp == null) return 0;
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

  Future<void> fetchMessages(String conversationId, {bool loadMore = false}) async {
    // TODO: Implement pagination (cursor based on oldest message)
    if (_isLoadingMessages) return; // Prevent concurrent loading

    _isLoadingMessages = true;
    _errorMessageMessages = null;
    if (!loadMore) {
      _messages[conversationId] = []; // Clear existing messages on initial fetch
    }
    notifyListeners();

    try {
      final fetchedMessages = await _chatService.getMessages(conversationId);
      // Messages from service are oldest -> newest
      if (_messages[conversationId] == null) {
         _messages[conversationId] = [];
      }
      // Prepend older messages if implementing loadMore later
      _messages[conversationId]!.addAll(fetchedMessages);
      // Ensure messages are sorted by time (oldest first) - service should handle this
      _messages[conversationId]!.sort((a, b) => a.sentAt.compareTo(b.sentAt));

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
    if (_messages[conversationId] == null || _messages[conversationId]!.isEmpty) {
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
    final index = _conversations.indexWhere((c) => c.conversationId == conversationId);
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
    if (!_messages[conversationId]!.any((m) => m.messageId == message.messageId)) {
       _messages[conversationId]!.add(message);
       _messages[conversationId]!.sort((a, b) => a.sentAt.compareTo(b.sentAt));
       notifyListeners(); // Notify if the message belongs to the selected conversation
    }
  }

  // @override
  // void dispose() {
  //   _webSocketService.dispose(); // Disconnect WebSocket
  //   super.dispose();
  // }
}