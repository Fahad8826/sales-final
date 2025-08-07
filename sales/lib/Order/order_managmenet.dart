import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sales/Home/home.dart';
import 'package:sales/Order/order_list_controller.dart';
import 'package:sales/Order/individual_order_details.dart';

class OrderManagement extends StatelessWidget {
  const OrderManagement({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OrderListController(), tag: 'order_management');

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Load filter options first, then initial items
      await controller.loadFilterOptions();
      await controller.loadInitialItems();
    });

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: () async {
        Get.delete<OrderListController>(tag: 'order_management');
        Get.off(() => Home());
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: _buildAppBar(context, screenHeight),
        body: RefreshIndicator(
          onRefresh: () async => await controller.refreshData(),
          color: Colors.white,
          backgroundColor: Colors.blue,
          child: Column(
            children: [
              _buildSearchBar(controller, screenWidth, screenHeight),
              _buildFilters(controller, context, screenWidth, screenHeight),
              Expanded(
                child: Obx(
                  () => _buildOrderList(controller, screenWidth, screenHeight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, double screenHeight) {
    return AppBar(
      title: Text(
        'Order Management',
        style: GoogleFonts.oswald(
          fontWeight: FontWeight.w600,
          fontSize: screenHeight * 0.025,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      backgroundColor: const Color(0xFF014185),
      foregroundColor: Colors.white,
      elevation: 0,
    );
  }

  Widget _buildSearchBar(
    OrderListController controller,
    double screenWidth,
    double screenHeight,
  ) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: TextField(
        controller: controller.searchController,
        decoration: InputDecoration(
          hintText: 'Search orders...',
          hintStyle: TextStyle(fontSize: screenHeight * 0.016),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: Obx(
            () => controller.searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: controller.clearSearch,
                  )
                : const SizedBox.shrink(),
          ),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenHeight * 0.015,
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(
    OrderListController controller,
    BuildContext context,
    double screenWidth,
    double screenHeight,
  ) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        screenWidth * 0.04,
        0,
        screenWidth * 0.04,
        screenHeight * 0.02,
      ),
      child: Row(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isLoadingFilters.value) {
                return SizedBox(
                  height: screenHeight * 0.045,
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      context,
                      'Status',
                      controller.selectedStatus,
                      screenWidth,
                      screenHeight,
                      () => _showFilterDialog(
                        'Status',
                        controller.selectedStatus,
                        controller.availableStatuses.toList(),
                        controller.setStatus,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    _buildFilterChip(
                      context,
                      'Place',
                      controller.selectedPlace,
                      screenWidth,
                      screenHeight,
                      () => _showFilterDialog(
                        'Place',
                        controller.selectedPlace,
                        controller.availablePlaces.toList(),
                        controller.setPlace,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    _buildFilterChip(
                      context,
                      'Product',
                      controller.selectedProductNo,
                      screenWidth,
                      screenHeight,
                      () => _showFilterDialog(
                        'Product',
                        controller.selectedProductNo,
                        controller.availableProductNos.toList(),
                        controller.setProductNo,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    _buildDateFilter(controller, screenWidth, screenHeight),
                  ],
                ),
              );
            }),
          ),
          _buildClearFiltersButton(controller, screenHeight),
        ],
      ),
    );
  }

  Widget _buildOrderList(
    OrderListController controller,
    double screenWidth,
    double screenHeight,
  ) {
    if (controller.isLoading.value && controller.filteredItems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage.isNotEmpty) {
      return _buildErrorState(controller, screenWidth, screenHeight);
    }

    if (controller.filteredItems.isEmpty && !controller.isLoading.value) {
      return _buildEmptyState(screenWidth, screenHeight);
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!controller.isLoadingMore.value &&
            controller.hasMore.value &&
            scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 200) {
          controller.loadMoreItems();
        }
        return false;
      },
      child: ListView.builder(
        key: const ValueKey('order_list'),
        controller: controller.scrollController,
        padding: EdgeInsets.all(screenWidth * 0.04),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount:
            controller.filteredItems.length +
            (controller.hasMore.value ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == controller.filteredItems.length) {
            return _buildLoadingIndicator(controller, screenHeight);
          }

          final item = controller.filteredItems[index];
          return _buildOrderCard(
            context,
            item,
            item['docId'],
            controller,
            screenWidth,
            screenHeight,
          );
        },
      ),
    );
  }

  Widget _buildLoadingIndicator(
    OrderListController controller,
    double screenHeight,
  ) {
    return Obx(() {
      if (!controller.hasMore.value) return const SizedBox.shrink();

      return Container(
        padding: EdgeInsets.all(screenHeight * 0.02),
        child: Column(
          children: [
            if (controller.isLoadingMore.value) ...[
              const CircularProgressIndicator(strokeWidth: 2),
              SizedBox(height: screenHeight * 0.01),
              Text(
                'Loading more orders...',
                style: GoogleFonts.k2d(
                  fontSize: screenHeight * 0.014,
                  color: Colors.grey[600],
                ),
              ),
            ] else ...[
              TextButton(
                onPressed: controller.loadMoreItems,
                child: Text(
                  'Load More',
                  style: GoogleFonts.k2d(
                    fontSize: screenHeight * 0.016,
                    color: Colors.blue[600],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildErrorState(
    OrderListController controller,
    double screenWidth,
    double screenHeight,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: screenHeight * 0.08,
              color: Colors.red[400],
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              'Something went wrong',
              style: GoogleFonts.k2d(
                fontSize: screenHeight * 0.02,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: GoogleFonts.k2d(
                fontSize: screenHeight * 0.016,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            ElevatedButton.icon(
              onPressed: controller.refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF014185),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.06,
                  vertical: screenHeight * 0.015,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    String value,
    double screenWidth,
    double screenHeight,
    VoidCallback onTap,
  ) {
    final isSelected = value != 'All';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenHeight * 0.01,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue[300]! : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isSelected ? '$label: $value' : label,
              style: GoogleFonts.k2d(
                color: isSelected ? Colors.blue[700] : Colors.grey[700],
                fontSize: screenHeight * 0.016,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
            SizedBox(width: screenWidth * 0.02),
            Icon(
              Icons.keyboard_arrow_down,
              size: screenHeight * 0.022,
              color: isSelected ? Colors.blue[700] : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilter(
    OrderListController controller,
    double screenWidth,
    double screenHeight,
  ) {
    return Obx(() {
      final hasDateFilter = controller.selectedDateRange != null;
      final displayText = hasDateFilter
          ? '${DateFormat('dd/MM').format(controller.selectedDateRange!.start)} - ${DateFormat('dd/MM').format(controller.selectedDateRange!.end)}'
          : 'Date';

      return InkWell(
        onTap: () => _selectDateRange(controller),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenHeight * 0.01,
          ),
          decoration: BoxDecoration(
            color: hasDateFilter ? Colors.blue[50] : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasDateFilter ? Colors.blue[300]! : Colors.grey[300]!,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayText,
                style: GoogleFonts.k2d(
                  color: hasDateFilter
                      ? const Color(0xFF014185)
                      : Colors.grey[700],
                  fontSize: screenHeight * 0.016,
                  fontWeight: hasDateFilter ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Icon(
                Icons.calendar_today,
                size: screenHeight * 0.02,
                color: hasDateFilter ? Colors.blue[700] : Colors.grey[600],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildClearFiltersButton(
    OrderListController controller,
    double screenHeight,
  ) {
    return Obx(() {
      final hasActiveFilters = controller.hasActiveFilters;

      if (!hasActiveFilters) return const SizedBox.shrink();

      return TextButton.icon(
        onPressed: controller.clearAllFilters,
        icon: Icon(Icons.clear, size: screenHeight * 0.022),
        label: Text(
          'Clear',
          style: GoogleFonts.k2d(fontSize: screenHeight * 0.016),
        ),
        style: TextButton.styleFrom(
          foregroundColor: Colors.red[600],
          padding: EdgeInsets.symmetric(
            horizontal: screenHeight * 0.015,
            vertical: screenHeight * 0.01,
          ),
        ),
      );
    });
  }

  Widget _buildOrderCard(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
    OrderListController controller,
    double screenWidth,
    double screenHeight,
  ) {
    final isCancelled = data['Cancel'] == true;
    final statusColor = _getStatusColor(data['order_status']);

    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.015),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: isCancelled
            ? null
            : () => _navigateToDetails(data, 'Order', docId),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔹 Header: Name + Status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      data['name'] ?? 'No Name',
                      style: GoogleFonts.k2d(
                        fontWeight: FontWeight.w600,
                        fontSize: screenHeight * 0.018,
                      ),
                    ),
                  ),
                  _buildStatusBadge(
                    data['order_status'],
                    statusColor,
                    screenHeight,
                  ),
                  if (isCancelled) _buildCancelledBadge(screenHeight),
                ],
              ),
              SizedBox(height: screenHeight * 0.008),

              /// 🔹 Order ID
              if (data['orderId'] != null)
                Text(
                  'Order ID: ${data['orderId']}',
                  style: GoogleFonts.k2d(
                    fontSize: screenHeight * 0.014,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              SizedBox(height: screenHeight * 0.01),

              /// 🔹 Delivery Date
              Row(
                children: [
                  Icon(
                    Icons.date_range,
                    size: screenHeight * 0.02,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Text(
                    data['deliveryDate'] != null
                        ? DateFormat(
                            'dd/MM/yyyy',
                          ).format(data['deliveryDate'].toDate())
                        : 'Not specified',
                    style: GoogleFonts.k2d(
                      fontSize: screenHeight * 0.016,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              /// 🔹 Place / Location
              if (data['place'] != null) ...[
                SizedBox(height: screenHeight * 0.008),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: screenHeight * 0.018,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Expanded(
                      child: Text(
                        data['place'],
                        style: GoogleFonts.k2d(
                          fontSize: screenHeight * 0.014,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              /// 🔹 Footer: View Details (if not cancelled)
              if (!isCancelled) ...[
                SizedBox(height: screenHeight * 0.015),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'View Details',
                      style: GoogleFonts.k2d(
                        color: Colors.blue[600],
                        fontSize: screenHeight * 0.016,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: screenHeight * 0.016,
                      color: Colors.blue[600],
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color, double screenHeight) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenHeight * 0.01,
        vertical: screenHeight * 0.005,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: GoogleFonts.k2d(
          color: color,
          fontSize: screenHeight * 0.014,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCancelledBadge(double screenHeight) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenHeight * 0.01,
        vertical: screenHeight * 0.005,
      ),
      decoration: BoxDecoration(
        color: Colors.red[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Cancelled',
        style: GoogleFonts.k2d(
          color: Colors.red[700],
          fontSize: screenHeight * 0.012,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEmptyState(double screenWidth, double screenHeight) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: screenHeight * 0.1,
            color: Colors.grey[400],
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(
            'No orders found',
            style: GoogleFonts.k2d(
              fontSize: screenHeight * 0.02,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            'Try adjusting your search or filters',
            style: GoogleFonts.k2d(
              color: Colors.grey[500],
              fontSize: screenHeight * 0.016,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
      case 'accepted':
        return Colors.blue;
      case 'sent out for delivery':
        return Colors.orange;
      case 'pending':
        return Colors.red;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showFilterDialog(
    String title,
    String currentValue,
    List<String> options,
    Function(String) onChanged,
  ) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Filter by $title',
                    style: GoogleFonts.k2d(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey[200]),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected = option == currentValue;

                  return ListTile(
                    title: Text(option, style: GoogleFonts.k2d()),
                    trailing: isSelected
                        ? Icon(Icons.check, color: Colors.blue[600])
                        : null,
                    onTap: () {
                      onChanged(option);
                      Get.back();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _selectDateRange(OrderListController controller) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: Get.context!,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: controller.selectedDateRange,
    );
    if (picked != null) {
      controller.setDateRange(picked);
    }
  }

  void _navigateToDetails(
    Map<String, dynamic> data,
    String type,
    String docId,
  ) {
    Get.to(() => IndividualOrderDetails(data: data, type: type, docId: docId));
  }
}
