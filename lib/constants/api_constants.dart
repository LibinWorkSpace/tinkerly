import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      // For web development, use localhost
      return 'http://localhost:5000';
    } else if (Platform.isAndroid) {
      // For Android emulator during development
      return 'http://10.0.2.2:5000';

      // For real Android device connecting to your computer
      // Replace with your computer's IP address
      // return 'http://192.168.1.4:5000';
    } else {
      // For iOS and other platforms
      return 'http://localhost:5000';
    }
  }
}