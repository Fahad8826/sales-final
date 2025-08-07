import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sales/Lead/lead_list.dart';

class DetailPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final String type;
  final String docId;

  const DetailPage({
    super.key,
    required this.data,
    required this.type,
    required this.docId,
  });

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'completed':
        return Colors.green;
      case 'warm':
        return Colors.orange;
      case 'cancelled':
      case 'hot':
        return Colors.red;
      case 'cold':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
    required double fontSize,
    required double iconSize,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: fontSize * 0.4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: iconSize, color: Colors.grey[600]),
          SizedBox(width: iconSize * 0.6),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.k2d(
                fontSize: fontSize * 0.9,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.k2d(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDivider(String title, double fontSize) {
    return Padding(
      padding: EdgeInsets.only(top: fontSize, bottom: fontSize * 0.5),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: fontSize * 0.8),
            child: Text(
              title,
              style: GoogleFonts.k2d(
                fontSize: fontSize * 0.8,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLead = type == 'Lead';
    final id = isLead ? data['leadId'] : data['orderId'];
    final status = data['status'] ?? 'N/A';

    // Get screen size and orientation using MediaQuery
    final size = MediaQuery.of(context).size;
    final double screenWidth = size.width;
    final double baseFontSize = screenWidth * 0.035;
    final double iconSize = screenWidth * 0.05;
    final double avatarRadius = screenWidth * 0.07;
    final double cardPadding = screenWidth * 0.04;
    final double containerPadding = screenWidth * 0.03;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '$type Details',
          style: GoogleFonts.oswald(
            fontWeight: FontWeight.w600,
            fontSize: MediaQuery.of(context).size.height * 0.025,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LeadList()),
            );
          },
          icon: Icon(Icons.arrow_back, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF014185),
        elevation: 1,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          children: [
            // Single Card with All Details
            Card(
              color: Colors.white,
              margin: EdgeInsets.symmetric(vertical: cardPadding * 0.5),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(cardPadding * 0.6),
              ),
              child: Padding(
                padding: EdgeInsets.all(cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Row(
                      children: [
                        CircleAvatar(
                          radius: avatarRadius,
                          backgroundColor: isLead
                              ? Colors.blue[50]
                              : Colors.green[50],
                          child: Icon(
                            isLead ? Icons.person_add : Icons.shopping_cart,
                            size: avatarRadius * 1.2,
                            color: isLead
                                ? Colors.blue[700]
                                : Colors.green[700],
                          ),
                        ),
                        SizedBox(width: cardPadding),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['name'] ?? 'No Name',
                                style: GoogleFonts.k2d(
                                  fontSize: baseFontSize * 1.3,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: baseFontSize * 0.3),
                              if (id != null)
                                Text(
                                  '$type ID: $id',
                                  style: GoogleFonts.k2d(
                                    fontSize: baseFontSize * 0.9,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: containerPadding * 1.2,
                            vertical: containerPadding * 0.6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              containerPadding * 1.2,
                            ),
                            border: Border.all(
                              color: _getStatusColor(status).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: GoogleFonts.k2d(
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.w600,
                              fontSize: baseFontSize * 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Contact Information
                    _buildSectionDivider('CONTACT INFORMATION', baseFontSize),
                    _buildInfoRow(
                      label: 'Customer ID',
                      value: data['customerId'] ?? 'N/A',
                      icon: Icons.account_circle,
                      fontSize: baseFontSize,
                      iconSize: iconSize,
                    ),
                    _buildInfoRow(
                      label: 'Primary Phone',
                      value: data['phone1'] ?? 'N/A',
                      icon: Icons.phone,
                      fontSize: baseFontSize,
                      iconSize: iconSize,
                    ),
                    if (data['phone2'] != null &&
                        data['phone2'].toString().isNotEmpty)
                      _buildInfoRow(
                        label: 'Secondary Phone',
                        value: data['phone2'],
                        icon: Icons.phone_callback,
                        fontSize: baseFontSize,
                        iconSize: iconSize,
                      ),
                    _buildInfoRow(
                      label: 'Address',
                      value: data['address'] ?? 'N/A',
                      icon: Icons.location_on,
                      fontSize: baseFontSize,
                      iconSize: iconSize,
                    ),
                    _buildInfoRow(
                      label: 'Place',
                      value: data['place'] ?? 'N/A',
                      icon: Icons.place,
                      fontSize: baseFontSize,
                      iconSize: iconSize,
                    ),

                    // Product Information
                    _buildSectionDivider('PRODUCT INFORMATION', baseFontSize),
                    _buildInfoRow(
                      label: 'Product Number',
                      value: data['productID'] ?? 'N/A',
                      icon: Icons.inventory,
                      fontSize: baseFontSize,
                      iconSize: iconSize,
                    ),
                    _buildInfoRow(
                      label: 'Number of Items',
                      value: data['nos']?.toString() ?? 'N/A',
                      icon: Icons.numbers,
                      fontSize: baseFontSize,
                      iconSize: iconSize,
                    ),

                    // Additional Information
                    _buildSectionDivider(
                      'ADDITIONAL INFORMATION',
                      baseFontSize,
                    ),
                    _buildInfoRow(
                      label: 'Remarks',
                      value: data['remark'] ?? 'N/A',
                      icon: Icons.note,
                      fontSize: baseFontSize,
                      iconSize: iconSize,
                    ),
                    _buildInfoRow(
                      label: 'Created At',
                      value: formatDate(data['createdAt']),
                      icon: Icons.calendar_today,
                      fontSize: baseFontSize,
                      iconSize: iconSize,
                    ),

                    if (isLead && data['followUpDate'] != null)
                      _buildInfoRow(
                        label: 'Follow-Up Date',
                        value: formatDate(data['followUpDate']),
                        icon: Icons.schedule,
                        fontSize: baseFontSize,
                        iconSize: iconSize,
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: cardPadding),
          ],
        ),
      ),
    );
  }
}
