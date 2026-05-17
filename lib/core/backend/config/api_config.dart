import 'package:flutter/foundation.dart';

class ApiConfig {
  
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://192.168.5.10:8000';
    }
    
    return 'http://192.168.5.10:8000';
  }
  // static const String baseUrl = String.fromEnvironment(
  //   'AI_API_URL',
  //   defaultValue: 'http://10.0.2.2:8000', // Default for Android emulator
  // );
}

