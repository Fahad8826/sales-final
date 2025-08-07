import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sales/Review/review.dart';

class OrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _notesController = TextEditingController();
  String _selectedStatus = 'Pending Review';
  bool _isLoading = false;
  bool _hasBeenSaved = false; // Add this variable to track save state

  // Blue theme colors
  static const Color primaryBlue = Color(0xFF014185);
  static const Color backgroundBlue = Color(0xFFF3F9FF);
  static const Color cardBackground = Color(0xFFFAFCFF);
  static const Color borderColor = Color(0xFFE3F2FD);
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Color.fromARGB(255, 4, 39, 68);

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.order['reviewStatus'] ?? 'Pending Review';
    _notesController.text = widget.order['followUpNotes'] ?? '';

    // Check if the order has already been reviewed (saved previously)
    _hasBeenSaved = widget.order['reviewStatus'] == 'Reviewed';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _updateOrderStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _firestore.collection('Orders').doc(widget.order['docId']).update({
        'reviewStatus': _selectedStatus,
        'followUpNotes': _notesController.text,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          _hasBeenSaved = true; // Set to true after successful save
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Review updated successfully!'),
            backgroundColor: primaryBlue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        Get.off(Review());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Oops updating order failed'),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // ignore: unused_local_variable
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1200;

    // Responsive padding and sizing
    final horizontalPadding = isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0);
    final cardPadding = isDesktop ? 28.0 : (isTablet ? 24.0 : 20.0);
    final fontSize = isDesktop ? 20.0 : (isTablet ? 19.0 : 18.0);

    final deliveryDate = widget.order['deliveryDate'] is Timestamp
        ? (widget.order['deliveryDate'] as Timestamp).toDate()
        : DateTime.now();

    final formattedDate = DateFormat('dd MMMM yyyy').format(deliveryDate);
    final daysSinceDelivery = DateTime.now().difference(deliveryDate).inDays;

    final (statusText, statusColor) = switch (_selectedStatus) {
      'Reviewed' => ('Reviewed', const Color(0xFF4CAF50)),
      'Follow-up Required' => ('Follow-up Required', const Color(0xFFFF9800)),
      _ => ('Pending Review', primaryBlue),
    };

    return Scaffold(
      backgroundColor: backgroundBlue,
      appBar: AppBar(
        title: Text(
          widget.order['orderId'] ?? 'Order Details',
          style: GoogleFonts.oswald(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF014185),
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary Card
            _buildCard(
              context,
              cardPadding,
              isDesktop,
              isTablet,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        color: primaryBlue,
                        size: isDesktop ? 26 : (isTablet ? 24 : 22),
                      ),
                      SizedBox(width: isDesktop ? 16 : 12),
                      Text(
                        'Order Summary',
                        style: GoogleFonts.k2d(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const Spacer(),
                      _buildStatusChip(statusText, statusColor, isTablet),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(height: 1, color: borderColor),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    'Order ID',
                    widget.order['orderId'] ?? 'N/A',
                    isTablet,
                  ),
                  _buildInfoRow(
                    'Customer Name',
                    widget.order['name'] ?? 'N/A',
                    isTablet,
                  ),
                  _buildInfoRow(
                    'Primary Phone',
                    widget.order['phone1'] ?? 'N/A',
                    isTablet,
                  ),
                  _buildInfoRow(
                    'Secondary Phone',
                    widget.order['phone2'] ?? 'N/A',
                    isTablet,
                  ),
                  _buildInfoRow(
                    'remark',
                    widget.order['remark'] ?? 'N/A',
                    isTablet,
                  ),
                  _buildInfoRow('Delivery Date', formattedDate, isTablet),
                  _buildInfoRow(
                    'Days Since Delivery',
                    '$daysSinceDelivery days',
                    isTablet,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Product Details Card
            if (widget.order['products'] != null &&
                (widget.order['products'] as List).isNotEmpty) ...[
              _buildCard(
                context,
                cardPadding,
                isDesktop,
                isTablet,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2,
                          color: primaryBlue,
                          size: isDesktop ? 26 : (isTablet ? 24 : 22),
                        ),
                        SizedBox(width: isDesktop ? 16 : 12),
                        Text(
                          'Products',
                          style: GoogleFonts.k2d(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(height: 1, color: borderColor),
                    const SizedBox(height: 16),
                    ...((widget.order['products'] as List?) ?? []).map<Widget>((
                      product,
                    ) {
                      return _buildProductCard(product, isTablet, isDesktop);
                    }).toList(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Follow-up Actions Card - Only show if not saved yet
            if (!_hasBeenSaved)
              _buildCard(
                context,
                cardPadding,
                isDesktop,
                isTablet,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.edit_note,
                          color: primaryBlue,
                          size: isDesktop ? 26 : (isTablet ? 24 : 22),
                        ),
                        SizedBox(width: isDesktop ? 16 : 12),
                        Text(
                          'Update Follow-up Status',
                          style: GoogleFonts.k2d(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(height: 1, color: borderColor),
                    const SizedBox(height: 20),

                    Text(
                      'Review Status',
                      style: GoogleFonts.k2d(
                        fontWeight: FontWeight.w500,
                        fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: primaryBlue,
                            width: 2,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 20 : 16,
                          vertical: isDesktop ? 16 : 12,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Pending Review',
                          child: Text('Pending Review'),
                        ),
                        DropdownMenuItem(
                          value: 'Reviewed',
                          child: Text('Reviewed'),
                        ),
                        DropdownMenuItem(
                          value: 'Follow-up Required',
                          child: Text('Follow-up Required'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'Notes',
                      style: GoogleFonts.k2d(
                        fontWeight: FontWeight.w500,
                        fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      maxLines: isDesktop ? 5 : 4,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: primaryBlue,
                            width: 2,
                          ),
                        ),
                        hintText:
                            'Add follow-up notes, customer feedback, or action items...',
                        hintStyle: GoogleFonts.k2d(
                          color: Colors.grey[500],
                          fontSize: isDesktop ? 15 : 14,
                        ),
                        contentPadding: EdgeInsets.all(isDesktop ? 16 : 12),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: isDesktop ? 32 : 24),

            // Action Buttons - Only show if not saved yet
            if (!_hasBeenSaved)
              _buildActionButtons(context, isDesktop, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    double padding,
    bool isDesktop,
    bool isTablet, {
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.05),
            blurRadius: isDesktop ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(padding: EdgeInsets.all(padding), child: child),
    );
  }

  Widget _buildStatusChip(String text, Color color, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 12 : 10,
        vertical: isTablet ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.k2d(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: isTablet ? 10 : 7,
        ),
      ),
    );
  }

  Widget _buildProductCard(dynamic product, bool isTablet, bool isDesktop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isDesktop ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'] ?? 'Product Name',
                  style: GoogleFonts.k2d(
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                    fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quantity: ${product['quantity'] ?? 'N/A'}',
                  style: GoogleFonts.k2d(
                    color: textSecondary,
                    fontSize: isDesktop ? 14 : 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${(product['price'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
            style: GoogleFonts.k2d(
              fontWeight: FontWeight.w700,
              color: primaryBlue,
              fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    bool isDesktop,
    bool isTablet,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: isDesktop ? 18 : 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: const BorderSide(color: primaryBlue),
              foregroundColor: primaryBlue,
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.k2d(
                fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(width: isDesktop ? 20 : 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _updateOrderStatus,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: isDesktop ? 18 : 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: primaryBlue.withOpacity(0.6),
            ),
            child: _isLoading
                ? SizedBox(
                    height: isDesktop ? 22 : 20,
                    width: isDesktop ? 22 : 20,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Update Order',
                    style: GoogleFonts.k2d(
                      fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isTablet ? 140 : 130,
            child: Text(
              label,
              style: GoogleFonts.k2d(
                color: textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: isTablet ? 15 : 14,
              ),
            ),
          ),
          Text(': ', style: GoogleFonts.k2d(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.k2d(
                fontWeight: FontWeight.w600,
                color: textPrimary,
                fontSize: isTablet ? 15 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
