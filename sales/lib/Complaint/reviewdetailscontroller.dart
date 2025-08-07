import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class ResponseDetailController extends GetxController {
  final Map<String, dynamic> responseData;
  final String documentId;

  ResponseDetailController({
    required this.responseData,
    required this.documentId,
  });

  final RxString adminEmail = 'Loading...'.obs;

  @override
  void onInit() {
    super.onInit();
    _fetchAdminEmail();
  }

  Future<void> _fetchAdminEmail() async {
    try {
      final adminId = responseData['respondedBy'];
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(adminId)
          .get();

      if (adminDoc.exists) {
        final data = adminDoc.data() as Map<String, dynamic>?;

        String? email =
            data?['email'] ??
            data?['Email'] ??
            data?['emailAddress'] ??
            data?['userEmail'] ??
            data?['adminEmail'];

        adminEmail.value = email ?? 'Admin Email Not Found';
      } else {
        adminEmail.value = 'Admin Not Found';
      }
    } catch (e) {
      adminEmail.value = 'Oops! loading admin email';
    }
  }

  String formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
