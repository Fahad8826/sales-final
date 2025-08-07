import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sales/Home/home.dart';

class LeadManagementController extends GetxController {
  final nameController = TextEditingController();
  final placeController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final phone2Controller = TextEditingController();
  final nosController = TextEditingController();
  final remarkController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  var isSaving = false.obs;
  var isOrdering = false.obs;
  var selectedProductId = Rxn<String>();
  var selectedStatus = Rxn<String>();
  var followUpDate = Rxn<DateTime>();
  var selectedTime = Rxn<TimeOfDay>();
  var productImageUrl = Rxn<String>();
  var productIdList = <String>[].obs;
  var selectedPlace = RxnString();
  final makerList = <Map<String, dynamic>>[].obs;
  final selectedMakerId = RxnString();
  final statusList = ['HOT', 'WARM', 'COOL'].obs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  var productStockMap = <String, int>{}.obs;
  final List<String> places = [
    'Thiruvananthapuram',
    'Kollam',
    'Pathanamthitta',
    'Alappuzha',
    'Kottayam',
    'Idukki',
    'Ernakulam',
    'Thrissur',
    'Palakkad',
    'Malappuram',
    'Kozhikode',
    'Wayanad',
    'Kannur',
    'Kasaragod',
  ];

  @override
  void onInit() {
    super.onInit();

    fetchProducts();
    fetchMakers();
    selectedStatus.listen((status) {
      if (status == "HOT") {
        followUpDate.value = null; // Clear date if HOT is selected
      }
    });
  }

  Future<void> fetchMakers() async {
    try {
      // Add loading state
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
          colorText: Color(0xFF014185),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Oops!',
        'Failed to load makers: $e',
        backgroundColor: Colors.red,
        colorText: Color(0xFF014185),
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
        'Error fetching products: $e',
        backgroundColor: Colors.red,
        colorText: Color(0xFF014185),
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
      debugPrint('Error fetching image for $productId: $e');
      productImageUrl.value = null;
      Get.snackbar(
        'Oops!',
        'Error loading image: $e',
        backgroundColor: Colors.red,
        colorText: Color(0xFF014185),
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
        colorText: Color(0xFF014185),
      );
      return;
    }

    if (followUpDate.value == null) {
      Get.snackbar(
        'Oops!',
        'Please select follow-up date',
        backgroundColor: Colors.white,
        colorText: Color(0xFF014185),
      );
      return;
    }

    if (isSaving.value) return; // Prevent double-tap
    isSaving.value = true;

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
          backgroundColor: Colors.white,
          colorText: Color(0xFF014185),
        );
        return;
      }

      final productDoc = querySnapshot.docs.first;
      final docId = productDoc.id; // This is the Firestore document ID
      final productId =
          productDoc['id']; // This is the 'id' field inside the document
      debugPrint("Document ID: $docId");
      debugPrint("Product ID field: $productId");

      final leadId = await _generateLeadsId();
      final customerId = await getOrCreateCustomerId(
        name: nameController.text,
        phone: phoneController.text,
        place: placeController.text,
        address: addressController.text,
      );

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Get.snackbar(
          'Oops!',
          'User not logged in',
          backgroundColor: Colors.white,
          colorText: Color(0xFF014185),
        );
        return;
      }
      final userId = currentUser.uid;

      final newDocRef = _firestore.collection('Leads').doc();
      await newDocRef.set({
        'leadId': leadId,
        'name': nameController.text,
        'place': placeController.text,
        'address': addressController.text,
        'phone1': phoneController.text,
        'phone2': phone2Controller.text.isNotEmpty
            ? phone2Controller.text
            : null,
        'productID': productId,
        'nos': nosController.text,
        'remark': remarkController.text.isNotEmpty
            ? remarkController.text
            : null,
        'status': selectedStatus.value,
        'followUpDate': Timestamp.fromDate(followUpDate.value!),
        'followUpTime': selectedTime.value != null
            ? "${selectedTime.value!.hour.toString().padLeft(2, '0')}:${selectedTime.value!.minute.toString().padLeft(2, '0')}"
            : "",

        'createdAt': Timestamp.now(),
        'salesmanID': userId,
        'isArchived': false,
        'customerId': customerId,
      });

      // 👇 Save a new customer (if needed)
      await _firestore.collection('Customers').add({
        'customerId': customerId,
        'name': nameController.text,
        'place': placeController.text,
        'address': addressController.text,
        'phone1': phoneController.text,
        'phone2': phone2Controller.text.isNotEmpty
            ? phone2Controller.text
            : null,
        'createdAt': Timestamp.now(),
      });

      Get.snackbar(
        'Success',
        'Lead saved successfully',
        backgroundColor: Colors.white,
        colorText: Color(0xFF014185),
      );
      clearForm();
      Get.offAll(Home());
    } catch (e) {
      Get.snackbar(
        'Oops!',
        'Error saving lead: $e',
        backgroundColor: const Color(0xFF014185),
        colorText: Colors.white,
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> placeOrder() async {
    if (!formKey.currentState!.validate() || selectedMakerId.value == null) {
      Get.snackbar(
        'Oops!',
        'Please fill all required fields correctly',
        backgroundColor: Colors.white,
        colorText: Color(0xFF014185),
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
          backgroundColor: Colors.white,
          colorText: Color(0xFF014185),
        );
        return;
      }
      if (isOrdering.value) return; // Prevent double-tap
      isOrdering.value = true;

      final productDoc = querySnapshot.docs.first;
      final docId = productDoc.id;
      final productId = productDoc['id'];
      final currentStock = productDoc['stock'];

      final orderedQuantity = int.tryParse(nosController.text) ?? 0;
      if (orderedQuantity <= 0) {
        Get.snackbar(
          'Oops!',
          'Invalid number of items ordered',
          backgroundColor: Colors.white,
          colorText: Color(0xFF014185),
        );
        return;
      }

      // ✅ Update stock first
      if (currentStock > 0) {
        // Only subtract if stock is positive
        final updatedStock = currentStock - orderedQuantity;
        await _firestore.collection('products').doc(docId).update({
          'stock': updatedStock,
        });
        // Update local product stock map as well
        productStockMap[selectedProductId.value!] = updatedStock;
      }

      final newOrderId = await generateCustomOrderId();
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Get.snackbar(
          'Oops!',
          'User not logged in',
          backgroundColor: Colors.white,
          colorText: Color(0xFF014185),
        );
        return;
      }

      final userId = currentUser.uid;
      final customerId = await getOrCreateCustomerId(
        name: nameController.text,
        phone: phoneController.text,
        place: placeController.text,
        address: addressController.text,
      );

      // ✅ Place the order
      await _firestore.collection('Orders').add({
        'orderId': newOrderId,
        'customerId': customerId,
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
        'cancel': false,
      });

      Get.snackbar(
        'Success',
        'Order placed successfully',
        backgroundColor: Colors.white,
        colorText: Color(0xFF014185),
      );
      clearForm();
      Get.offAll(Home());
    } catch (e) {
      Get.snackbar(
        'Oops!',
        'Cannot placing order: $e',
        backgroundColor: Colors.white,
        colorText: Color(0xFF014185),
      );
    } finally {
      isOrdering.value = false;
    }
  }

  // Example: CUS00001, CUS00002, etc.
  Future<String> generateCustomerId() async {
    final snapshot = await _firestore
        .collection('Customers')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    int lastNumber = 0;
    if (snapshot.docs.isNotEmpty) {
      final lastId = snapshot.docs.first.data()['customerId'] as String?;
      if (lastId != null && lastId.startsWith('CUS')) {
        final numberPart = int.tryParse(lastId.replaceAll('CUS', '')) ?? 0;
        lastNumber = numberPart;
      }
    }

    final newNumber = lastNumber + 1;
    return 'CUS${newNumber.toString().padLeft(5, '0')}';
  }

  Future<String> getOrCreateCustomerId({
    required String name,
    required String phone,
    required String place,
    required String address,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('Customers')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // ✅ Return existing customerId
        final existingCustomerId = snapshot.docs.first.data()['customerId'];
        return existingCustomerId;
      }

      // ❌ No existing customer, create a new one
      final newCustomerId = await generateCustomerId();
      await _firestore.collection('Customers').add({
        'customerId': newCustomerId,
        'name': name,
        'phone': phone,
        'place': place,
        'address': address,
        'createdAt': Timestamp.now(),
      });

      return newCustomerId;
    } catch (e) {
      Get.snackbar(
        'Oops!',
        'Failed to get or create customer: $e',
        backgroundColor: Colors.white,
        colorText: Color(0xFF014185),
      );
      rethrow;
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

  bool isSaveButtonEnabled() {
    if (selectedStatus.value == null)
      return false; // Disable if status is -- Select --
    return selectedStatus.value != 'HOT';
  }

  bool isOrderButtonEnabled() {
    if (selectedStatus.value == null)
      return false; // Disable if status is -- Select --
    // final enteredNos = int.tryParse(nosController.text) ?? 0;
    // final availableStock = productStockMap[selectedProductId.value] ?? 0;

    return selectedStatus.value == 'HOT' && followUpDate.value == null;
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
    selectedMakerId.value = null; // Reset maker selection
    followUpDate.value = null;
    productImageUrl.value = null;
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

    // Add other validations if needed
    if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      return 'Enter a valid 10-digit phone number';
    }

    return null;
  }

  String? validateNos(String? value) {
    if (value == null || value.isEmpty) return 'NOS is required';
    if (!RegExp(r'^\d+$').hasMatch(value)) return 'Enter valid number';
    final numValue = int.tryParse(value);
    if (numValue == null || numValue <= 0) {
      return 'Quantity must be greater than 0';
    }

    return null;
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
    super.onClose();
  }
}
