class UserModel {
  final String uid;
  final String email;
  final String username;
  final List<String> interests;
  final bool profileComplete;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.interests,
    required this.profileComplete,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      interests: List<String>.from(map['interests'] ?? []),
      profileComplete: map['profileComplete'] ?? false,
      createdAt: map['createdAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'interests': interests,
      'profileComplete': profileComplete,
      'createdAt': createdAt,
    };
  }
}
