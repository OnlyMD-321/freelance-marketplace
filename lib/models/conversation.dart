// filepath: Mobile/lib/models/conversation.dart
import 'user.dart'; // Assuming UserInfo holds basic user details

class Conversation {
  final String conversationId;
  final List<UserInfo> participants; // List of users in the conversation
  final String? lastMessage; // Preview of the last message
  final DateTime? lastMessageTimestamp; // Timestamp of the last message
  final int unreadCount; // Number of unread messages for the current user

  // Optional: Link to related job if applicable
  final String? relatedJobId;
  final String? relatedJobTitle;

  Conversation({
    required this.conversationId,
    required this.participants,
    this.lastMessage,
    this.lastMessageTimestamp,
    this.unreadCount = 0,
    this.relatedJobId,
    this.relatedJobTitle,
  });

  // Helper to get the other participant's info (assuming 2 participants)
  UserInfo? getOtherParticipant(String currentUserId) {
    return participants.firstWhere(
      (p) => p.userId != currentUserId,
      orElse:
          () =>
              participants.isNotEmpty
                  ? participants.first
                  : UserInfo(
                    userId: 'unknown',
                    username: 'Unknown User',
                  ), // Fallback
    );
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    var participantsJson = json['participants'] as List<dynamic>? ?? [];
    List<UserInfo> participantsList =
        participantsJson
            .map((p) => UserInfo.fromJson(p as Map<String, dynamic>))
            .toList();

    return Conversation(
      conversationId: json['conversationId'] as String,
      participants: participantsList,
      lastMessage: json['lastMessage'] as String?,
      lastMessageTimestamp:
          json['lastMessageTimestamp'] == null
              ? null
              : DateTime.parse(json['lastMessageTimestamp'] as String),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      // Assuming job info might be nested or directly available
      relatedJobId:
          json['relatedJob']?['jobId'] as String? ??
          json['relatedJobId'] as String?,
      relatedJobTitle:
          json['relatedJob']?['title'] as String? ??
          json['relatedJobTitle'] as String?,
    );
  }

  // Optional: toJson method if needed
  Map<String, dynamic> toJson() {
    return {
      'conversationId': conversationId,
      'participants': participants.map((p) => p.toJson()).toList(),
      'lastMessage': lastMessage,
      'lastMessageTimestamp': lastMessageTimestamp?.toIso8601String(),
      'unreadCount': unreadCount,
      'relatedJobId': relatedJobId,
      'relatedJobTitle': relatedJobTitle,
    };
  }
}
