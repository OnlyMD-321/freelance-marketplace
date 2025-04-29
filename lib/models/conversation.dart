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

  // Need this getter for ChatProvider logic
  DateTime? get lastMessageAt => lastMessageTimestamp;

  // Helper to get the other participant's info (assuming 2 participants)
  UserInfo? getOtherParticipant(String currentUserId) {
    try {
      return participants.firstWhere((p) => p.userId != currentUserId);
    } catch (e) {
      // Handle cases with no other participant or only one participant (self-chat?)
      return participants.isNotEmpty
          ? participants
              .first // Return self if only one participant
          : UserInfo(userId: 'unknown', username: 'Unknown User'); // Fallback
    }
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    var participantsJson = json['participants'] as List<dynamic>? ?? [];
    List<UserInfo> participantsList =
        participantsJson.map((p) {
          final participantData =
              p is Map<String, dynamic> && p.containsKey('user')
                  ? p['user'] as Map<String, dynamic>
                  : p as Map<String, dynamic>;
          try {
            return UserInfo.fromJson(participantData);
          } catch (e) {
            print(
              "Error parsing participant in Conversation.fromJson: $e. Data: $participantData",
            );
            // Return a fallback UserInfo or rethrow, depending on desired robustness
            return UserInfo(userId: 'error', username: 'Error User');
          }
        }).toList();

    final lastMessageData = json['lastMessage'] as Map<String, dynamic>?;
    DateTime? lastTimestamp;
    if (lastMessageData?['sentAt'] != null) {
      try {
        // Attempt to parse the timestamp string
        lastTimestamp =
            DateTime.parse(lastMessageData!['sentAt'] as String).toLocal();
      } catch (e) {
        print(
          "Error parsing lastMessageTimestamp in Conversation.fromJson: $e. Value: ${lastMessageData!['sentAt']}",
        );
        // Handle parsing error, e.g., set to null or a default date
        lastTimestamp = null;
      }
    }

    return Conversation(
      conversationId: json['conversationId'] as String,
      participants: participantsList,
      lastMessage: lastMessageData?['content'] as String?,
      lastMessageTimestamp: lastTimestamp, // Use the parsed or null timestamp
      unreadCount: json['unreadCount'] as int? ?? 0,
      // Parse relatedJobId and relatedJobTitle if they exist in the JSON
      relatedJobId:
          json['jobId'] as String?, // Assuming backend sends jobId directly
      relatedJobTitle:
          json['job']?['title']
              as String?, // Assuming backend sends nested job object with title
    );
  }

  // Add copyWith method for easier state updates
  Conversation copyWith({
    String? conversationId,
    List<UserInfo>? participants,
    String? lastMessage,
    DateTime? lastMessageTimestamp,
    int? unreadCount,
    String? relatedJobId,
    String? relatedJobTitle,
  }) {
    return Conversation(
      conversationId: conversationId ?? this.conversationId,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
      unreadCount: unreadCount ?? this.unreadCount,
      relatedJobId: relatedJobId ?? this.relatedJobId,
      relatedJobTitle: relatedJobTitle ?? this.relatedJobTitle,
    );
  }

  // Optional: toJson method if needed
  Map<String, dynamic> toJson() {
    return {
      'conversationId': conversationId,
      'participants': participants.map((p) => p.toJson()).toList(),
      'relatedJobId': relatedJobId,
    };
  }
}
