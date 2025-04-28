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
    final Map<String, dynamic> userData =
        json.containsKey('user') && json['user'] is Map<String, dynamic>
            ? json['user'] as Map<String, dynamic>
            : json;

    // Check for userId, log error if missing, but provide a default to avoid crash
    if (userData['userId'] == null) {
      print("Error parsing UserInfo: Missing userId. JSON: $json");
      // Provide a default/fallback value instead of throwing immediately
      // This helps prevent crashes but indicates a data issue from the backend.
      return UserInfo(
        userId:
            'missing_userid_${DateTime.now().millisecondsSinceEpoch}', // Unique placeholder
        username: userData['username'] as String? ?? 'Unknown User',
        profilePictureUrl: userData['profilePictureUrl'] as String?,
      );
    }

    return UserInfo(
      userId: userData['userId'] as String,
      username: userData['username'] as String? ?? 'Unknown',
      profilePictureUrl: userData['profilePictureUrl'] as String?,
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
  final String? phoneNumber; // Added
  final String? country; // Added
  final String? city; // Added
  final String? bio; // Added (Worker specific)
  final String? skillsSummary; // Added (Worker specific)
  // Add other fields like emailVerified, isActive, lastLogin if needed by UI

  User({
    required super.userId,
    required super.username,
    required this.email,
    required this.userType,
    super.profilePictureUrl,
    required this.createdAt,
    this.phoneNumber, // Added
    this.country, // Added
    this.city, // Added
    this.bio, // Added
    this.skillsSummary, // Added
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

    // Ensure required fields exist before parsing
    if (json['userId'] == null ||
        json['username'] == null ||
        json['email'] == null ||
        json['userType'] == null ||
        json['createdAt'] == null) {
      print("Error parsing User: Missing required field(s). JSON: $json");
      throw FormatException("Missing required field(s) in User data.");
    }

    return User(
      userId: json['userId'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      userType: parseUserType(json['userType'] as String?),
      profilePictureUrl: json['profilePictureUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      // Parse the newly added fields
      phoneNumber: json['phoneNumber'] as String?,
      country: json['country'] as String?,
      city: json['city'] as String?,
      bio: json['bio'] as String?,
      skillsSummary: json['skillsSummary'] as String?,
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
      // Add new fields to toJson
      'phoneNumber': phoneNumber,
      'country': country,
      'city': city,
      'bio': bio,
      'skillsSummary': skillsSummary,
    });
    // Remove null values before sending if backend expects only non-null fields
    json.removeWhere((key, value) => value == null);
    return json;
  }
}
