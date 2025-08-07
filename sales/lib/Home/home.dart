import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sales/Home/home_controller.dart';
import 'package:sales/micservice.dart';

class Home extends StatelessWidget {
  final HomeController controller = Get.put(HomeController());
  final MicController controllerMic = Get.put(MicController());
  Home({super.key});
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Request microphone permission and start mic service
      controllerMic.requestMicPermissionAndStart();
      await Future.delayed(Duration(milliseconds: 300));
      controllerMic.refreshMicServiceOffer();
      await controller.fetchCounts();
    });
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        onRefresh: () async {
          await controller.fetchCounts();
          await controller.getCurrentLocation();
        },
        color: Colors.white,
        backgroundColor: Colors.blue,
        displacement: 40,
        strokeWidth: 3.5,
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(), // important!
          children: [
            _buildHeader(),
            _buildStatsSection(context),
            SizedBox(height: MediaQuery.of(context).size.height * 0.04),
            _buildQuickActions(context),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Color(0xFF014185),
      elevation: 0,

      title: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Dashboard',
          style: GoogleFonts.oswald(
            color: Colors.white,
            fontSize: MediaQuery.of(context).size.height * 0.03,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: Icon(
            Icons.account_circle,
            color: Colors.white,
            size: MediaQuery.of(context).size.height * 0.035,
          ),
          onPressed: () {
            Get.toNamed('/profile');
          },
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return FutureBuilder<String>(
      future: controller.fetchUserName(), // Fetches name from Firebase
      builder: (context, snapshot) {
        String userName = '...';
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          userName = snapshot.data!;
        }
        return Container(
          decoration: BoxDecoration(
            color: Color(0xFF014185),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(
                MediaQuery.of(context).size.height * 0.03,
              ),
              bottomRight: Radius.circular(
                MediaQuery.of(context).size.height * 0.03,
              ),
            ),
          ),

          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, $userName',
                          style: GoogleFonts.k2d(
                            fontSize:
                                MediaQuery.of(context).size.height * 0.022,

                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.01,
                        ),
                        Text(
                          'Here\'s what\'s happening with your business today',
                          style: GoogleFonts.k2d(
                            fontSize:
                                MediaQuery.of(context).size.height * 0.016,

                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsSection(context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.height * 0.02,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).size.height * 0.02,
            ),
            child: Text(
              'Overview',
              style: GoogleFonts.k2d(
                fontSize: MediaQuery.of(context).size.height * 0.022,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.016),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E293B).withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Activity',
                      style: GoogleFonts.k2d(
                        fontSize: MediaQuery.of(context).size.height * 0.02,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Obx(
                      () => Text(
                        '${controller.totalActivity}',
                        style: GoogleFonts.k2d(
                          fontSize: MediaQuery.of(context).size.height * 0.037,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.height * 0.01),
                    Padding(
                      padding: EdgeInsets.only(bottom: 6),
                      child: Text(
                        'leads + orders',
                        style: GoogleFonts.k2d(
                          fontSize: MediaQuery.of(context).size.height * 0.015,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.016),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.01,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Obx(
                          () => FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: controller.progressValue,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Get.offAllNamed('/leadlist');
                    },
                    child: Text(
                      'Details',
                      style: GoogleFonts.k2d(
                        fontSize: MediaQuery.of(context).size.height * 0.016,
                        color: Color(0xFF014185),
                        fontStyle: FontStyle.italic,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF014185),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.k2d(
              fontSize: MediaQuery.of(context).size.height * 0.02,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          _buildActionGrid(context),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
        ],
      ),
    );
  }

  Widget _buildActionGrid(context) {
    final menuItems = [
      {
        'title': 'New Lead',
        'subtitle': 'Manage your leads',
        'icon': 'assets/svg/lead.svg',
        'color': const Color(0xFF014185),
        'count': () => '', // Static value
        'route': '/leadmanagment',
      },
      {
        'title': 'Follow Up',
        'subtitle': 'Pending follow-ups',
        'icon': 'assets/svg/follow_up.svg',
        'color': const Color(0xFF014185),
        'count': () =>
            controller.totalLeads.value.toString(), // Directly use totalLeads
        'route': '/followup',
      },
      {
        'title': 'Order Management',
        'subtitle': 'Track orders',
        'icon': 'assets/svg/order.svg',
        'color': const Color(0xFF014185),
        'count': () =>
            controller.totalOrders.value.toString(), // Directly use totalOrders
        'route': '/ordermanagement',
      },
      {
        'title': 'Post Sale Follow Up',
        'subtitle': 'Customer feedback',
        'icon': 'assets/svg/review.svg',
        'color': const Color(0xFF014185),
        'count': () => controller.totalPostSaleFollowUp.value
            .toString(), // Directly use totalPostSaleFollowUp
        'route': '/review',
      },
      {
        'title': 'Complaint',
        'subtitle': 'Support tickets',
        'icon': 'assets/svg/complaint.svg',
        'color': const Color(0xFF014185),
        'count': () => '', // Static value
        'route': '/complaint',
      },
    ];

    return Column(
      children: menuItems.asMap().entries.map((entry) {
        int index = entry.key;
        Map<String, dynamic> item = entry.value;

        return Obx(() {
          debugPrint(
            "Obx rebuilding for ${item['title']}, count: ${item['count']()}",
          );
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  controller.selectMenuItem(index);
                  Future.delayed(const Duration(milliseconds: 120), () {
                    Get.toNamed(item['route'] as String);
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: controller.selectedIndex.value == index
                        ? const Color(0xFFF8FAFC)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: controller.selectedIndex.value == index
                          ? (item['color'] as Color)
                          : const Color(0xFFE2E8F0),
                      width: controller.selectedIndex.value == index ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E293B).withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: SvgPicture.asset(
                            item['icon'] as String,
                            color: item['color'] as Color,
                            width: 24,
                            height: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] as String,
                              style: GoogleFonts.k2d(
                                fontSize:
                                    MediaQuery.of(context).size.height * 0.02,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['subtitle'] as String,
                              style: GoogleFonts.k2d(
                                fontSize:
                                    MediaQuery.of(context).size.height * 0.014,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Text(
                              item['count'](), // Call the function to get the current count
                              style: GoogleFonts.k2d(
                                fontSize:
                                    MediaQuery.of(context).size.height * 0.012,
                                fontWeight: FontWeight.w600,
                                color: item['color'] as Color,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: const Color(0xFF94A3B8),
                            size: 14,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
      }).toList(),
    );
  }
}
