// import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sales/Profile/profilecontroller.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = Get.put(ProfileController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.oswald(
            fontWeight: FontWeight.w600,
            fontSize: MediaQuery.of(context).size.height * 0.025,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF014185),
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
          );
        }

        final data = controller.userData.value;
        if (data == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No profile data found',
                  style: GoogleFonts.oswald(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              // Profile Header Section
              Container(
                width: double.infinity,
                color: Color(0xFF014185),
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    // Profile Image
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: data['imageUrl'] != null
                              ? CircleAvatar(
                                  radius: 60,
                                  backgroundImage: NetworkImage(
                                    data['imageUrl'],
                                  ),
                                )
                              : CircleAvatar(
                                  radius: 60,
                                  backgroundColor: const Color(0xFF014185),
                                  child: Text(
                                    _getInitials(data['name'] ?? ''),
                                    style: GoogleFonts.k2d(
                                      fontSize:
                                          MediaQuery.of(context).size.height *
                                          0.029,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF014185),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                    // Name
                    Text(
                      data['name'] ?? 'Unknown User',
                      style: GoogleFonts.k2d(
                        fontSize: MediaQuery.of(context).size.height * 0.025,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Email
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        data['email'] ?? 'No email provided',
                        style: GoogleFonts.k2d(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              // Profile Details Section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Personal Information',
                        style: GoogleFonts.k2d(
                          fontSize: MediaQuery.of(context).size.height * 0.02,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    _buildInfoItem(
                      context,
                      icon: Icons.phone_outlined,
                      label: 'Phone Number',
                      value: data['phone'],
                      isFirst: true,
                    ),
                    _buildInfoItem(
                      context,

                      icon: Icons.person_outline,
                      label: 'Gender',
                      value: data['gender'],
                    ),
                    _buildInfoItem(
                      context,

                      icon: Icons.cake_outlined,
                      label: 'Age',
                      value: data['age']?.toString(),
                    ),
                    _buildInfoItem(
                      context,

                      icon: Icons.location_on_outlined,
                      label: 'Address',
                      value: data['address'],
                    ),
                    _buildInfoItem(
                      context,

                      icon: Icons.place_outlined,
                      label: 'Place',
                      value: data['place'],
                      isLast: true,
                    ),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Get.defaultDialog(
                            title: 'Confirm Logout',
                            middleText: 'Are you sure you want to log out?',
                            textConfirm: 'Yes',
                            textCancel: 'No',
                            confirmTextColor: Colors.white,
                            onConfirm: () async {
                              await controller.logout();
                              Get.offAllNamed('/login');
                            },
                            onCancel: () {},
                            buttonColor: const Color.fromARGB(255, 26, 67, 121),
                          );
                        },
                        icon: const Icon(Icons.settings_outlined),
                        label: Text(
                          'Log Out',
                          style: GoogleFonts.k2d(
                            color: Color.fromARGB(255, 26, 67, 121),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(
                            color: Color.fromARGB(255, 26, 67, 121),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
            ],
          ),
        );
      }),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    List<String> nameParts = name.split(' ');
    if (nameParts.length == 1) {
      return nameParts[0][0].toUpperCase();
    }
    return (nameParts[0][0] + nameParts[1][0]).toUpperCase();
  }

  Widget _buildInfoItem(
    context, {
    required IconData icon,
    required String label,
    String? value,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: isFirst
              ? BorderSide.none
              : const BorderSide(color: Color(0xFFF1F5F9)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF64748B), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.k2d(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.014),
                  Text(
                    value ?? 'Not provided',
                    style: GoogleFonts.k2d(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: value != null
                          ? const Color(0xFF1E293B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
