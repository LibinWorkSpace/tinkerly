import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // 👈 This fixes the Uint8List error
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  static const String backendUrl = 'http://localhost:5000';

  // Save or update user profile
  static Future<void> saveUserProfile(String name, String email, String? profileImageUrl, List<String> categories, String username, String? bio) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    final response = await http.post(
      Uri.parse('$backendUrl/user'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'profileImageUrl': profileImageUrl,
        'categories': categories,
        'username': username,
        'bio': bio,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to save user profile');
    }
  }

  // Fetch user profile
  static Future<Map<String, dynamic>?> fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    final response = await http.get(
      Uri.parse('$backendUrl/user'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  // Fetch all media for the current user
  static Future<List<dynamic>> fetchMedia() async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    final response = await http.get(
      Uri.parse('$backendUrl/media'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch media');
    }
  }

  // Upload a file (image/video/other) to backend/Cloudinary
  static Future<String?> uploadFile(String filePath) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    final request = http.MultipartRequest('POST', Uri.parse('$backendUrl/upload'));
    request.headers['Authorization'] = 'Bearer $idToken';
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    final response = await request.send();
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      print('Cloudinary upload response: $respStr'); // Debug print
      final data = jsonDecode(respStr);
      return data['url'] as String?;
    }
    return null;
  }

  // Delete a media file by ID
  static Future<bool> deleteMedia(String mediaId) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    final response = await http.delete(
      Uri.parse('$backendUrl/media/$mediaId'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    return response.statusCode == 200;
  }
  static Future<String?> uploadBytes(Uint8List bytes, String filename) async {
  final user = FirebaseAuth.instance.currentUser;
  final idToken = await user?.getIdToken();

  final request = http.MultipartRequest('POST', Uri.parse('$backendUrl/upload'));
  request.headers['Authorization'] = 'Bearer $idToken';
  request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

  final response = await request.send();
  if (response.statusCode == 200) {
    final respStr = await response.stream.bytesToString();
    final data = jsonDecode(respStr);
    return data['url'] as String?;
  } else {
    print('Upload failed with status: ${response.statusCode}');
    return null;
  }
}

  // Create a new post
  static Future<void> createPost({
    required String url,
    required String description,
    required String category,
    required String mediaType,
    required String? idToken,
    required String? userId,
    String? subCategory,
  }) async {
    final body = {
      'url': url,
      'description': description,
      'category': category,
      'mediaType': mediaType,
      'userId': userId,
    };
    if (subCategory != null && subCategory.isNotEmpty) {
      body['subCategory'] = subCategory;
    }
    final response = await http.post(
      Uri.parse('$backendUrl/post'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to create post');
    }
  }

  // Fetch all posts for the current user
  static Future<List<dynamic>> fetchPosts() async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    final response = await http.get(
      Uri.parse('$backendUrl/posts'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch posts');
    }
  }

  // Fetch posts by category for the current user
  static Future<List<dynamic>> fetchPostsByCategory(String category) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    final response = await http.get(
      Uri.parse('$backendUrl/posts?category=${Uri.encodeComponent(category)}'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch posts by category');
    }
  }

  // Fetch another user's public profile by UID
  static Future<Map<String, dynamic>?> fetchPublicProfile(String uid) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    final response = await http.get(
      Uri.parse('$backendUrl/user/$uid'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  // Follow a user by UID
  static Future<bool> followUser(String uid) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    final response = await http.post(
      Uri.parse('$backendUrl/user/$uid/follow'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    return response.statusCode == 200;
  }

  // Unfollow a user by UID
  static Future<bool> unfollowUser(String uid) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    final response = await http.post(
      Uri.parse('$backendUrl/user/$uid/unfollow'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    return response.statusCode == 200;
  }

  // Search users by name or username
  static Future<List<dynamic>> searchUsers(String query) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    final response = await http.get(
      Uri.parse('$backendUrl/users/search?query=${Uri.encodeComponent(query)}'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to search users');
    }
  }

  // Fetch posts for a specific user by UID
  static Future<List<dynamic>> fetchPostsForUser(String uid) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    final response = await http.get(
      Uri.parse('$backendUrl/posts/user/$uid'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch user posts');
    }
  }

  // Fetch all posts from all users (for home feed)
  static Future<List<dynamic>> fetchAllPosts() async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    final response = await http.get(
      Uri.parse('$backendUrl/posts/all'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch all posts');
    }
  }

  // Delete a post by ID
  static Future<bool> deletePost(String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    final response = await http.delete(
      Uri.parse('$backendUrl/post/$postId'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    return response.statusCode == 200;
  }

  // Like a post by ID
  static Future<bool> likePost(String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    final response = await http.post(
      Uri.parse('$backendUrl/post/$postId/like'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    return response.statusCode == 200;
  }

  // Unlike a post by ID
  static Future<bool> unlikePost(String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    final response = await http.post(
      Uri.parse('$backendUrl/post/$postId/unlike'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    return response.statusCode == 200;
  }
}
