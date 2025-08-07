import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sales/Auth/Signin.dart';

class PasswordController extends GetxController {
  final TextEditingController emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  var isInputEmpty = true.obs;
  var isInputValid = false.obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();

    // Listen to input changes for validation
    emailController.addListener(() {
      final input = emailController.text.trim();
      isInputEmpty.value = input.isEmpty;
      isInputValid.value = isEmailValid(input);
    });
  }

  bool isEmailValid(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+com$');
    return emailRegex.hasMatch(email);
  }

  Future<void> sendResetEmail() async {
    final email = emailController.text.trim();

    if (!isEmailValid(email)) {
      Get.snackbar(
        'Invalid Email',
        'Please enter a valid email address.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      Get.snackbar(
        'Success',
        'Password reset email sent!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
        colorText: Color(0xFF014185),
      );

      emailController.clear(); // Clear the field after success
      Get.off(() => Signin());
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email format.';
      }

      Get.snackbar(
        'Oops!',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }
}
