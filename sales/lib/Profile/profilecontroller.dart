import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

class ProfileController extends GetxController {
  var userData = Rxn<Map<String, dynamic>>();
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserProfile();
  }

  void fetchUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      userData.value = doc.data();
    }
    isLoading.value = false;
  }



  Future<void> logout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'isLoggedIn': false, 'deviceId': null},
      );
      await FirebaseAuth.instance.signOut();
    }
  }
}
