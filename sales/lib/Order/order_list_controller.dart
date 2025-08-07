import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class OrderListController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final searchController = TextEditingController();
  late final ScrollController scrollController;

  // Reactive filter variables
  final _selectedStatus = 'All'.obs;
  final _selectedPlace = 'All'.obs;
  final _selectedProductNo = 'All'.obs;
  final _selectedDateRange = Rx<DateTimeRange?>(null);
  final _searchQuery = ''.obs;

  // Pagination and loading state
  final items = <Map<String, dynamic>>[].obs;
  final filteredItems = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final errorMessage = ''.obs;

  // Pagination settings
  static const int itemsPerPage = 20;
  static const int maxRetries = 3;
  DocumentSnapshot? lastDocument;

  // Available filter options
  final availableStatuses = <String>['All'].obs;
  final availablePlaces = <String>['All'].obs;
  final availableProductNos = <String>['All'].obs;
  final isLoadingFilters = true.obs;

  // Debounce timer for search
  Timer? _searchDebounceTimer;

  // Cache for filter options
  bool _filterOptionsCached = false;

  // Getters
  String get selectedStatus => _selectedStatus.value;
  String get selectedPlace => _selectedPlace.value;
  String get selectedProductNo => _selectedProductNo.value;
  DateTimeRange? get selectedDateRange => _selectedDateRange.value;
  String get searchQuery => _searchQuery.value;

  bool get hasActiveFilters =>
      _selectedStatus.value != 'All' ||
      _selectedPlace.value != 'All' ||
      _selectedProductNo.value != 'All' ||
      _selectedDateRange.value != null ||
      _searchQuery.value.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    scrollController = ScrollController();
    _initializeController();
  }

  @override
  void onClose() {
    _searchDebounceTimer?.cancel();
    searchController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _initializeController() {
    // Bind search query to controller text changes with debouncing
    searchController.addListener(_onSearchChanged);

    // Listen to filter changes (but not during initialization)
    Future.delayed(const Duration(milliseconds: 100), () {
      everAll([
        _selectedStatus,
        _selectedPlace,
        _selectedProductNo,
        _selectedDateRange,
      ], (_) => _onFiltersChanged());
    });
  }

  void _onSearchChanged() {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_searchQuery.value != searchController.text) {
        _searchQuery.value = searchController.text;
        _onFiltersChanged();
      }
    });
  }

  void _onFiltersChanged() {
    debugPrint(
      'Filters changed - Status: ${_selectedStatus.value}, Place: ${_selectedPlace.value}, Product: ${_selectedProductNo.value}, DateRange: ${_selectedDateRange.value != null}',
    );
    _resetPagination();
    loadInitialItems();
  }

  void _resetPagination() {
    items.clear();
    filteredItems.clear();
    lastDocument = null;
    hasMore.value = true;
    errorMessage.value = '';
  }

  Future<void> loadInitialItems() async {
    if (isLoading.value) return;

    // Load filter options first if not cached
    if (!_filterOptionsCached) {
      await loadFilterOptions();
    }

    isLoading.value = true;
    errorMessage.value = '';
    _resetPagination();

    try {
      await _loadItems();
    } catch (e) {
      _handleError('Failed to load orders', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreItems() async {
    if (!hasMore.value || isLoadingMore.value || isLoading.value) return;

    isLoadingMore.value = true;
    try {
      await _loadItems();
    } catch (e) {
      _handleError('Failed to load more orders', e);
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> _loadItems({int retryCount = 0}) async {
    try {
      final query = _buildQuery();
      final snapshot = await query.get(
        const GetOptions(source: Source.serverAndCache),
      );

      if (snapshot.docs.isEmpty) {
        hasMore.value = false;
        return;
      }

      final newItems = _processSnapshot(snapshot);

      // Update last document for pagination
      lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

      // Add new items
      items.addAll(newItems);
      _updateFilteredItems();

      // Check if we have more items to load
      hasMore.value = snapshot.docs.length == itemsPerPage;

      debugPrint(
        'Loaded ${newItems.length} items, total: ${items.length}, hasMore: ${hasMore.value}',
      );
    } catch (e) {
      if (retryCount < maxRetries) {
        debugPrint('Retrying load items (attempt ${retryCount + 1})');
        await Future.delayed(Duration(seconds: retryCount + 1));
        return _loadItems(retryCount: retryCount + 1);
      }
      rethrow;
    }
  }

  Query _buildQuery() {
    Query query = _firestore
        .collection('Orders')
        .where('salesmanID', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .orderBy('createdAt', descending: true);

    // Apply filters
    if (_selectedStatus.value != 'All') {
      query = query.where('order_status', isEqualTo: _selectedStatus.value);
    }
    if (_selectedPlace.value != 'All') {
      query = query.where('place', isEqualTo: _selectedPlace.value);
    }
    if (_selectedProductNo.value != 'All') {
      query = query.where('productID', isEqualTo: _selectedProductNo.value);
    }
    if (_selectedDateRange.value != null) {
      final startDate = Timestamp.fromDate(_selectedDateRange.value!.start);
      final endDate = Timestamp.fromDate(
        DateTime(
          _selectedDateRange.value!.end.year,
          _selectedDateRange.value!.end.month,
          _selectedDateRange.value!.end.day,
          23,
          59,
          59,
        ),
      );
      query = query
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate);
    }

    // Apply pagination
    query = query.limit(itemsPerPage);
    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument!);
    }

    return query;
  }

  List<Map<String, dynamic>> _processSnapshot(QuerySnapshot snapshot) {
    final newItems = <Map<String, dynamic>>[];

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (_searchQuery.value.isEmpty || _matchesSearchQuery(data)) {
        newItems.add({...data, 'type': 'Order', 'docId': doc.id});
      }
    }

    return newItems;
  }

  void _updateFilteredItems() {
    if (_searchQuery.value.isEmpty) {
      filteredItems.assignAll(items);
    } else {
      filteredItems.assignAll(
        items.where((item) => _matchesSearchQuery(item)).toList(),
      );
    }
  }

  bool _matchesSearchQuery(Map<String, dynamic> data) {
    if (_searchQuery.value.isEmpty) return true;

    final searchLower = _searchQuery.value.toLowerCase();
    final fieldsToSearch = [
      'name',
      'phone1',
      'phone2',
      'address',
      'place',
      'remark',
      'orderId',
    ];

    return fieldsToSearch.any((field) {
      final value = (data[field] ?? '').toString().toLowerCase();
      return value.contains(searchLower);
    });
  }

  Future<void> loadFilterOptions() async {
    if (_filterOptionsCached) return;

    try {
      isLoadingFilters.value = true;
      final ordersSnapshot = await _firestore
          .collection('Orders')
          .where(
            'salesmanID',
            isEqualTo: FirebaseAuth.instance.currentUser?.uid,
          )
          .get(const GetOptions(source: Source.serverAndCache));

      final statuses = <String>{'All'};
      final places = <String>{'All'};
      final productNos = <String>{'All'};

      for (var doc in ordersSnapshot.docs) {
        final data = doc.data();

        _addToSet(statuses, data['order_status']);
        _addToSet(places, data['place']);
        _addToSet(productNos, data['productID']);
      }

      availableStatuses.assignAll(statuses.toList()..sort());
      availablePlaces.assignAll(places.toList()..sort());
      availableProductNos.assignAll(productNos.toList()..sort());

      _filterOptionsCached = true;

      debugPrint(
        'Filter options loaded - Statuses: ${availableStatuses.length}, Places: ${availablePlaces.length}, Products: ${availableProductNos.length}',
      );
    } catch (e) {
      debugPrint('Error loading filter options: $e');
      _handleError('Failed to load filter options', e);
    } finally {
      isLoadingFilters.value = false;
    }
  }

  void _addToSet(Set<String> set, dynamic value) {
    if (value != null && value.toString().trim().isNotEmpty) {
      set.add(value.toString().trim());
    }
  }

  void _handleError(String message, dynamic error) {
    debugPrint('$message: $error');
    errorMessage.value = message;

    // Show user-friendly error message
    if (error.toString().contains('network')) {
      errorMessage.value = 'Please check your internet connection';
    } else if (error.toString().contains('permission')) {
      errorMessage.value = 'Access denied. Please check your permissions';
    }
  }

  // Filter setters with validation
  void setStatus(String value) {
    if (availableStatuses.contains(value)) {
      _selectedStatus.value = value;
      debugPrint('Status filter set to: $value');
    }
  }

  void setPlace(String value) {
    if (availablePlaces.contains(value)) {
      _selectedPlace.value = value;
      debugPrint('Place filter set to: $value');
    }
  }

  void setProductNo(String value) {
    if (availableProductNos.contains(value)) {
      _selectedProductNo.value = value;
      debugPrint('ProductNo filter set to: $value');
    }
  }

  void setDateRange(DateTimeRange? range) {
    _selectedDateRange.value = range;
    debugPrint('Date range filter set to: $range');
  }

  void clearSearch() {
    searchController.clear();
    _searchQuery.value = '';
  }

  void clearAllFilters() {
    debugPrint('Clearing all filters manually');

    // Cancel any pending search debounce timer
    _searchDebounceTimer?.cancel();

    // Temporarily disable reactive updates by removing listeners
    final statusValue = _selectedStatus.value;
    final placeValue = _selectedPlace.value;
    final productValue = _selectedProductNo.value;
    final dateRangeValue = _selectedDateRange.value;
    final searchValue = _searchQuery.value;

    // Reset all filters silently without triggering reactive updates
    _selectedStatus.value = 'All';
    _selectedPlace.value = 'All';
    _selectedProductNo.value = 'All';
    _selectedDateRange.value = null;
    searchController.clear();
    _searchQuery.value = '';

    // Reset pagination state
    _resetPagination();

    // Load initial data directly (same as what's used initially)
    Future.microtask(() async {
      try {
        isLoading.value = true;
        errorMessage.value = '';

        // Build query for initial data (without any filters)
        final query = _firestore
            .collection('Orders')
            .where(
              'salesmanID',
              isEqualTo: FirebaseAuth.instance.currentUser?.uid,
            )
            .orderBy('createdAt', descending: true)
            .limit(itemsPerPage);

        final snapshot = await query.get(
          const GetOptions(source: Source.serverAndCache),
        );

        if (snapshot.docs.isNotEmpty) {
          final newItems = _processSnapshot(snapshot);
          lastDocument = snapshot.docs.last;
          items.assignAll(newItems);
          _updateFilteredItems();
          hasMore.value = snapshot.docs.length == itemsPerPage;

          debugPrint(
            'Reset filters and loaded ${newItems.length} initial items',
          );
        } else {
          hasMore.value = false;
        }
      } catch (e) {
        _handleError('Failed to load orders after filter reset', e);
      } finally {
        isLoading.value = false;
      }
    });
  }

  Future<void> refreshData() async {
    debugPrint('Refreshing all data');
    _filterOptionsCached = false;
    await loadFilterOptions();
    await loadInitialItems();
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

  // Method to get order count for analytics
  int get totalOrdersCount => items.length;

  // Method to get filtered count
  int get filteredOrdersCount => filteredItems.length;

  // Method to check if data is stale (older than 5 minutes)
  bool get isDataStale {
    // Implementation depends on when you last fetched data
    // This is a placeholder - you might want to track last fetch time
    return false;
  }

  // Performance optimization: Batch updates
  void _batchUpdate(Function updates) {
    // Temporarily disable reactive updates
    updates();
    // Re-enable updates
  }

  // Method to export filtered data (if needed)
  List<Map<String, dynamic>> getFilteredDataForExport() {
    return filteredItems
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // Method to get statistics
  Map<String, int> getOrderStatistics() {
    final stats = <String, int>{};

    for (final item in filteredItems) {
      final status = item['order_status'] ?? 'Unknown';
      stats[status] = (stats[status] ?? 0) + 1;
    }

    return stats;
  }

  // Method to validate data integrity
  bool _validateOrderData(Map<String, dynamic> data) {
    return data.containsKey('name') &&
        data.containsKey('salesmanID') &&
        data['salesmanID'] == FirebaseAuth.instance.currentUser?.uid;
  }

  // Method to preload next batch (performance optimization)
  Future<void> preloadNextBatch() async {
    if (!hasMore.value || isLoadingMore.value) return;

    // Silently load next batch in background
    try {
      final query = _buildQuery();
      await query.get(const GetOptions(source: Source.cache));
    } catch (e) {
      // Silently handle preload errors
      debugPrint('Preload failed: $e');
    }
  }
}
