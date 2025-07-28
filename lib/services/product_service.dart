import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import '../constants/api_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductService {
  static Future<Product> fetchProduct(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/products/$id'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode == 200) {
      return Product.fromMap(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch product');
    }
  }

  static Future<List<Product>> fetchProductsByUser(String userId) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/products/user/$userId'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => Product.fromMap(e)).toList();
    } else {
      throw Exception('Failed to fetch products for user');
    }
  }

  static Future<List<Product>> fetchProductsByPost(String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/products/post/$postId'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => Product.fromMap(e)).toList();
    } else {
      throw Exception('Failed to fetch products for post');
    }
  }
} 