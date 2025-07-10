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

}
