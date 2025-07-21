class AppUser {
  final String uid;
  final String email;
  final List<String> categories;
  final String name;
  final String username;
  final String? bio;
  final String? profileImageUrl;
  final DateTime? createdAt;
  final DateTime? lastActive;
  final String? phone;
  final bool? isPhoneVerified;

  AppUser({
    required this.uid,
    required this.email,
    required this.categories,
    required this.name,
    required this.username,
    this.bio,
    this.profileImageUrl,
    this.createdAt,
    this.lastActive,
    this.phone,
    this.isPhoneVerified,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'categories': categories,
      'name': name,
      'username': username,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt?.toIso8601String(),
      'lastActive': lastActive?.toIso8601String(),
      'phone': phone,
      'isPhoneVerified': isPhoneVerified,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'],
      email: map['email'],
      categories: List<String>.from(map['categories']),
      name: map['name'],
      username: map['username'] ?? map['name'].toLowerCase().replaceAll(' ', '_'),
      bio: map['bio'],
      profileImageUrl: map['profileImageUrl'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      lastActive: map['lastActive'] != null ? DateTime.parse(map['lastActive']) : null,
      phone: map['phone'],
      isPhoneVerified: map['isPhoneVerified'],
    );
  }

  AppUser copyWith({
    String? uid,
    String? email,
    List<String>? categories,
    String? name,
    String? username,
    String? bio,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? lastActive,
    String? phone,
    bool? isPhoneVerified,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      categories: categories ?? this.categories,
      name: name ?? this.name,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      phone: phone ?? this.phone,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
    );
  }
}
