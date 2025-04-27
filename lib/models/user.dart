// filepath: Mobile/lib/models/user.dart
enum UserType { client, worker }

// --- UserInfo Class (Simplified User representation) ---
class UserInfo {
  final String userId;
  final String username;
  final String? profilePictureUrl; // Optional profile picture

  UserInfo({
    required this.userId,
    required this.username,
    this.profilePictureUrl,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userId: json['userId'] as String,
      username: json['username'] as String,
      profilePictureUrl: json['profilePictureUrl'] as String?,
    );
  }

  // --- Add the missing toJson method ---
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'profilePictureUrl': profilePictureUrl,
    };
  }
}

// --- Full User Class ---
class User extends UserInfo {
  // User can extend UserInfo
  final String email;
  final UserType userType;
  final DateTime createdAt;
  // Add other user-specific fields if needed

  User({
    required super.userId,
    required super.username,
    required this.email,
    required this.userType,
    super.profilePictureUrl,
    required this.createdAt,
  }); // Call super constructor

  factory User.fromJson(Map<String, dynamic> json) {
    // Helper to parse UserType from String
    UserType parseUserType(String? typeStr) {
      if (typeStr?.toLowerCase() == 'client') {
        return UserType.client;
      } else if (typeStr?.toLowerCase() == 'worker') {
        return UserType.worker;
      }
      // Default or throw error if type is unexpected/missing
      print(
        'Warning: Unknown or missing userType "$typeStr", defaulting to client.',
      );
      return UserType.client; // Or throw an exception
    }

    return User(
      userId: json['userId'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      userType: parseUserType(json['userType'] as String?),
      profilePictureUrl: json['profilePictureUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  // Override toJson if User has additional fields
  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson(); // Get UserInfo fields
    json.addAll({
      // Add User specific fields
      'email': email,
      'userType': userType.name, // Convert enum to string
      'createdAt': createdAt.toIso8601String(),
    });
    return json;
  }
}
