import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/portfolio_model.dart';
import '../constants/api_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PortfolioService {
  static Future<List<Portfolio>> fetchUserPortfolios(String userId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      final idToken = await user.getIdToken();
      print('Fetching portfolios for user: $userId');
      print('API URL: ${ApiConstants.baseUrl}/portfolios/user/$userId');
      
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/portfolios/user/$userId'),
        headers: {'Authorization': 'Bearer $idToken'},
      ).timeout(Duration(seconds: 10));
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((e) => Portfolio.fromMap(e)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please log in again.');
      } else if (response.statusCode == 404) {
        // No portfolios found - return empty list instead of throwing error
        return [];
      } else {
        throw Exception('Failed to fetch portfolios: ${response.statusCode} - ${response.body}');
      }
    } on SocketException {
      throw Exception('Network error: Unable to connect to server. Please check your internet connection.');
    } on HttpException {
      throw Exception('HTTP error: Server returned an invalid response.');
    } on FormatException {
      throw Exception('Data format error: Invalid response from server.');
    } catch (e) {
      print('Error in fetchUserPortfolios: $e');
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timeout: Server is taking too long to respond.');
      }
      rethrow;
    }
  }

  static Future<Portfolio> fetchPortfolio(String id) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      final idToken = await user.getIdToken();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/portfolios/$id'),
        headers: {'Authorization': 'Bearer $idToken'},
      );
      
      if (response.statusCode == 200) {
        return Portfolio.fromMap(jsonDecode(response.body));
      } else {
        print('Portfolio fetch failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to fetch portfolio: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in fetchPortfolio: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> fetchPortfolioFull(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/portfolios/$id/full'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch portfolio details');
    }
  }

  static Future<List<dynamic>> fetchPortfolioPosts(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/portfolios/$id/posts'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch portfolio posts');
    }
  }

  static Future<List<dynamic>> fetchPortfolioProducts(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/portfolios/$id/products'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch portfolio products');
    }
  }

  static Future<List<dynamic>> fetchPortfolioFollowers(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/portfolios/$id/followers'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch portfolio followers');
    }
  }

  static Future<Portfolio> createPortfolio(Map<String, dynamic> portfolioData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      final idToken = await user.getIdToken();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/portfolios'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(portfolioData),
      );
      
      if (response.statusCode == 201) {
        return Portfolio.fromMap(jsonDecode(response.body));
      } else {
        print('Portfolio creation failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to create portfolio: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in createPortfolio: $e');
      rethrow;
    }
  }

  static Future<Portfolio> updatePortfolio(String portfolioId, Map<String, dynamic> updateData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      final idToken = await user.getIdToken();
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/portfolios/$portfolioId'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updateData),
      );
      
      if (response.statusCode == 200) {
        return Portfolio.fromMap(jsonDecode(response.body));
      } else {
        print('Portfolio update failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to update portfolio: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in updatePortfolio: $e');
      rethrow;
    }
  }

  static Future<bool> deletePortfolio(String portfolioId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      final idToken = await user.getIdToken();
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/portfolios/$portfolioId'),
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        print('Portfolio deleted successfully: $portfolioId');
        return true;
      } else {
        print('Portfolio deletion failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to delete portfolio: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in deletePortfolio: $e');
      rethrow;
    }
  }

  static Future<List<Portfolio>> getPortfoliosByCategory(String userId, String category) async {
    try {
      final allPortfolios = await fetchUserPortfolios(userId);
      return allPortfolios.where((portfolio) => portfolio.category == category).toList();
    } catch (e) {
      print('Error in getPortfoliosByCategory: $e');
      rethrow;
    }
  }

  // Search portfolios by name or category
  static Future<List<dynamic>> searchPortfolios(String query) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      final idToken = await user.getIdToken();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/portfolios/search?query=${Uri.encodeComponent(query)}'),
        headers: {'Authorization': 'Bearer $idToken'},
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to search portfolios: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in searchPortfolios: $e');
      rethrow;
    }
  }
} 