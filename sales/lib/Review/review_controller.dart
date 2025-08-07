import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReviewController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  RxList<Map<String, dynamic>> orders = <Map<String, dynamic>>[].obs;
  RxString selectedStatus = 'All'.obs;
  RxString searchQuery = ''.obs;
  RxBool showFilters = false.obs;
  late TabController tabController;
  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 4, vsync: this);
    fetchFilteredOrders();
  }

  @override
  void onClose() {
    tabController.dispose();
    _debounce?.cancel();
    super.onClose();
  }

  Future<void> fetchFilteredOrders() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        orders.clear();
        return;
      }

      Query<Map<String, dynamic>> query = _firestore
          .collection('Orders')
          .where('order_status', isEqualTo: 'delivered')
          .where('salesmanID', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true);

      if (selectedStatus.value != 'All') {
        query = query.where('reviewStatus', isEqualTo: selectedStatus.value);
      }

      final querySnapshot = await query.limit(50).get();
      var filtered = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['docId'] = doc.id;
        return data;
      }).toList();

      if (searchQuery.value.isNotEmpty) {
        final searchLower = searchQuery.value.toLowerCase();
        filtered = filtered.where((data) {
          final customerName = (data['customerName'] ?? '').toLowerCase();
          final orderId = (data['orderId'] ?? '').toLowerCase();
          final customerEmail = (data['customerEmail'] ?? '').toLowerCase();
          return customerName.contains(searchLower) ||
              orderId.contains(searchLower) ||
              customerEmail.contains(searchLower);
        }).toList();
      }

      orders.assignAll(filtered);
    } catch (e) {
      print('Oops! fetching orders: $e');
      orders.clear();
    }
  }

  void refreshData() {
    fetchFilteredOrders();
  }

  void onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      searchQuery.value = value;
      fetchFilteredOrders();
    });
  }
}
