import 'dart:async'; // For StreamController
import 'dart:convert'; // For jsonDecode
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../models/conversation.dart';
import '../models/message.dart';
import 'secure_storage_service.dart';
import '../utils/constants.dart'; // For apiBaseUrl
import 'package:http/http.dart' as http;

class ChatService {
  final SecureStorageService _storageService = SecureStorageService();
  io.Socket? _socket;

  // StreamController to broadcast received messages to the provider
  final StreamController<ChatMessage> _messageStreamController =
      StreamController.broadcast();
  Stream<ChatMessage> get messageStream => _messageStreamController.stream;
  // Callback setter for provider to listen
  set onMessageReceived(void Function(ChatMessage) callback) {
    // This is a simplified approach; a proper Stream/Subscription is better
    // For now, just directly assign the callback if needed by provider's current structure
    // OR the provider should subscribe to messageStream instead.
    // Let's assume provider subscribes to the stream for now.
  }

  // --- Connection Management ---
  Future<void> connect() async {
    if (_socket?.connected ?? false) {
      print("[ChatService] Socket already connected.");
      return;
    }

    final token = await _storageService.getToken();
    if (token == null) {
      print("[ChatService] Cannot connect: No token found.");
      return;
    }

    // Extract base URL for socket connection (remove /api/v1)
    final uri = Uri.parse(apiBaseUrl);
    final socketUrl =
        '${uri.scheme}://${uri.host}:${uri.port}'; // e.g., http://localhost:3000
    print("[ChatService] Connecting socket to $socketUrl");

    _socket = io.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'auth': {'token': token}, // Send token for authentication
    });

    _socket!.onConnect((_) {
      print('[ChatService] Socket connected: ${_socket!.id}');
      // TODO: Handle joining rooms, fetching initial state if needed after connection
    });

    _socket!.onDisconnect((reason) {
      print('[ChatService] Socket disconnected: $reason');
      // TODO: Implement reconnection logic if needed
    });

    _socket!.onConnectError((data) {
      print('[ChatService] Socket connection error: $data');
    });

    _socket!.onError((data) {
      print('[ChatService] Socket error: $data');
    });

    // Listen for incoming messages from server
    _socket!.on('receiveMessage', (data) {
      try {
        print("[ChatService] Received 'receiveMessage' event: $data");
        final messageData = data as Map<String, dynamic>;

        // Extract senderId from the nested sender object
        final senderInfo = messageData['sender'] as Map<String, dynamic>?;
        final senderId = senderInfo?['userId'] as String?;

        if (senderId == null) {
          print("[ChatService] Error: Received message missing senderId.");
          return; // Or handle the error appropriately
        }

        // Create a new map for ChatMessage.fromJson, ensuring all required fields exist
        final messageJson = {
          'messageId': messageData['messageId'] as String?,
          'conversationId': messageData['conversationId'] as String?,
          'senderId': senderId, // Use the extracted senderId
          'content': messageData['content'] as String?,
          'sentAt': messageData['sentAt'] as String?,
          'isRead': messageData['isRead'] as bool? ?? false,
        };

        // Basic validation to ensure required fields are not null
        if (messageJson['messageId'] == null ||
            messageJson['conversationId'] == null ||
            messageJson['content'] == null ||
            messageJson['sentAt'] == null) {
          print(
            "[ChatService] Error: Received message missing essential fields.",
          );
          return; // Or handle the error appropriately
        }

        // Now create the ChatMessage using the prepared JSON
        final message = ChatMessage.fromJson(
          messageJson.cast<String, dynamic>(),
        );
        _messageStreamController.add(message); // Add to stream for provider
      } catch (e, stackTrace) {
        print("[ChatService] Error parsing received message: $e");
        print(stackTrace);
      }
    });

    // Listen for general errors from server
    _socket!.on('error', (data) {
      print("[ChatService] Received 'error' event from server: $data");
      // TODO: Handle server-side errors (e.g., show snackbar via provider)
    });
  }

  void disconnect() {
    print("[ChatService] Disconnecting socket...");
    _socket?.dispose();
    _socket = null;
  }

  // --- HTTP API Calls (for existing conversations/messages) ---
  Future<List<Conversation>> listConversations() async {
    final url = Uri.parse('$apiBaseUrl/chat');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Conversation.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load conversations: ${response.statusCode}');
    }
  }

  Future<List<ChatMessage>> getMessages(String conversationId) async {
    final url = Uri.parse('$apiBaseUrl/chat/$conversationId/messages');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      // Decode the response body
      final dynamic decodedBody = jsonDecode(response.body);

      // Check if the body is a Map and contains a 'messages' key
      if (decodedBody is Map<String, dynamic> &&
          decodedBody.containsKey('messages') &&
          decodedBody['messages'] is List) {
        // Extract the list from the map
        final List<dynamic> messagesList = decodedBody['messages'] as List;
        return messagesList.map((json) => ChatMessage.fromJson(json)).toList();
      } else if (decodedBody is List) {
        // If it's already a list, process it directly (fallback)
        final List<dynamic> data = decodedBody;
        return data.map((json) => ChatMessage.fromJson(json)).toList();
      } else {
        // If the structure is unexpected, throw an error
        throw Exception(
          'Failed to load messages: Unexpected response format. Expected List or {"messages": List}.',
        );
      }
    } else {
      // Include response body in error for more context
      throw Exception(
        'Failed to load messages: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> markAsRead(String conversationId) async {
    final url = Uri.parse('$apiBaseUrl/chat/$conversationId/read');
    final headers = await _getHeaders();
    try {
      await http.post(url, headers: headers);
      // Handle potential errors if needed, though often fire-and-forget
    } catch (e) {
      print(
        "[ChatService] Error marking conversation $conversationId as read: $e",
      );
    }
  }

  // --- Socket.IO Actions ---

  Future<Map<String, dynamic>> getOrCreateConversation({
    required String recipientId,
    String? jobId,
    String? applicationId,
  }) async {
    if (_socket == null || !_socket!.connected) {
      throw Exception("Socket not connected");
    }
    final completer = Completer<Map<String, dynamic>>();
    const timeoutDuration = Duration(seconds: 10); // Add a timeout duration

    print(
      "[ChatService] Emitting 'findOrCreateConversation' for recipient $recipientId",
    );
    // Emit a specific event for finding/creating a conversation *without* sending a message content
    _socket!.emitWithAck(
      'findOrCreateConversation', // <-- Changed event name
      {
        'recipientId': recipientId,
        'jobId': jobId,
        'applicationId': applicationId,
      },
      ack: (response) {
        print(
          "[ChatService] Ack received for findOrCreateConversation: $response",
        );
        if (completer.isCompleted) return; // Avoid completing multiple times

        if (response != null && response is Map<String, dynamic>) {
          // Expecting backend to return { status: 'ok', conversationId: '...' }
          if (response['status'] == 'ok' &&
              response['conversationId'] != null) {
            completer.complete({
              'conversationId': response['conversationId'],
              'message': 'Conversation ready',
            });
          } else {
            completer.completeError(
              Exception(
                response['message'] ?? 'Failed to get/create conversation',
              ),
            );
          }
        } else {
          completer.completeError(
            Exception(
              'Invalid response from server for findOrCreateConversation',
            ),
          );
        }
      },
    );

    // Add timeout for the completer
    return completer.future.timeout(
      timeoutDuration,
      onTimeout: () {
        print(
          "[ChatService] Timeout waiting for findOrCreateConversation ack.",
        ); // Log timeout
        // Ensure completer is completed with an error on timeout
        if (!completer.isCompleted) {
          completer.completeError(
            TimeoutException(
              'Server did not respond in time.',
              timeoutDuration,
            ),
          );
        }
        // The timeout function expects a return value of the future's type,
        // but since we complete the completer with an error, this path might not be strictly necessary
        // depending on how timeout handles already completed futures.
        // To be safe, return a Map indicating timeout, although the error is preferred.
        return {
          'conversationId': null,
          'message': 'Timeout waiting for server response.',
        };
        // Alternatively, rethrow the TimeoutException if the Future type allows nulls or specific error handling
        // throw TimeoutException('Server did not respond in time.', timeoutDuration);
      },
    );
  }

  Future<void> sendMessage({
    required String conversationId,
    required String recipientId,
    required String content,
  }) async {
    if (_socket == null || !_socket!.connected) {
      throw Exception("Socket not connected");
    }
    // Now we have recipientId, proceed with emit
    print(
      "[ChatService] Emitting 'sendMessage' for conversation $conversationId to $recipientId",
    );
    _socket!.emitWithAck(
      'sendMessage',
      {
        'recipientId': recipientId,
        'content': content,
        // Send conversationId too? Backend might ignore it but could be useful for context
        'conversationId': conversationId,
      },
      ack: (response) {
        print("[ChatService] Ack received for sendMessage: $response");
        if (response is Map<String, dynamic> && response['status'] != 'ok') {
          print("[ChatService] Error sending message: ${response['message']}");
          // Throw an exception to be caught by the provider
          throw Exception(
            "Failed to send message: ${response['message'] ?? 'Unknown error'}",
          );
        } else if (response == null || response is! Map<String, dynamic>) {
          print("[ChatService] Invalid ack response type for sendMessage");
          throw Exception(
            "Invalid response from server after sending message.",
          );
        }
        // Success case, do nothing here, message will arrive via 'receiveMessage' listener
      },
    );
  }

  void joinRoom(String conversationId) {
    if (_socket?.connected ?? false) {
      print("[ChatService] Emitting 'joinRoom' for $conversationId");
      _socket!.emit('joinRoom', conversationId);
    }
  }

  void leaveRoom(String conversationId) {
    if (_socket?.connected ?? false) {
      print("[ChatService] Emitting 'leaveRoom' for $conversationId");
      _socket!.emit('leaveRoom', conversationId);
    }
  }

  // --- Helper Methods ---
  Future<Map<String, String>> _getHeaders() async {
    final token = await _storageService.getToken();
    // Should not happen if connect() succeeded, but check anyway
    if (token == null) throw Exception('Auth token not found');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
}
