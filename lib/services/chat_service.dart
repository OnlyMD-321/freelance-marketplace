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
  bool _isConnecting = false; // <-- Add connection state flag
  Completer<void>? _connectionCompleter; // <-- Store active completer

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
    // Use the existing completer if a connection is already in progress
    if (_isConnecting && _connectionCompleter != null) {
      print(
        "[ChatService Connect] Connection already in progress. Returning existing future.",
      );
      return _connectionCompleter!.future;
    }

    // If socket exists and is connected, complete immediately
    if (_socket?.connected ?? false) {
      print("[ChatService Connect] Socket already connected. Returning.");
      return Future.value(); // Return a completed future
    }

    // Start new connection process
    print("[ChatService Connect] Starting new connection process.");
    _isConnecting = true;
    _connectionCompleter = Completer<void>();

    // --- Clean up existing disconnected socket instance if necessary --- START
    if (_socket != null && !_socket!.connected) {
      print(
        "[ChatService Connect] Found existing disconnected socket. Disposing it first.",
      );
      _socket!.dispose();
      _socket = null;
    }
    // --- Clean up existing disconnected socket instance if necessary --- END

    print("[ChatService Connect] Attempting to get token...");
    final token = await _storageService.getToken();
    if (token == null) {
      print("[ChatService Connect] No token found. Completing with error.");
      _isConnecting = false;
      if (!_connectionCompleter!.isCompleted) {
        _connectionCompleter!.completeError(Exception("No token found"));
      }
      return _connectionCompleter!.future;
    }
    print("[ChatService Connect] Token found.");

    final uri = Uri.parse(apiBaseUrl);
    final socketUrl = '${uri.scheme}://${uri.host}:${uri.port}';
    print("[ChatService Connect] Connecting socket to $socketUrl");

    try {
      print("[ChatService Connect] Calling io.io()...");
      _socket = io.io(socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'forceNew': true, // Consider forcing a new connection if issues persist
        'auth': {'token': token},
      });
      print("[ChatService Connect] io.io() called. Setting up listeners...");

      // --- Listeners ---
      _socket!.onConnect((_) {
        print('[ChatService Connect] Event: onConnect ${_socket!.id}');
        _isConnecting = false;
        if (!_connectionCompleter!.isCompleted) {
          print("[ChatService Connect] Completing future successfully.");
          _connectionCompleter!.complete();
        } else {
          print(
            "[ChatService Connect] Event: onConnect - completer already completed.",
          );
        }
      });

      _socket!.onDisconnect((reason) {
        print('[ChatService Connect] Event: onDisconnect. Reason: $reason');
        _isConnecting = false; // Reset flag on disconnect
        // Don't complete completer here, let connect attempts handle errors
      });

      _socket!.onConnectError((data) {
        print('[ChatService Connect] Event: onConnectError. Data: $data');
        _isConnecting = false;
        if (!_connectionCompleter!.isCompleted) {
          print("[ChatService Connect] Completing future with connect error.");
          _connectionCompleter!.completeError(data ?? 'Connection Error');
        } else {
          print(
            "[ChatService Connect] Event: onConnectError - completer already completed.",
          );
        }
      });

      _socket!.onError((data) {
        print('[ChatService Connect] Event: onError. Data: $data');
        // Potentially flag an error state, but don't complete the connection completer
      });

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

      _socket!.on('error', (data) {
        print("[ChatService] Received 'error' event from server: $data");
        // TODO: Handle server-side errors (e.g., show snackbar via provider)
      });
      // --- End Listeners ---

      print("[ChatService Connect] Listeners set up.");
    } catch (e) {
      print("[ChatService Connect] Error during io.io() or listener setup: $e");
      _isConnecting = false;
      if (!_connectionCompleter!.isCompleted) {
        _connectionCompleter!.completeError(e);
      }
    }

    print("[ChatService Connect] Returning completer future with timeout.");
    return _connectionCompleter!.future.timeout(
      const Duration(seconds: 15), // Slightly increased timeout
      onTimeout: () {
        print("[ChatService Connect] Connection attempt timed out.");
        _isConnecting = false;
        if (!_connectionCompleter!.isCompleted) {
          _connectionCompleter!.completeError(
            TimeoutException("Socket connection attempt timed out"),
          );
        }
        // Clean up socket instance on timeout?
        _socket?.dispose();
        _socket = null;
        // Rethrow the timeout exception as per Completer's expectation
        throw TimeoutException("Socket connection attempt timed out");
      },
    );
  }

  void disconnect() {
    print("[ChatService] Disconnecting socket...");
    _isConnecting = false; // Ensure flag is reset
    _connectionCompleter = null; // Clear completer
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
    // --- Start: Connection Check and Attempt ---
    if (!(_socket?.connected ?? false)) {
      print(
        "[ChatService - getOrCreate] Socket not connected. Attempting connection...",
      );
      try {
        // Attempt to connect and wait for it to complete
        await connect();
        // Check connection status *after* attempting to connect
        if (!(_socket?.connected ?? false)) {
          print(
            "[ChatService - getOrCreate] Connection attempt failed or timed out.",
          );
          throw Exception("Failed to establish socket connection for chat.");
        }
        print("[ChatService - getOrCreate] Connection successful.");
      } catch (e) {
        print(
          "[ChatService - getOrCreate] Error during connection attempt: $e",
        );
        throw Exception("Failed to establish socket connection for chat: $e");
      }
    }
    // --- End: Connection Check and Attempt ---

    // Original logic proceeds only if connection is now established
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
