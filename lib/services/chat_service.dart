import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart'; // Import the base URL
import '../models/conversation.dart';
import '../models/message.dart';
import 'secure_storage_service.dart'; // To get the token

class ChatService {
  final SecureStorageService _storageService = SecureStorageService();
  final String _chatUrl = '$apiBaseUrl/chat'; // Base URL for chat endpoints

  // Helper to get authenticated headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await _storageService.getToken();
    if (token == null) {
      throw Exception('Authentication token not found.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // List User's Conversations
  Future<List<Conversation>> listConversations() async {
    final url = Uri.parse(_chatUrl);
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body);
        return responseData.map((json) => Conversation.fromJson(json)).toList();
      } else {
        print('Failed to list conversations: ${response.statusCode} ${response.body}');
        throw Exception('Failed to list conversations.');
      }
    } catch (error) {
      print('Error listing conversations: $error');
      rethrow;
    }
  }

  // Get Messages for a Conversation
  Future<List<ChatMessage>> getMessages(String conversationId, {String? cursor, int limit = 30}) async {
    final queryParams = {
      'limit': limit.toString(),
      if (cursor != null) 'cursor': cursor,
    };
    final url = Uri.parse('$_chatUrl/$conversationId/messages').replace(queryParameters: queryParams);

    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // Assuming API returns { messages: [...], pagination: {...} }
        final List<dynamic> messageListJson = responseData['messages'];
        // Note: API returns newest first, but we might want oldest first in UI
        // The backend handler already reverses them, so they should be oldest -> newest
        return messageListJson.map((json) => ChatMessage.fromJson(json)).toList();
      } else {
        print('Failed to get messages: ${response.statusCode} ${response.body}');
        throw Exception('Failed to get messages.');
      }
    } catch (error) {
      print('Error getting messages: $error');
      rethrow;
    }
  }

  // Mark Conversation as Read
  Future<bool> markAsRead(String conversationId) async {
    final url = Uri.parse('$_chatUrl/$conversationId/read');
    try {
      final headers = await _getHeaders();
      final response = await http.post(url, headers: headers); // No body needed

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to mark as read: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (error) {
      print('Error marking as read: $error');
      return false;
    }
  }

  // Send Message (HTTP Fallback - WebSocket is preferred for real-time)
  // Note: The backend currently doesn't have an HTTP POST route for sending messages.
  // This function is a placeholder if you decide to add one.
  // Real-time sending will be handled via WebSocket connection later.
  Future<ChatMessage?> sendMessageHttp({
    required String conversationId,
    required String content,
    // required String recipientId, // Might be needed depending on backend route design
  }) async {
    // final url = Uri.parse('$_chatUrl'); // Or a specific send endpoint
    // try {
    //   final headers = await _getHeaders();
    //   final body = jsonEncode({
    //     'conversationId': conversationId, // Or recipientId
    //     'content': content,
    //   });
    //   final response = await http.post(url, headers: headers, body: body);
    //   if (response.statusCode == 201) {
    //     return ChatMessage.fromJson(jsonDecode(response.body));
    //   } else {
    //     print('Failed to send message via HTTP: ${response.statusCode} ${response.body}');
    //     throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to send message.');
    //   }
    // } catch (error) {
    //   print('Error sending message via HTTP: $error');
    //   rethrow;
    // }
    print("Warning: sendMessageHttp is a placeholder. Use WebSocket for sending.");
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate delay
    // Return a dummy message or null/throw error
    return null; // Indicate not implemented or failed
  }
}