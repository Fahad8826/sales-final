// location_service.dart
import 'package:flutter/services.dart';

class LocationService {
  static const MethodChannel _channel = MethodChannel('location_service_channel');

  static Future<void> start() async {
    try {
      await _channel.invokeMethod('startLocationService');
    } catch (e) {
      print("Error starting location service: $e");
    }
  }

  static Future<void> stop() async {
    try {
      await _channel.invokeMethod('stopLocationService');
    } catch (e) {
      print("Error stopping location service: $e");
    }
  }
}
