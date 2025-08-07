import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sales/Lead/lead_list_controller.dart';
import 'package:sales/Home/home.dart';
import 'package:sales/Lead/individual_details.dart';

class LeadList extends StatelessWidget {
  const LeadList({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LeadListController());

    return WillPopScope(
      onWillPop: () async {
        Get.off(() => Home());
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              Get.off(() => Home());
            },
            icon: Icon(Icons.arrow_back, color: Colors.white),
          ),
          title: Text(
            'Leads & Orders',
            style: GoogleFonts.oswald(
              fontWeight: FontWeight.w600,
              fontSize: MediaQuery.of(context).size.height * 0.025,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: Color(0xFF014185),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            Obx(
              () =>
                  controller
                      .hasActiveFilters // Remove .value
                  ? IconButton(
                      icon: const Icon(Icons.filter_alt_off),
                      onPressed: () => controller.clearAllFilters(),
                    )
                  : SizedBox.shrink(),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => controller.refreshData(),
          backgroundColor: Colors.blue,
          color: Colors.white,
          child: Column(
            children: [
              _buildSearchBar(controller, context),
              _buildFilterChips(controller, context),
              const Divider(height: 1),
              Expanded(child: _buildListView(controller, context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(LeadListController controller, BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Obx(() {
        return TextField(
          onChanged: (value) => controller.searchQuery.value = value,
          decoration: InputDecoration(
            hintText: 'Search by name, phone, address, ID...',
            hintStyle: GoogleFonts.k2d(
              fontSize: MediaQuery.of(context).size.height * 0.015,
            ),
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            suffixIcon: controller.searchQuery.value.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () => controller.clearAllFilters(),
                  )
                : const SizedBox.shrink(),
          ),
        );
      }),
    );
  }

  Widget _buildFilterChips(LeadListController controller, context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.06,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(() {
        if (controller.isLoadingFilters.value) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        return ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildFilterChip(
              'Type',
              controller.selectedType,
              ['All', 'Lead', 'Order'],
              controller.setType,
              controller,
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.05),
            _buildFilterChip(
              'Status',
              controller.selectedStatus,
              controller.availableStatuses.toList(),
              controller.setStatus,
              controller,
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.05),
            _buildFilterChip(
              'Place',
              controller.selectedPlace,
              controller.availablePlaces.toList(),
              controller.setPlace,
              controller,
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.05),
            _buildFilterChip(
              'Product',
              controller.selectedProductNo,
              controller.availableProductNos.toList(),
              controller.setProductNo,
              controller,
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.05),
            _buildDateRangeChip(controller),
            SizedBox(width: MediaQuery.of(context).size.width * 0.05),
            _buildClearFiltersChip(controller, context),
          ],
        );
      }),
    );
  }

  Widget _buildFilterChip(
    String label,
    String currentValue,
    List<String> options,
    Function(String) onChanged,
    LeadListController controller,
  ) {
    return FilterChip(
      label: Text('$label: $currentValue', style: GoogleFonts.k2d()),
      selected: currentValue != 'All',
      onSelected: (_) =>
          _showFilterDialog(label, currentValue, options, onChanged),
      backgroundColor: Colors.white,
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue[700],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildDateRangeChip(LeadListController controller) {
    return Obx(() {
      final hasDateFilter = controller.selectedDateRange != null;
      return FilterChip(
        label: Text(
          hasDateFilter
              ? 'Date: ${DateFormat('dd/MM').format(controller.selectedDateRange!.start)} - ${DateFormat('dd/MM').format(controller.selectedDateRange!.end)}'
              : 'Date: All',
          style: GoogleFonts.k2d(),
        ),
        selected: hasDateFilter,
        onSelected: (_) => _selectDateRange(controller),
        backgroundColor: Colors.white,
        selectedColor: Colors.blue[100],
        checkmarkColor: Colors.blue[700],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      );
    });
  }

  Widget _buildClearFiltersChip(LeadListController controller, context) {
    return Obx(() {
      if (!controller.hasActiveFilters)
        return const SizedBox.shrink(); // Remove .value
      return ActionChip(
        label: const Text('Clear All'),
        onPressed: controller.clearAllFilters,
        backgroundColor: Colors.red[100],
        avatar: const Icon(Icons.clear, size: 18),
      );
    });
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
                    title: Text(option),
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

  Future<void> _selectDateRange(LeadListController controller) async {
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

  Widget _buildListView(LeadListController controller, context) {
    return Obx(() {
      if (controller.filteredItems.isEmpty && !controller.isLoading.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey),
              SizedBox(height: MediaQuery.of(context).size.height * 0.05),
              Text(
                'No items found',
                style: GoogleFonts.k2d(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.05),
              Text(
                'Try adjusting your search or filters',
                style: GoogleFonts.k2d(color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        controller: controller.scrollController,
        padding: const EdgeInsets.only(bottom: 16),
        itemCount:
            controller.filteredItems.length +
            (controller.isLoading.value ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == controller.filteredItems.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          final item = controller.filteredItems[index];
          return _buildListTile(
            context,
            item,
            item['type'],
            item['id'],
            controller,
          );
        },
      );
    });
  }

  Widget _buildListTile(
    context,
    Map<String, dynamic> data,
    String type,
    String docId,
    LeadListController controller,
  ) {
    final statusColor = _getStatusColor(data['status']);
    final isLead = type == 'Lead';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      color: Colors.white,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: InkWell(
        onTap: () => _navigateToDetails(data, type, docId),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row with Icon and Type Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon Container
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isLead
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isLead
                            ? Colors.orange.withOpacity(0.2)
                            : Colors.green.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      isLead
                          ? Icons.person_add_alt_1_rounded
                          : Icons.shopping_bag_rounded,
                      color: isLead ? Colors.orange[600] : Colors.green[600],
                      size: MediaQuery.of(context).size.height * 0.022,
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.05),
                  // Main Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and Date Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                data['name'] ?? 'No Name',
                                style: GoogleFonts.k2d(
                                  fontWeight: FontWeight.w600,
                                  fontSize:
                                      MediaQuery.of(context).size.height *
                                      0.018,
                                  color: Colors.black87,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            SizedBox(width: 7),
                            // Type Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isLead
                                    ? Colors.orange.withOpacity(0.15)
                                    : Colors.green.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isLead
                                      ? Colors.orange.withOpacity(0.3)
                                      : Colors.green.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                type,
                                style: GoogleFonts.k2d(
                                  color: isLead
                                      ? Colors.orange[700]
                                      : Colors.green[700],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.01,
                        ),
                        // Date and ID Row
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              controller.formatDateShort(data['createdAt']),
                              style: GoogleFonts.k2d(
                                fontSize:
                                    MediaQuery.of(context).size.height * 0.014,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Bottom Row with Additional Info
              Row(
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          data['status'] ?? 'N/A',
                          style: GoogleFonts.k2d(
                            color: statusColor,
                            fontSize: MediaQuery.of(context).size.height * 0.01,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),

                  if (data['place'] != null &&
                      data['place'].toString().isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            data['place'].toString(),
                            style: GoogleFonts.k2d(
                              fontSize:
                                  MediaQuery.of(context).size.height * 0.012,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Arrow Icon
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'warm':
        return Colors.orange;
      case 'completed':
      case 'delivered':
        return Colors.green;
      case 'hot':
        return Colors.red;
      case 'cold':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _navigateToDetails(
    Map<String, dynamic> data,
    String type,
    String docId,
  ) {
    Get.to(() => DetailPage(data: data, type: type, docId: docId));
  }
}
