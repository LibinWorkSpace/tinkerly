import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // 👈 This fixes the Uint8List error
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../constants/api_constants.dart';

class UserService {
  // Save or update user profile
  static Future<bool> saveUserProfile(String name, String email, String? profileImageUrl, List<String> categories, String username, String? bio, {String? phone, bool? isPhoneVerified, bool isEdit = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    final Map<String, dynamic> body = {
      'name': name,
      'profileImageUrl': profileImageUrl,
      'categories': categories,
      'username': username,
      'bio': bio,
      if (isPhoneVerified != null) 'isPhoneVerified': isPhoneVerified,
    };
    if (phone != null && phone.isNotEmpty) {
      body['phone'] = phone;
    }
    // Remove null or empty string fields (except for categories)
    body.removeWhere((key, value) => value == null || (value is String && value.isEmpty && key != 'phone'));
    final url = isEdit
      ? Uri.parse('${ApiConstants.baseUrl}/user')
      : Uri.parse('${ApiConstants.baseUrl}/user');
    final response = await (isEdit
      ? http.put(
          url,
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
      : http.post(
          url,
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            ...body,
            'email': email,
          }),
        )
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      throw Exception('Failed to save user profile');
    }
  }

  // Fetch user profile
  static Future<Map<String, dynamic>?> fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/user'),
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
      Uri.parse('${ApiConstants.baseUrl}/media'),
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
    final request = http.MultipartRequest('POST', Uri.parse('${ApiConstants.baseUrl}/upload'));
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
      Uri.parse('${ApiConstants.baseUrl}/media/$mediaId'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    return response.statusCode == 200;
  }
  static Future<String?> uploadBytes(Uint8List bytes, String filename) async {
  final user = FirebaseAuth.instance.currentUser;
  final idToken = await user?.getIdToken();

  final request = http.MultipartRequest('POST', Uri.parse('${ApiConstants.baseUrl}/upload'));
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
      Uri.parse('${ApiConstants.baseUrl}/post'),
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
      Uri.parse('${ApiConstants.baseUrl}/posts'),
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
      Uri.parse('${ApiConstants.baseUrl}/posts?category=${Uri.encodeComponent(category)}'),
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
      Uri.parse('${ApiConstants.baseUrl}/user/$uid'),
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
      Uri.parse('${ApiConstants.baseUrl}/user/$uid/follow'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    return response.statusCode == 200;
  }

  // Unfollow a user by UID
  static Future<bool> unfollowUser(String uid) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/user/$uid/unfollow'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    return response.statusCode == 200;
  }

  // Search users by name or username
  static Future<List<dynamic>> searchUsers(String query) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/users/search?query=${Uri.encodeComponent(query)}'),
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
      Uri.parse('${ApiConstants.baseUrl}/posts/user/$uid'),
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
      Uri.parse('${ApiConstants.baseUrl}/posts/all'),
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
      Uri.parse('${ApiConstants.baseUrl}/post/$postId'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    return response.statusCode == 200;
  }

  // Like a post by ID
  static Future<bool> likePost(String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/post/$postId/like'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    return response.statusCode == 200;
  }

  // Unlike a post by ID
  static Future<bool> unlikePost(String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/post/$postId/unlike'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    return response.statusCode == 200;
  }

  // Send OTP for password reset (method: 'email' or 'phone')
  static Future<bool> sendPasswordResetOtp(String email, {String method = 'email'}) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/auth/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'method': method}),
    );
    return response.statusCode == 200;
  }

  // Reset password with OTP
  static Future<bool> resetPasswordWithOtp(String email, String otp, String newPassword) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp, 'newPassword': newPassword}),
    );
    return response.statusCode == 200;
  }

  // Check if email exists
  static Future<bool> checkEmailExists(String email) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/user/exists?email=${Uri.encodeComponent(email)}'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['exists'] == true;
    }
    return false;
  }

  // Send registration OTP
  static Future<bool> sendRegistrationOtp(String email) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/auth/send-registration-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return response.statusCode == 200;
  }

  // Verify registration OTP
  static Future<bool> verifyRegistrationOtp(String email, String otp) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/auth/verify-registration-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    return response.statusCode == 200;
  }

  static Future<bool> sendSmsOtp(String phone, {bool requireAuth = true}) async {
    String? idToken;
    if (requireAuth) {
      final user = FirebaseAuth.instance.currentUser;
      idToken = await user?.getIdToken();
    }
    final headers = {
      'Content-Type': 'application/json',
      if (requireAuth && idToken != null) 'Authorization': 'Bearer $idToken',
    };
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/otp/send-otp'),
      headers: headers,
      body: jsonEncode({'phone': phone}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['result'] == true;
    }
    return false;
  }

  static Future<bool> verifySmsOtp(String phone, String code, {bool requireAuth = true}) async {
    String? idToken;
    if (requireAuth) {
      final user = FirebaseAuth.instance.currentUser;
      idToken = await user?.getIdToken();
    }
    final headers = {
      'Content-Type': 'application/json',
      if (requireAuth && idToken != null) 'Authorization': 'Bearer $idToken',
    };
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/otp/verify-otp'),
      headers: headers,
      body: jsonEncode({'phone': phone, 'code': code}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['result'] == true;
    }
    return false;
  }

  // Authenticated phone verification for profile
  static Future<bool> verifySmsOtpAuth(String phone, String code) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/otp/verify-otp-auth'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'phone': phone, 'code': code}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['result'] == true;
    }
    return false;
  }

  // Authenticated phone number change
  static Future<bool> changePhone(String phone, String code) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/otp/change-phone'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'phone': phone, 'code': code}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['result'] == true;
    }
    return false;
  }
}
