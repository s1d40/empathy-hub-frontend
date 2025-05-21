import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kReleaseMode) {
      return 'https_your_production_api_domain_com'; // Replace with your production URL
    } else {
      // For Android Emulator, use 10.0.2.2 to reach host's localhost.
      // For iOS Simulator, Linux desktop, or web (Chrome on the same machine),
      // localhost (or 127.0.0.1) usually works.
      return 'http://192.168.1.120:8000'; // 192.168.1.120 Or 'http://127.0.0.1:8000/api/v1' 'http://192.168.1.120:8000' For devices in Local Network
    }
    
      }

    // In ApiConfig
static String get baseWsUrl {
  if (kReleaseMode) {
    return 'wss://your-production-domain.com'; // Replace with your production WebSocket URL
  } else {
    return 'ws://192.168.1.120:8000'; // Or your local backend WebSocket URL//ws://127.0.0.1:8000
  }
}

}