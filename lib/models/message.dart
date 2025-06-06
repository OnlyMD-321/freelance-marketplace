// filepath: Mobile/lib/models/chat_message.dart
class ChatMessage {
  final String messageId;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime sentAt;
  final bool
  isRead; // Indicates if the message has been read by the recipient(s)

  ChatMessage({
    required this.messageId,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.sentAt,
    this.isRead = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: json['messageId'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
      isRead:
          json['isRead'] as bool? ?? false, // Default to false if not provided
    );
  }

  // Optional: toJson method if needed (e.g., for sending messages)
  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId, // Usually generated by backend
      'conversationId': conversationId,
      'senderId': senderId, // Usually set by backend based on auth
      'content': content,
      'sentAt': sentAt.toIso8601String(), // Usually set by backend
      'isRead': isRead,
    };
  }

  // For sending new messages, you might only need content and conversationId
  Map<String, dynamic> toJsonForSending() {
    return {'conversationId': conversationId, 'content': content};
  }
}
