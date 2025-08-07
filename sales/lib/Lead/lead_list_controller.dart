import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class LeadListController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  var items = <Map<String, dynamic>>[].obs; // Reactive list of all items
  var filteredItems = <Map<String, dynamic>>[].obs; // Reactive filtered items
  var isLoading = false.obs; // Reactive loading state
  var page = 1.obs; // Reactive page counter
  final int itemsPerPage = 20;
  final ScrollController scrollController = ScrollController();

  // Separate last documents for pagination
  DocumentSnapshot? _lastLeadDocument;
  DocumentSnapshot? _lastOrderDocument;

  var _hasMoreLeads = true.obs;
  var _hasMoreOrders = true.obs;

  // Reactive filter variables
  final _selectedType = 'All'.obs;
  final _selectedStatus = 'All'.obs;
  final _selectedPlace = 'All'.obs;
  final _selectedProductNo = 'All'.obs;
  final _selectedDateRange = Rx<DateTimeRange?>(null);
  final searchQuery = ''.obs;

  // Available filter options
  final availableStatuses = <String>['All'].obs;
  final availablePlaces = <String>['All'].obs;
  final availableProductNos = <String>['All'].obs;

  // Loading state
  final isLoadingFilters = true.obs;

  // Getters
  String get selectedType => _selectedType.value;
  String get selectedStatus => _selectedStatus.value;
  String get selectedPlace => _selectedPlace.value;
  String get selectedProductNo => _selectedProductNo.value;
  DateTimeRange? get selectedDateRange => _selectedDateRange.value;
  String get searchQuery_getter => searchQuery.value; // Fixed return type
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    loadFilterOptions();
    _loadInitialItems(); // Load initial items
    scrollController.addListener(_onScroll);

    // Debounce filter updates to refresh items
    everAll(
      [
        _selectedType,
        _selectedStatus,
        _selectedPlace,
        _selectedProductNo,
        _selectedDateRange,
        searchQuery,
      ],
      (_) {
        _resetPagination();
        _loadInitialItems(); // Reload items with new filters
      },
    );

    // Listener for text changes to update searchQuery
  }

  void _resetPagination() {
    page.value = 1;
    items.clear();
    filteredItems.clear();
    _lastLeadDocument = null;
    _lastOrderDocument = null;
    _hasMoreLeads.value = true;
    _hasMoreOrders.value = true;
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        !isLoading.value &&
        (_hasMoreLeads.value || _hasMoreOrders.value)) {
      _loadMoreItems(); // Load more items
    }
  }

  Future<void> _loadInitialItems() async {
    _resetPagination();
    await _loadMoreItems();
  }

  Future<void> _loadMoreItems() async {
    if (isLoading.value || currentUserId == null) return;

    // Check if we have more data to load
    if (!_hasMoreLeads.value && !_hasMoreOrders.value) return;

    isLoading.value = true;

    try {
      List<Map<String, dynamic>> newItems = [];

      // Query Leads if we have more leads to load
      if (_hasMoreLeads.value) {
        Query<Map<String, dynamic>> leadsQuery = _firestore
            .collection('Leads')
            .where('salesmanID', isEqualTo: currentUserId)
            .orderBy('createdAt', descending: true)
            .limit(itemsPerPage ~/ 2);

        // Apply pagination for leads
        if (_lastLeadDocument != null) {
          leadsQuery = leadsQuery.startAfterDocument(_lastLeadDocument!);
        }

        final leadsSnapshot = await leadsQuery.get();

        // Update has more leads flag
        _hasMoreLeads.value = leadsSnapshot.docs.length == itemsPerPage ~/ 2;

        // Update last document for leads
        if (leadsSnapshot.docs.isNotEmpty) {
          _lastLeadDocument = leadsSnapshot.docs.last;
        }

        // Process Leads
        for (var doc in leadsSnapshot.docs) {
          final data = doc.data();
          data['id'] = doc.id;
          data['type'] = 'Lead';
          newItems.add(data);
        }
      }

      // Query Orders if we have more orders to load
      if (_hasMoreOrders.value) {
        Query<Map<String, dynamic>> ordersQuery = _firestore
            .collection('Orders')
            .where('salesmanID', isEqualTo: currentUserId)
            .orderBy('createdAt', descending: true)
            .limit(itemsPerPage ~/ 2);

        // Apply pagination for orders
        if (_lastOrderDocument != null) {
          ordersQuery = ordersQuery.startAfterDocument(_lastOrderDocument!);
        }

        final ordersSnapshot = await ordersQuery.get();

        // Update has more orders flag
        _hasMoreOrders.value = ordersSnapshot.docs.length == itemsPerPage ~/ 2;

        // Update last document for orders
        if (ordersSnapshot.docs.isNotEmpty) {
          _lastOrderDocument = ordersSnapshot.docs.last;
        }

        // Process Orders
        for (var doc in ordersSnapshot.docs) {
          final data = doc.data();
          data['id'] = doc.id;
          data['type'] = 'Order';
          newItems.add(data);
        }
      }

      // Sort items by createdAt (newest first)
      newItems.sort(
        (a, b) => (b['createdAt'] as Timestamp).compareTo(
          a['createdAt'] as Timestamp,
        ),
      );

      // Update items
      items.addAll(newItems);

      // Apply filters to get filtered items
      _applyFilters();

      page.value++;
    } catch (e) {
      print('Oops! loading items: $e');
      Get.snackbar(
        'Oops!',
        'Failed to load items: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = items.where((item) {
      return matchesFilters(item, item['type']);
    }).toList();

    filteredItems.assignAll(filtered);
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  Future<void> loadFilterOptions() async {
    try {
      isLoadingFilters.value = true;

      final leadsSnapshot = await _firestore
          .collection('Leads')
          .where('salesmanID', isEqualTo: currentUserId)
          .get();

      final ordersSnapshot = await _firestore
          .collection('Orders')
          .where('salesmanID', isEqualTo: currentUserId)
          .get();

      Set<String> statuses = {'All'};
      Set<String> places = {'All'};
      Set<String> productNos = {'All'};

      // Process leads
      for (var doc in leadsSnapshot.docs) {
        final data = doc.data();
        if (data['status']?.toString().trim().isNotEmpty == true) {
          statuses.add(data['status'].toString().trim());
        }
        if (data['place']?.toString().trim().isNotEmpty == true) {
          places.add(data['place'].toString().trim());
        }
        if (data['productID']?.toString().trim().isNotEmpty == true) {
          productNos.add(data['productID'].toString().trim());
        }
      }

      // Process orders
      for (var doc in ordersSnapshot.docs) {
        final data = doc.data();
        if (data['status']?.toString().trim().isNotEmpty == true) {
          statuses.add(data['status'].toString().trim());
        }
        if (data['place']?.toString().trim().isNotEmpty == true) {
          places.add(data['place'].toString().trim());
        }
        if (data['productID']?.toString().trim().isNotEmpty == true) {
          productNos.add(data['productID'].toString().trim());
        }
      }

      availableStatuses.assignAll(statuses.toList()..sort());
      availablePlaces.assignAll(places.toList()..sort());
      availableProductNos.assignAll(productNos.toList()..sort());
    } catch (e) {
      print('Oops! loading filter options: $e');
      Get.snackbar(
        'Oops!',
        'Failed to load filter options',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoadingFilters.value = false;
    }
  }

  // Utility methods for date formatting
  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  String formatDateShort(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return DateFormat('dd MMM yyyy').format(date);
  }

  // Filter matching logic
  bool matchesFilters(Map<String, dynamic> data, String type) {
    // Check user ownership
    if (currentUserId == null) return false;

    final userField = type == 'Lead' ? 'salesmanID' : 'salesmanID';
    if (data[userField] != currentUserId) return false;

    // Type filter
    if (_selectedType.value != 'All' && _selectedType.value != type) {
      return false;
    }

    // Status filter
    if (_selectedStatus.value != 'All') {
      final itemStatus = data['status']?.toString().trim() ?? '';
      if (itemStatus != _selectedStatus.value) return false;
    }

    // Place filter
    if (_selectedPlace.value != 'All') {
      final itemPlace = data['place']?.toString().trim() ?? '';
      if (itemPlace != _selectedPlace.value) return false;
    }

    // Product filter
    if (_selectedProductNo.value != 'All') {
      final itemProductID = data['productID']?.toString().trim() ?? '';
      if (itemProductID != _selectedProductNo.value) return false;
    }

    // Date range filter
    if (_selectedDateRange.value != null && data['createdAt'] != null) {
      final createdDate = (data['createdAt'] as Timestamp).toDate();
      final startDate = DateTime(
        _selectedDateRange.value!.start.year,
        _selectedDateRange.value!.start.month,
        _selectedDateRange.value!.start.day,
      );
      final endDate = DateTime(
        _selectedDateRange.value!.end.year,
        _selectedDateRange.value!.end.month,
        _selectedDateRange.value!.end.day,
        23,
        59,
        59,
      );
      if (createdDate.isBefore(startDate) || createdDate.isAfter(endDate)) {
        return false;
      }
    }

    // Search query filter
    if (searchQuery.value.isNotEmpty) {
      final searchLower = searchQuery.value.toLowerCase();
      final searchableFields = [
        (data['name'] ?? '').toString().toLowerCase(),
        (data['phone1'] ?? '').toString().toLowerCase(),
        (data['phone2'] ?? '').toString().toLowerCase(),
        (data['address'] ?? '').toString().toLowerCase(),
        (data['place'] ?? '').toString().toLowerCase(),
        (data['remark'] ?? '').toString().toLowerCase(),
        (data['leadId'] ?? '').toString().toLowerCase(),
        (data['orderId'] ?? '').toString().toLowerCase(),
      ];
      if (!searchableFields.any((field) => field.contains(searchLower))) {
        return false;
      }
    }

    return true;
  }

  // Filter setters
  void setType(String value) => _selectedType.value = value;
  void setStatus(String value) => _selectedStatus.value = value;
  void setPlace(String value) => _selectedPlace.value = value;
  void setProductNo(String value) => _selectedProductNo.value = value;
  void setDateRange(DateTimeRange? range) => _selectedDateRange.value = range;

  void clearAllFilters() {
    _selectedType.value = 'All';
    _selectedStatus.value = 'All';
    _selectedPlace.value = 'All';
    _selectedProductNo.value = 'All';
    _selectedDateRange.value = null;
    searchQuery.value = '';
  }

  void refreshFilterOptions() => loadFilterOptions();

  Future<void> refreshData() async {
    await loadFilterOptions();
    await _loadInitialItems();
  }

  bool get hasActiveFilters =>
      _selectedType.value != 'All' ||
      _selectedStatus.value != 'All' ||
      _selectedPlace.value != 'All' ||
      _selectedProductNo.value != 'All' ||
      _selectedDateRange.value != null ||
      searchQuery.value.isNotEmpty;
}
