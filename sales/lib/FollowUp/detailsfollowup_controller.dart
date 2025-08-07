import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sales/FollowUp/followup.dart';

class LeadDetailsController extends GetxController {
  final String? leadId; // To receive leadId for existing leads

  LeadDetailsController({this.leadId});

  // Text Editing Controllers
  final nameController = TextEditingController();
  final placeController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final phone2Controller = TextEditingController();
  final nosController = TextEditingController();
  final remarkController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  // Rx Variables for reactive UI updates
  var selectedProductId = Rxn<String>();
  var selectedStatus = Rxn<String>();
  var selectedTime = Rxn<TimeOfDay>();
  var followUpDate = Rxn<DateTime>();
  var productImageUrl = Rxn<String>();
  var productIdList = <String>[].obs;
  final makerList = <Map<String, dynamic>>[].obs;
  final selectedMakerId = RxnString();
  final statusList = ['HOT', 'WARM', 'COOL'].obs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  var productStockMap = <String, int>{}.obs;

  // New Rx variables for managing page state
  var isLoading = true.obs;
  var isEditing = false.obs; // Controls edit mode
  var isUpdateMode = false.obs; // True if editing an existing lead

  // Private variable to store the actual Firestore document ID of the lead
  String? _currentLeadDocId;

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
    fetchMakers();

    if (leadId != null) {
      isUpdateMode.value = true;
      isEditing.value = false; // Start in view mode for existing leads
      initializeLeadDetails(leadId!);
    }
    ever(selectedStatus, (String? status) {
      if (status != 'HOT') {
        selectedMakerId.value = null;
      }
      if (status == 'HOT') {
        followUpDate.value = null;
      }
    });
  }

  // Method to fetch and populate lead details for an existing lead
  Future<void> initializeLeadDetails(String leadFirebaseDocId) async {
    try {
      isLoading.value = true;
      final leadDoc = await _firestore
          .collection('Leads')
          .doc(leadFirebaseDocId)
          .get();

      if (leadDoc.exists) {
        _currentLeadDocId = leadDoc.id; // Store the document ID
        final data = leadDoc.data()!;

        nameController.text = data['name'] ?? '';
        placeController.text = data['place'] ?? '';
        addressController.text = data['address'] ?? '';
        phoneController.text = data['phone1'] ?? '';
        phone2Controller.text = data['phone2'] ?? '';
        nosController.text = data['nos']?.toString() ?? '';
        remarkController.text = data['remark'] ?? '';

        selectedProductId.value = data['productID'] as String?;
        selectedStatus.value = data['status'] as String?;
        selectedMakerId.value = data['makerId'] as String?;

        if (data['followUpDate'] != null) {
          followUpDate.value = (data['followUpDate'] as Timestamp).toDate();
        } else {
          followUpDate.value = null;
        }

        if (selectedProductId.value != null) {
          await fetchProductImage(selectedProductId.value!);
        }
      } else {
        Get.snackbar(
          'Oops!',
          'Lead not found!',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        Get.back();
      }
    } catch (e) {
      Get.snackbar(
        'Oops!',
        'Failed to load lead details: $e',
        backgroundColor: Colors.white,
        colorText: Colors.red,
      );
      Get.back();
    } finally {
      isLoading.value = false;
    }
  }

  // Toggle between view and edit modes
  void toggleEditing() {
    if (isEditing.value) {
      // If currently editing, try to save
      saveLead();
    }
    isEditing.value = !isEditing.value;
  }

  Future<void> fetchMakers() async {
    try {
      makerList.clear(); // Clear existing data
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'maker')
          .get();

      makerList.value = snapshot.docs.map((doc) {
        return {'id': doc.id, 'name': doc['name'] ?? 'Unknown'};
      }).toList();

      if (makerList.isEmpty) {
        Get.snackbar(
          'Warning',
          'No makers found',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Oops!',
        'Failed to load makers: $e',
        backgroundColor: Colors.white,
        colorText: Colors.red,
      );
    }
  }

  Future<void> fetchProducts() async {
    try {
      final snapshot = await _firestore.collection('products').get();

      final products = <String>[];
      final stockMap = <String, int>{};

      for (var doc in snapshot.docs) {
        final id = doc.data()['id']?.toString() ?? doc.id;
        final stock = doc.data()['stock'] ?? 0;
        products.add(id);
        stockMap[id] = stock;
      }

      productIdList.assignAll(products);
      productStockMap.assignAll(stockMap);

      debugPrint('Fetched product IDs: $products');
      debugPrint('Fetched product stock: $stockMap');
    } catch (e) {
      Get.snackbar(
        'Oops!',
        'Oops! fetching products: $e',
        backgroundColor: Colors.white,
        colorText: Colors.red,
      );
    }
  }

  Future<void> fetchProductImage(String productId) async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('id', isEqualTo: productId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint('No document found for product ID: $productId');
        productImageUrl.value = null;
        return;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();
      final imageUrl = data['imageUrl'] as String?;
      debugPrint('Fetched imageUrl for $productId: $imageUrl');

      productImageUrl.value = imageUrl;
    } catch (e) {
      debugPrint('Oops! fetching image for $productId: $e');
      productImageUrl.value = null;
      Get.snackbar(
        'Oops!',
        'Oops! loading image: $e',
        backgroundColor: Colors.white,
        colorText: Colors.red,
      );
    }
  }

  Future<String> _generateLeadsId() async {
    final snapshot = await _firestore
        .collection('Leads')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    int lastNumber = 0;

    if (snapshot.docs.isNotEmpty) {
      final lastId = snapshot.docs.first.data()['leadId'] as String?;
      if (lastId != null && lastId.startsWith('LEA')) {
        final numberPart = int.tryParse(lastId.replaceAll('LEA', '')) ?? 0;
        lastNumber = numberPart;
      }
    }

    final newNumber = lastNumber + 1;
    return 'LEA${newNumber.toString().padLeft(5, '0')}';
  }

  Future<void> saveLead() async {
    if (!formKey.currentState!.validate()) {
      Get.snackbar(
        'Oops!',
        'Please fill all required fields correctly',
        backgroundColor: Colors.white,
        colorText: Colors.red,
      );
      return;
    }

    if (selectedStatus.value != 'HOT' && followUpDate.value == null) {
      Get.snackbar(
        'Oops!',
        'Please select follow-up date for WARM/COOL status',
        backgroundColor: Colors.white,
        colorText: Colors.red,
      );
      return;
    }

    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('id', isEqualTo: selectedProductId.value)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        Get.snackbar(
          'Oops!',
          'Selected product not found',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final productDoc = querySnapshot.docs.first;
      final productIdFromDoc =
          productDoc['id']; // This is the 'id' field inside the document

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Get.snackbar(
          'Oops!',
          'User not logged in',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
      final userId = currentUser.uid;

      Map<String, dynamic> leadData = {
        'name': nameController.text,
        'place': placeController.text,
        'address': addressController.text,
        'phone1': phoneController.text,
        'phone2': phone2Controller.text.isNotEmpty
            ? phone2Controller.text
            : null,
        'productID': productIdFromDoc,
        'nos': int.tryParse(nosController.text) ?? 0,
        'remark': remarkController.text.isNotEmpty
            ? remarkController.text
            : null,
        'status': selectedStatus.value,

        'followUpDate': followUpDate.value != null
            ? Timestamp.fromDate(followUpDate.value!)
            : null,
        'followUpTime': selectedTime.value != null
            ? "${selectedTime.value!.hour.toString().padLeft(2, '0')}:${selectedTime.value!.minute.toString().padLeft(2, '0')}"
            : "",
        'salesmanID': userId,
        'isArchived': false,
      };

      if (isUpdateMode.value && _currentLeadDocId != null) {
        // Update existing lead
        await _firestore
            .collection('Leads')
            .doc(_currentLeadDocId)
            .update(leadData);
        Get.snackbar(
          'Success',
          'Lead updated successfully!',
          backgroundColor: Colors.white,
          colorText: Color(0xFF014185),
        );
      } else {
        // Create new lead
        final leadId = await _generateLeadsId();
        leadData['leadId'] = leadId;
        leadData['createdAt'] = Timestamp.now();
        await _firestore.collection('Leads').add(leadData);
        Get.snackbar(
          'Success',
          'New lead created successfully!',
          backgroundColor: Colors.white,
          colorText: Color(0xFF014185),
        );
        clearForm(); // Clear form after creating a new lead
      }
      isEditing.value = false;
      // Switch back to view mode after saving
    } catch (e) {
      Get.snackbar(
        'Oops!',
        'Oops! saving lead: $e',
        backgroundColor: Colors.white,
        colorText: Colors.red,
      );
      debugPrint('Oops! saving lead: $e');
    }
  }

  Future<void> placeOrder(String leadDocId) async {
    if (!formKey.currentState!.validate() || selectedMakerId.value == null) {
      Get.snackbar(
        'Oops!',
        'Please fill all required fields correctly',
        backgroundColor: Colors.white,
        colorText: Colors.red,
      );
      return;
    }

    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('id', isEqualTo: selectedProductId.value)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        Get.snackbar(
          'Oops!',
          'Selected product not found',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final productDoc = querySnapshot.docs.first;
      final docId = productDoc.id;
      final productId = productDoc['id'];
      final currentStock = productDoc['stock'];

      final orderedQuantity = int.tryParse(nosController.text) ?? 0;
      if (orderedQuantity <= 0) {
        Get.snackbar(
          'Oops!',
          'Invalid number of items ordered',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      if (currentStock > 0) {
        final updatedStock = currentStock - orderedQuantity;
        await _firestore.collection('products').doc(docId).update({
          'stock': updatedStock,
        });
        productStockMap[selectedProductId.value!] = updatedStock;
      }

      final newOrderId = await generateCustomOrderId();
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Get.snackbar(
          'Oops!',
          'User not logged in',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final userId = currentUser.uid;

      await _firestore.collection('Orders').add({
        'orderId': newOrderId,
        'name': nameController.text,
        'place': placeController.text,
        'address': addressController.text,
        'phone1': phoneController.text,
        'phone2': phone2Controller.text.isNotEmpty
            ? phone2Controller.text
            : null,
        'productID': productId,
        'nos': orderedQuantity,
        'remark': remarkController.text.isNotEmpty
            ? remarkController.text
            : null,
        'status': selectedStatus.value,
        'makerId': selectedMakerId.value,
        'followUpDate': followUpDate.value != null
            ? Timestamp.fromDate(followUpDate.value!)
            : null,
        'salesmanID': userId,
        'createdAt': Timestamp.now(),
        'order_status': "pending",
      });

      // ✅ Delete from Leads collection using the correct doc ID
      await _firestore.collection('Leads').doc(leadDocId).delete();

      Get.snackbar(
        'Success',
        'Order placed successfully',
        backgroundColor: Colors.white,
        colorText: Color(0xFF014185),
      );
      clearForm();
      Get.offAll(FollowupPage());
    } catch (e) {
      Get.snackbar(
        'Oops!',
        'Oops! placing order: $e',
        backgroundColor: Colors.white,
        colorText: Colors.red,
      );
    }
  }

  Future<String> generateCustomOrderId() async {
    final snapshot = await _firestore
        .collection('Orders')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    int lastNumber = 0;

    if (snapshot.docs.isNotEmpty) {
      final lastId = snapshot.docs.first.data()['orderId'] as String?;
      if (lastId != null && lastId.startsWith('ORD')) {
        final numberPart = int.tryParse(lastId.replaceAll('ORD', '')) ?? 0;
        lastNumber = numberPart;
      }
    }

    final newNumber = lastNumber + 1;
    return 'ORD${newNumber.toString().padLeft(5, '0')}';
  }

  // Adjusted button enablement logic
  bool isOrderButtonEnabled() {
    // Only enable if in view mode for an existing lead (if you want to restrict ordering to saved leads only)
    // or if creating a new lead with HOT status
    return selectedStatus.value == 'HOT' &&
        isEditing.value &&
        selectedMakerId.value != null;
  }

  void clearForm() {
    nameController.clear();
    placeController.clear();
    addressController.clear();
    phoneController.clear();
    phone2Controller.clear();
    nosController.clear();
    remarkController.clear();

    selectedProductId.value = null;
    selectedStatus.value = null;
    selectedMakerId.value = null;
    followUpDate.value = null;
    productImageUrl.value = null;
    isUpdateMode.value = false; // Reset to creation mode
    isEditing.value = true; // For new leads, editing is allowed by default
    _currentLeadDocId = null; // Clear the current lead ID
  }

  String? validateName(String? value) {
    if (value == null || value.isEmpty) return 'Name is required';
    if (value.length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? validatePlace(String? value) {
    if (value == null || value.isEmpty) return 'Place is required';
    return null;
  }

  String? validateAddress(String? value) {
    if (value == null || value.isEmpty) return 'Address is required';
    if (value.length < 5) return 'Address must be at least 5 characters';
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Phone is required';
    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      return 'Enter valid 10-digit phone number';
    }
    return null;
  }

  String? validatePhone2(String? value) {
    if (value == null || value.isEmpty) return null; // Optional field

    if (value == phoneController.text) {
      return 'Phone 2 should be different from Phone 1';
    }

    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      return 'Enter a valid 10-digit phone number';
    }

    return null;
  }

  String? validateNos(String? value) {
    if (value == null || value.isEmpty) return 'Quantity (NOS) is required';
    final int? nos = int.tryParse(value);
    if (nos == null || nos <= 0) return 'Enter a valid number greater than 0';
    return null;
  }

  Future<void> archiveDocument(String leadDocId) async {
    try {
      await _firestore.collection('Leads').doc(leadDocId).update({
        'isArchived': true,
      });

      Get.snackbar(
        'Success',
        'Lead archived successfully',
        backgroundColor: Colors.white,
        colorText: Colors.red,
      );
      Navigator.of(
        Get.context!,
      ).pop(); // Optional: pop the screen after archiving
    } catch (e) {
      Get.snackbar(
        'Oops!',
        'Failed to archive lead: $e',
        backgroundColor: Colors.white,
        colorText: Colors.red,
      );
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    placeController.dispose();
    addressController.dispose();
    phoneController.dispose();
    phone2Controller.dispose();
    nosController.dispose();
    remarkController.dispose();
    // Dispose balance controller
    super.onClose();
  }
}
