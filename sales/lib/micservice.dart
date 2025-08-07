import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class MicController extends GetxController {
  static const MethodChannel _channel = MethodChannel('mic_service_channel');
  final RxString status = 'Mic not started'.obs;

  Future<void> requestMicPermissionAndStart() async {
    log("📞 Called: requestMicPermissionAndStart");

    var micStatus = await Permission.microphone.status;
    var notificationStatus = await Permission.notification.status;

    if (!micStatus.isGranted) micStatus = await Permission.microphone.request();
    if (!notificationStatus.isGranted) {
      notificationStatus = await Permission.notification.request();
    }

    if (micStatus.isGranted && notificationStatus.isGranted) {
      try {
        final result = await _channel.invokeMethod('startMicStream');
        status.value = 'Mic streaming started';
        log("Mic service started: $result");
      } catch (e) {
        status.value = 'Error: $e';
        log("Error starting mic service: $e");
      }
    } else {
      status.value =
          'Permissions denied: Mic=${micStatus.isGranted}, Notifications=${notificationStatus.isGranted}';
    }
  }

  Future<void> refreshMicServiceOffer() async {
    try {
      await _channel.invokeMethod('refresh_offer');
      log("✅ Mic offer refresh broadcast sent");
    } catch (e) {
      log("⚠ Failed to refresh mic offer: $e");
    }
  }
}
