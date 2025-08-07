import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ResponseController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Stream<QuerySnapshot> get responseStream {
    return _firestore
        .collection('complaint_responses')
        .where('statusChanged', isEqualTo: true)
        .where('userId', isEqualTo: currentUserId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<String> getAdminEmail(String adminId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('admins')
          .doc(adminId)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['email'] ??
            data['Email'] ??
            data['emailAddress'] ??
            data['userEmail'] ??
            'Unknown Admin';
      } else {
        return 'Admin Not Found';
      }
    } catch (e) {
      return 'Oops! Loading Admin';
    }
  }

  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'in-progress':
        return Colors.orange;
      case 'pending':
        return Colors.red;
      case 'rejected':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Icons.check_circle;
      case 'in-progress':
        return Icons.hourglass_empty;
      case 'pending':
        return Icons.pending;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }
}
