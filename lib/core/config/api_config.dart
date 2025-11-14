import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ApiConfig {
  static String get baseUrl {
    if (kReleaseMode) {
      return 'https://empathy-hub-backend-131065304705.us-central1.run.app'; // Replace with your production URL
    } else {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return 'http://192.168.1.101:8000'; // For Android Emulator/Device to reach host's local network IP
      }
      return 'http://127.0.0.1:8000'; // For iOS Simulator, Linux desktop, or web (Chrome on the same machine)
    }
  }

    // In ApiConfig
static String get baseWsUrl {
  if (kReleaseMode) {
    return 'wss://empathy-hub-backend-131065304705.us-central1.run.app'; // Replace with your production WebSocket URL
  } else {
    if (defaultTargetPlatform == TargetPlatform.android) {
        return 'ws://192.168.1.101:8000'; // For Android Emulator/Device to reach host's local network IP
      }
    return 'ws://127.0.0.1:8000'; // Or your local backend WebSocket URL
  }
}

}