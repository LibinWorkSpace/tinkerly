import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  Future<void> saveUser(AppUser user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  static Future<AppUser?> getUserByUid(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return AppUser.fromMap(doc.data()!);
    }
    return null;
  }

  static Future<void> updateUserProfile({
    required String uid,
    required String name,
    required String username,
    required String bio,
    String? profileImageUrl,
  }) async {
    final data = {
      'name': name,
      'username': username,
      'bio': bio,
    };
    if (profileImageUrl != null) {
      data['profileImageUrl'] = profileImageUrl;
    }
    await FirebaseFirestore.instance.collection('users').doc(uid).update(data);
  }
}
