import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';

class SigninController extends GetxController {
  final emailOrPhoneController = TextEditingController();
  final passwordController = TextEditingController();

  var isPasswordVisible = false.obs;
  var isInputEmpty = true.obs;
  var isInputValid = false.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();

    emailOrPhoneController.addListener(() {
      final input = emailOrPhoneController.text.trim();
      isInputEmpty.value = input.isEmpty;
      isInputValid.value = _isValidEmail(input) || _isValidPhone(input);
    });
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^\+?[\d\s-]{10,}$');
    return phoneRegex.hasMatch(phone);
  }

  Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown';
    } else {
      return 'unsupported';
    }
  }

  Future<bool> _showForceLogoutDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false, // Prevents dismissing by tapping outside
          builder: (context) => AlertDialog(
            title: const Text(
              'Force Logout',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            content: const Text(
              'This account is already logged in on another device. Do you want to log out from that device and continue?',
              style: TextStyle(fontSize: 16),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                12,
              ), // Consistent corner radius
            ),
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surface, // Theme-aware background
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ), // Standard padding
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel', style: TextStyle(fontSize: 16)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(100, 40), // Consistent button size
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Continue', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ) ??
        false;
  }

  // Future<String?> signIn(String input, String password) async {
  //   try {
  //     print("Attempting to sign in with input: $input");

  //     String? email;
  //     String? uid;

  //     final currentDeviceId = await _getDeviceId(); // Get current device ID

  //     // 📧 1. Resolve email
  //     if (_isValidEmail(input)) {
  //       email = input;
  //     } else if (_isValidPhone(input)) {
  //       final query = await FirebaseFirestore.instance
  //           .collection('users')
  //           .where('phone', isEqualTo: input)
  //           .limit(1)
  //           .get();

  //       if (query.docs.isNotEmpty) {
  //         final doc = query.docs.first;
  //         email = doc.get('email');
  //         uid = doc.get('uid');
  //         print("Found email for phone: $email");
  //       } else {
  //         return 'No account found for this phone number.';
  //       }
  //     } else {
  //       return 'Invalid email or phone number format.';
  //     }

  //     if (email == null) {
  //       return 'Email not found.';
  //     }
  //        // Check if user is already logged in somewhere else
  //     final userQuerySnapshot = await FirebaseFirestore.instance
  //         .collection('users')
  //         .where('email', isEqualTo: email)
  //         .limit(1)
  //         .get();

  //     if (userQuerySnapshot.docs.isNotEmpty) {
  //       final userData = userQuerySnapshot.docs.first.data();
  //       final bool isLoggedInElsewhere = userData['isLoggedIn'] ?? false;
  //       final String existingDeviceId = userData['deviceId'] ?? '';
  //       final String currentDeviceId = await _getDeviceId();

  //       if (isLoggedInElsewhere && existingDeviceId != currentDeviceId) {
  //         final shouldForceLogout = await _showForceLogoutDialog(context);
  //         if (!shouldForceLogout) {
  //           setState(() {
  //             _error = 'Login cancelled by user.';
  //           });
  //           return;
  //         }
  //         await FirebaseFirestore.instance
  //             .collection('users')
  //             .doc(userQuerySnapshot.docs.first.id)
  //             .update({
  //           'isLoggedIn': true,
  //           'deviceId': currentDeviceId,
  //           'lastLoginAt': FieldValue.serverTimestamp(),
  //         });
  //       }
  //     }

  //     // 🔐 2. Firebase Authentication
  //     final userCredential = await FirebaseAuth.instance
  //         .signInWithEmailAndPassword(email: email, password: password);

  //     uid ??= userCredential.user?.uid;

  //     // 📄 3. Get Firestore user document
  //     final userDocRef = FirebaseFirestore.instance
  //         .collection('users')
  //         .doc(uid);
  //     final userDoc = await userDocRef.get();

  //     if (!userDoc.exists) {
  //       await FirebaseAuth.instance.signOut();
  //       return 'No SalesPerson record found.';
  //     }

  //     final data = userDoc.data()!;
  //     final role = data['role'];
  //     final isActive = data['isActive'] ?? false;
  //     final storedDeviceId = data['deviceId'];
  //     // ignore: unused_local_variable
  //     final isLoggedIn = data['isLoggedIn'] ?? false;

  //     // ❌ Check if not salesmen
  //     if (role != "salesmen") {
  //       await FirebaseAuth.instance.signOut();
  //       return 'Access denied. You are not a Sales.';
  //     }

  //     // ❌ Check if inactive
  //     if (!isActive) {
  //       await FirebaseAuth.instance.signOut();
  //       return 'Access denied. Your account is inactive.';
  //     }

  //     // 🔐 4. Enforce single device login
  //     if (storedDeviceId == null || storedDeviceId == currentDeviceId) {
  //       // ✅ First-time login or same device

  //       await userDocRef.update({
  //         'deviceId': currentDeviceId,
  //         'isLoggedIn': true,
  //         'lastLogin': FieldValue.serverTimestamp( ),
  //       });

  //       log("✅ Login successful for $uid on device $currentDeviceId");
  //       return null; // Success
  //     } else {
  //       // ❌ Different device
  //       await FirebaseAuth.instance.signOut();
  //       return 'Access denied. Already logged in on another device.';
  //     }
  //   } on FirebaseAuthException catch (e) {
  //     if (e.code == 'user-not-found') {
  //       return 'No user found with this email or phone.';
  //     } else if (e.code == 'wrong-password') {
  //       return 'Incorrect password. Please try again.';
  //     } else if (e.code == 'network-request-failed') {
  //       return 'Network error. Please check your internet connection.';
  //     } else {
  //       return e.message ?? 'Firebase authentication failed.';
  //     }
  //   } catch (e) {
  //     return 'Unexpected error: $e';
  //   }
  // }
  
  Future<String?> signIn(
    BuildContext context,
    String input,
    String password,
  ) async {
    try {
      print("Attempting to sign in with input: $input");

      String? email;
      String? uid;

      final currentDeviceId = await _getDeviceId();

      // Resolve email or phone
      if (_isValidEmail(input)) {
        email = input;
      } else if (_isValidPhone(input)) {
        final query = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: input)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          final doc = query.docs.first;
          email = doc.get('email');
          uid = doc.get('uid');
          print("Found email for phone: $email");
        } else {
          return 'No account found for this phone number.';
        }
      } else {
        return 'Invalid email or phone number format.';
      }

      if (email == null) return 'Email not found.';

      // 🔍 Check if already logged in elsewhere
      final userQuerySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuerySnapshot.docs.isNotEmpty) {
        final userData = userQuerySnapshot.docs.first.data();
        final bool isLoggedInElsewhere = userData['isLoggedIn'] ?? false;
        final String existingDeviceId = userData['deviceId'] ?? '';

        if (isLoggedInElsewhere && existingDeviceId != currentDeviceId) {
          final shouldForceLogout = await _showForceLogoutDialog(context);

          if (!shouldForceLogout) {
            return 'Login cancelled by user.';
          }

          // Force logout on other device
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userQuerySnapshot.docs.first.id)
              .update({
                'isLoggedIn': false,
                'deviceId': currentDeviceId, // update to current device
                'lastLoginAt': FieldValue.serverTimestamp(),
              });
        }
      }

      // 🔐 Firebase authentication
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      uid ??= userCredential.user?.uid;

      // Firestore user doc
      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid);
      final userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        await FirebaseAuth.instance.signOut();
        return 'No SalesPerson record found.';
      }

      final data = userDoc.data()!;
      final role = data['role'];
      final isActive = data['isActive'] ?? false;
      final storedDeviceId = data['deviceId'];

      if (role != "salesmen") {
        await FirebaseAuth.instance.signOut();
        return 'Access denied. You are not a Sales.';
      }

      if (!isActive) {
        await FirebaseAuth.instance.signOut();
        return 'Access denied. Your account is inactive.';
      }

      // ✅ Update login status
      await userDocRef.update({
        'deviceId': currentDeviceId,
        'isLoggedIn': true,
        'lastLogin': FieldValue.serverTimestamp(),
      });

      log("✅ Login successful for $uid on device $currentDeviceId");
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No user found with this email or phone.';
      } else if (e.code == 'wrong-password') {
        return 'Incorrect password. Please try again.';
      } else if (e.code == 'network-request-failed') {
        return 'Network error. Please check your internet connection.';
      } else {
        return e.message ?? 'Firebase authentication failed.';
      }
    } catch (e) {
      return 'Unexpected error: $e';
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }
}
