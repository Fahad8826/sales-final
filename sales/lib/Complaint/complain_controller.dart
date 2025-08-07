// complaint_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ComplaintController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final complaintController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxString selectedCategory = 'General'.obs;
  final RxInt priority = 1.obs; // 1: Low, 2: Medium, 3: High

  final List<String> categories = [
    'General',
    'Technical Issue',
    'Staff Behavior',
    'Other',
  ];

  Future<void> submitComplaint() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Get.snackbar(
          'Oops!',
          'Please log in to submit a complaint',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          icon: const Icon(Icons.error_outline),
        );
        return;
      }

      // Get user's name from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final name = userDoc.data()?['name'] ?? 'Unknown User';
      final email = userDoc.data()?['email'] ?? user.email ?? 'No email';

      // Generate complaint ID
      final complaintId = DateTime.now().millisecondsSinceEpoch.toString();

      await FirebaseFirestore.instance.collection('complaints').add({
        'complaintId': complaintId,
        'userId': user.uid,
        'name': name,
        'email': email,
        'complaint': complaintController.text.trim(),
        'category': selectedCategory.value,
        'priority': priority.value,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
        'statusChanged': false,
      });

      Get.snackbar(
        'Success',
        'Your complaint has been submitted successfully!\nComplaint ID: $complaintId',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
        colorText: Color(0xFF014185),
        icon: const Icon(Icons.check_circle_outline),
        duration: const Duration(seconds: 4),
      );

      // Clear form
      complaintController.clear();
      selectedCategory.value = 'General';
      priority.value = 1;
    } catch (e) {
      Get.snackbar(
        'Oops!',
        'Failed to submit complaint. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error_outline),
      );
    } finally {
      isLoading.value = false;
    }
  }

  String getPriorityText(int value) {
    switch (value) {
      case 1:
        return 'Low';
      case 2:
        return 'Medium';
      case 3:
        return 'High';
      default:
        return 'Low';
    }
  }

  Color getPriorityColor(int value) {
    switch (value) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  @override
  void onClose() {
    complaintController.dispose();
    super.onClose();
  }
}
