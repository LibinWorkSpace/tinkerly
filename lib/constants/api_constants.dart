import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      // For web, use localhost (assuming backend runs on same machine)
      return 'http://localhost:5000';
    } else if (Platform.isAndroid) {
      // For Android emulator, use 10.0.2.2
      return 'http://10.0.2.2:5000';
    } else {
      // For iOS simulator or other platforms
      return 'http://localhost:5000';
    }
  }
} 