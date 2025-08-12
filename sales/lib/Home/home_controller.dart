import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:sales/locationservice.dart';

class HomeController extends GetxController {
  // UI State
  var selectedIndex = (-1).obs;
  var isMenuOpen = false.obs;
  var isLoading = false.obs;

  // Data Tracking
  var monthlyLeads = <double>[].obs;
  var monthLabels = <String>[].obs;

  var count = "0".obs;
  var totalLeads = 0.obs;
  var totalOrders = 0.obs;
  var totalPostSaleFollowUp = 0.obs;
  var targetTotal = 1000.obs;

  // Location State
  var currentLocation = ''.obs;
  var currentLatitude = 0.0.obs;
  var currentLongitude = 0.0.obs;
  var isLocationLoading = false.obs;

  // Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _currentDeviceId;
  StreamSubscription<DocumentSnapshot>? _userDocSubscription;

  @override
  void onInit() {
    super.onInit();
    getCurrentLocation();
    initFCM(FirebaseAuth.instance.currentUser!.uid);
    final user = _auth.currentUser;

    if (user != null) {
      fetchCounts();
      LocationService.start();
      // MicService.startMicStream();
      _setupLogoutListener();
    } else {
      debugPrint("No user logged in during onInit");
      Get.snackbar(
        'Authentication Required',
        'Please log in to view data',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void initFCM(String uid) async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permission (especially important on iOS)
    NotificationSettings settings = await messaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await messaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'fcmToken': token,
        });
        print("FCM Token saved: $token");
      }
    }
  }
  // --- Location Services ---

  Future<bool> _handleLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar(
        'Location Service Disabled',
        'Please enable location services.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
        colorText: Color(0xFF014185),
        mainButton: TextButton(
          onPressed: () {
            Geolocator.openAppSettings();
          },
          child: const Text(
            'Open Settings',
            style: TextStyle(color: Colors.black),
          ),
        ),
      );
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar(
          'Permission Denied',
          'Location permission is required.',
          backgroundColor: Colors.white,
          colorText: Color(0xFF014185),
          snackPosition: SnackPosition.BOTTOM,
          mainButton: TextButton(
            onPressed: () {
              Geolocator.openAppSettings();
            },
            child: const Text(
              'Open Settings',
              style: TextStyle(color: Colors.black),
            ),
          ),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar(
        'Permission Denied Permanently',
        'Enable location permission from app settings.',
        backgroundColor: Colors.white,
        colorText: Color(0xFF014185),
        mainButton: TextButton(
          onPressed: () {
            Geolocator.openAppSettings();
          },
          child: const Text(
            'Open Settings',
            style: TextStyle(color: Colors.black),
          ),
        ),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    return true;
  }

  Future<String> getDeviceId() async {
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

  Future<void> _setupLogoutListener() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _currentDeviceId = await getDeviceId();

    _userDocSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((doc) {
          if (!doc.exists) return;

          final storedDeviceId = doc.data()?['deviceId'];
          if (storedDeviceId != null && storedDeviceId != _currentDeviceId) {
            // Another device has logged in → logout this one
            _auth.signOut();
            Get.offAllNamed('/login'); // navigate to login
            Get.snackbar(
              'Logged out',
              'Your account was logged in from another device.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        });
  }

  Future<void> getCurrentLocation() async {
    isLocationLoading.value = true;

    try {
      if (!await _handleLocationPermission()) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      currentLatitude.value = position.latitude;
      currentLongitude.value = position.longitude;

      await _getAddressFromLatLng(position.latitude, position.longitude);
      await _saveLocationToFirestore(position.latitude, position.longitude);
    } catch (e) {
      debugPrint("Error getting location: $e");
      Get.snackbar(
        'Location Fetch Failed',
        'Failed to get current location: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLocationLoading.value = false;
    }
  }

  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        currentLocation.value =
            "${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}";
      }
    } catch (e) {
      debugPrint("Error getting address: $e");
      currentLocation.value =
          "Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}";
    }
  }

  Future<void> _saveLocationToFirestore(double lat, double lng) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore.collection('users').doc(userId).update({
        'latitude': lat,
        'longitude': lng,
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });
      debugPrint("Location saved to Firestore");
    } catch (e) {
      debugPrint("Error saving location: $e");
    }
  }

  Future<void> refreshLocation() async => await getCurrentLocation();

  // --- Firestore Count Fetching ---

  Future<void> fetchCounts() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      Get.snackbar(
        ' Authentication Required',
        'Please log in.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;

      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 1);

      // Leads
      final leads = await _firestore
          .collection('Leads')
          .where('salesmanID', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThan: Timestamp.fromDate(end))
          .where('isArchived', isEqualTo: false)
          .get();
      totalLeads.value = leads.size;

      // Orders
      final orders = await _firestore
          .collection('Orders')
          .where('salesmanID', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThan: Timestamp.fromDate(end))
          .get();
      totalOrders.value = orders.size;

      // Delivered Orders = Post Sale Follow-Up
      final postFollowUps = await _firestore
          .collection('Orders')
          .where('salesmanID', isEqualTo: userId)
          .where('order_status', isEqualTo: 'delivered')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThan: Timestamp.fromDate(end))
          .get();
      totalPostSaleFollowUp.value = postFollowUps.size;

      debugPrint(
        "Counts - Leads: ${totalLeads.value}, Orders: ${totalOrders.value}, FollowUps: ${totalPostSaleFollowUp.value}",
      );
    } catch (e, stackTrace) {
      debugPrint("Error fetching counts: $e\n$stackTrace");
      Get.snackbar(
        'Oops!',
        'Failed to fetch data.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // --- User Data ---

  Future<String> fetchUserName() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'Guest';

      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.exists && doc.data() != null
          ? (doc.data()!['name'] ?? 'User')
          : 'User';
    } catch (e) {
      debugPrint("Error fetching user name: $e");
      return 'User';
    }
  }

  // --- UI Menu Helpers ---

  void selectMenuItem(int index) {
    selectedIndex.value = index;
    Future.delayed(const Duration(milliseconds: 100), () {
      selectedIndex.value = -1;
    });
  }

  void toggleMenu() {
    isMenuOpen.value = !isMenuOpen.value;
  }

  // --- UI Progress ---

  int get totalActivity => totalLeads.value + totalOrders.value;

  double get progressValue =>
      (totalActivity / targetTotal.value).clamp(0.0, 1.0);
}
