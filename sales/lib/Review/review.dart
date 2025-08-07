import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sales/Review/individual_review.dart';
import 'package:sales/Review/review_controller.dart';

class Review extends StatelessWidget {
  const Review({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReviewController());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      controller.refreshData();
    });
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Post Sale Follow-up',
          style: GoogleFonts.oswald(
            fontWeight: FontWeight.w600,
            fontSize: MediaQuery.of(context).size.height * 0.025,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF014185),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          controller.refreshData();
        },
        color: Colors.white,
        backgroundColor: Colors.blue,
        displacement: 40,
        strokeWidth: 3.5,
        child: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Column(
              children: [
                // Search bar
                _SearchBar(onChanged: controller.onSearchChanged),
                // Tab bar
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: controller.tabController,
                    labelColor: Theme.of(context).primaryColor,
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: Theme.of(context).primaryColor,
                    isScrollable: true,
                    labelStyle: GoogleFonts.k2d(
                      fontSize: MediaQuery.of(context).size.height * 0.015,
                    ),
                    tabs: const [
                      Tab(text: 'All Orders'),
                      Tab(text: 'Pending'),
                      Tab(text: 'Completed'),
                      Tab(text: 'Follow-up Required'),
                    ],
                  ),
                ),
                // Orders list
                Expanded(
                  child: Obx(() {
                    if (controller.orders.isEmpty &&
                        controller.searchQuery.value.isNotEmpty) {
                      return _EmptyWidget(
                        tabIndex: controller.tabController.index,
                      );
                    }
                    return TabBarView(
                      controller: controller.tabController,
                      children: [
                        // Tab 0: All Orders
                        controller.orders.isEmpty
                            ? const _EmptyWidget(tabIndex: 0)
                            : _OrdersList(
                                orders: controller.orders,
                                tabIndex: 0,
                              ),

                        // Tab 1: Pending
                        () {
                          final pendingOrders = controller.orders
                              .where(
                                (o) =>
                                    (o['reviewStatus'] ?? 'Pending Review') ==
                                    'Pending Review',
                              )
                              .toList();
                          return pendingOrders.isEmpty
                              ? const _EmptyWidget(tabIndex: 1)
                              : _OrdersList(orders: pendingOrders, tabIndex: 1);
                        }(),

                        // Tab 2: Completed
                        () {
                          final completedOrders = controller.orders
                              .where(
                                (o) =>
                                    (o['reviewStatus'] ?? 'Pending Review') ==
                                    'Reviewed',
                              )
                              .toList();
                          return completedOrders.isEmpty
                              ? const _EmptyWidget(tabIndex: 2)
                              : _OrdersList(
                                  orders: completedOrders,
                                  tabIndex: 2,
                                );
                        }(),

                        // Tab 3: Follow-up Required
                        () {
                          final followUpOrders = controller.orders
                              .where(
                                (o) =>
                                    (o['reviewStatus'] ?? 'Pending Review') ==
                                    'Follow-up Required',
                              )
                              .toList();
                          return followUpOrders.isEmpty
                              ? const _EmptyWidget(tabIndex: 3)
                              : _OrdersList(
                                  orders: followUpOrders,
                                  tabIndex: 3,
                                );
                        }(),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by customer name or order ID...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        onChanged: onChanged,
      ),
    );
  }
}

// ignore: unused_element
class _ErrorWidget extends StatelessWidget {
  final Object? error;

  // ignore: unused_element_parameter
  const _ErrorWidget({this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          SizedBox(height: MediaQuery.of(context).size.height * 0.016),
          Text(
            'Oops! loading orders',
            style: GoogleFonts.k2d(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            error?.toString() ?? 'Unknown Problem',
            style: GoogleFonts.k2d(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Get.put(ReviewController()).refreshData(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyWidget extends StatelessWidget {
  final int tabIndex;

  const _EmptyWidget({required this.tabIndex});

  @override
  Widget build(BuildContext context) {
    final emptyMessage = switch (tabIndex) {
      1 => 'No pending reviews',
      2 => 'No completed reviews',
      3 => 'No follow-up required orders',
      _ => 'No orders found',
    };

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            emptyMessage,
            style: GoogleFonts.k2d(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final int tabIndex;

  const _OrdersList({required this.orders, required this.tabIndex});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: orders.length,
      itemBuilder: (context, index) =>
          _OrderCard(order: orders[index], index: index),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final int index;

  const _OrderCard({required this.order, required this.index});

  @override
  Widget build(BuildContext context) {
    DateTime? deliveryDate;
    final rawDate = order['deliveryDate'];

    if (rawDate is Timestamp) {
      deliveryDate = rawDate.toDate();
    } else if (rawDate is String) {
      deliveryDate = DateTime.tryParse(rawDate);
    }

    final formattedDate = deliveryDate != null
        ? DateFormat('dd MMM yyyy').format(deliveryDate)
        : 'N/A';
    log("Formatted Date: $formattedDate");
    final daysSinceDelivery = deliveryDate != null
        ? DateTime.now().difference(deliveryDate).inDays
        : 0;

    final reviewStatus = order['reviewStatus'] ?? 'Pending Review';

    final (statusColor, statusIcon) = switch (reviewStatus) {
      'Reviewed' => (Colors.green, Icons.check_circle),
      'Follow-up Required' => (Colors.orange, Icons.priority_high),
      _ => (Colors.red, Icons.pending),
    };

    return Card(
      color: Colors.white,
      elevation: 3,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        onTap: () {
          Get.to(() => OrderDetailsScreen(order: order));
        },
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                          child: Row(
                            children: [
                              Text(
                                order['orderId'] ?? 'Order #${index + 1}',
                                style: GoogleFonts.k2d(
                                  fontSize:
                                      MediaQuery.of(context).size.height *
                                      0.017,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                  border: Border.all(
                                    color: statusColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      statusIcon,
                                      size: 12,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      reviewStatus,
                                      style: GoogleFonts.k2d(
                                        fontSize: 10,
                                        color: statusColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            order['phone1'] ?? 'Customer Name',
                            style: GoogleFonts.k2d(
                              fontSize:
                                  MediaQuery.of(context).size.height * 0.014,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_shipping,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      order['deliveryDate'] != null
                          ? 'Delivered: $formattedDate'
                          : 'Delivery Date: Not Available',
                      style: GoogleFonts.k2d(
                        fontSize: MediaQuery.of(context).size.height * 0.014,
                        color: Colors.grey,
                      ),
                    ),
                    const Spacer(),
                    if (order['deliveryDate'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: daysSinceDelivery > 14
                              ? Colors.red[50]
                              : Colors.blue[50],
                          borderRadius: const BorderRadius.all(
                            Radius.circular(8),
                          ),
                        ),
                        child: Text(
                          '$daysSinceDelivery days ago',
                          style: GoogleFonts.k2d(
                            fontSize: 12,
                            color: daysSinceDelivery > 14
                                ? Colors.red
                                : Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
