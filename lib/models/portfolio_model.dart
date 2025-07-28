class Portfolio {
  final String id;
  final String userId;
  final String profilename;
  final String? profileImageUrl;
  final String category;
  final String description;
  final List<String> followers;
  final List<String> posts;
  final DateTime createdAt;
  final DateTime updatedAt;

  Portfolio({
    required this.id,
    required this.userId,
    required this.profilename,
    this.profileImageUrl,
    required this.category,
    required this.description,
    required this.followers,
    required this.posts,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Portfolio.fromMap(Map<String, dynamic> map) {
    // Handle followers - they might be ObjectIds from backend
    List<String> followersList = [];
    if (map['followers'] != null) {
      try {
        followersList = List<String>.from(map['followers']);
      } catch (e) {
        // If followers are ObjectIds, convert them to strings
        followersList = (map['followers'] as List).map((e) => e.toString()).toList();
      }
    }
    
    // Handle posts - they might be ObjectIds from backend
    List<String> postsList = [];
    if (map['posts'] != null) {
      try {
        postsList = List<String>.from(map['posts']);
      } catch (e) {
        // If posts are ObjectIds, convert them to strings
        postsList = (map['posts'] as List).map((e) => e.toString()).toList();
      }
    }
    
    return Portfolio(
      id: map['_id'] ?? '',
      userId: map['userId'] ?? '',
      profilename: map['profilename'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      followers: followersList,
      posts: postsList,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'userId': userId,
      'profilename': profilename,
      'profileImageUrl': profileImageUrl,
      'category': category,
      'description': description,
      'followers': followers,
      'posts': posts,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
} 