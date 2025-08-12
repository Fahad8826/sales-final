// ignore: file_names
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sales/Auth/forgotpassword.dart';
import 'package:sales/Auth/sign_in_controller.dart';
import 'package:sales/Home/home.dart';

class Signin extends StatelessWidget {
  final controller = Get.put(SigninController());

  Signin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              Positioned(
                top:
                    MediaQuery.of(context).size.height *
                    .16, // Adjusted position slightly
                left:
                    MediaQuery.of(context).size.width *
                    0.25, // Center the logo horizontally
                right:
                    MediaQuery.of(context).size.width *
                    0.25, // Center the logo horizontally
                child: Image.asset(
                  'assets/app_icons/Sales.png',
                  // Use contain to ensure the whole logo is visible
                  height:
                      MediaQuery.of(context).size.height * 0.15, // Made smaller
                  width:
                      MediaQuery.of(context).size.width *
                      0.15, // Added width constraint
                ),
              ),
              // Welcome text
              Positioned(
                top:
                    MediaQuery.of(context).size.height *
                    0.36, // Adjusted position
                left: 30,
                right: 30,
                child: Column(
                  children: [
                    Text(
                      "Welcome Back",
                      style: GoogleFonts.oswald(
                        fontSize: MediaQuery.of(context).size.height * 0.035,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF014185), // Dark blue
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Sign in to continue",
                      style: GoogleFonts.oswald(
                        fontSize: MediaQuery.of(context).size.height * 0.025,
                        color: Colors.blueGrey, // A shade of blue
                      ),
                    ),
                  ],
                ),
              ),
              // Email or Phone Number TextField
              Positioned(
                top:
                    MediaQuery.of(context).size.height *
                    0.5, // Adjusted position
                left: 30,
                right: 30,
                child: TextField(
                  controller: controller.emailOrPhoneController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.person_outlined,
                      color: Color(0xFF014185), // Icon color
                    ),
                    labelText: "Email or Phone Number",
                    labelStyle: GoogleFonts.k2d(
                      color: const Color(0xFF030047).withOpacity(
                        0.6,
                      ), // Slightly lighter dark blue for label
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide
                          .none, // No border by default for filled field
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none, // No border when enabled
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(
                        color: Color(
                          0xFF030047,
                        ), // Dark blue for focused border
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: const Color(
                      0xFFC0D2EB,
                    ), // Lighter, desaturated blue for fill
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 20,
                    ), // Add padding
                  ),
                  style: GoogleFonts.k2d(
                    color: Color(0xFF030047),
                  ), // Text input color
                ),
              ),
              // Password TextField
              Positioned(
                top:
                    MediaQuery.of(context).size.height *
                    0.6, // Adjusted position
                left: 30,
                right: 30,
                child: Obx(
                  () => TextField(
                    controller: controller.passwordController,
                    obscureText: !controller.isPasswordVisible.value,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: Color(0xFF014185),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.isPasswordVisible.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: controller.isPasswordVisible.value
                              ? Color(0xFF030047)
                              : Colors.blueGrey,
                        ),
                        onPressed: controller.togglePasswordVisibility,
                      ),
                      labelText: "Password",
                      labelStyle: GoogleFonts.k2d(
                        color: const Color(0xFF030047).withOpacity(
                          0.6,
                        ), // Slightly lighter dark blue for label
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide
                            .none, // No border by default for filled field
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none, // No border when enabled
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(
                          color: Color(
                            0xFF030047,
                          ), // Dark blue for focused border
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: const Color(
                        0xFFC0D2EB,
                      ), // Lighter, desaturated blue for fill
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 20,
                      ), // Add padding
                    ),
                    style: GoogleFonts.k2d(
                      color: Color(0xFF030047),
                    ), // Text input color
                  ),
                ),
              ),
              // Sign In Button
              Positioned(
                bottom:
                    MediaQuery.of(context).size.height *
                    0.18, // Adjusted position
                left: 30,
                right: 30,
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * .07,
                  child: Obx(() {
                    final isLoading = controller.isLoading.value;

                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLoading
                            ? Colors.grey
                            : const Color(0xFF014185),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: isLoading ? 0 : 5,
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              final input = controller
                                  .emailOrPhoneController
                                  .text
                                  .trim();
                              final password = controller
                                  .passwordController
                                  .text
                                  .trim();

                              controller.isLoading.value = true;

                              try {
                                final result = await controller.signIn(
                                  context,
                                  input,
                                  password,
                                );

                                controller.isLoading.value = false;

                                if (result == null) {
                                  controller.emailOrPhoneController.clear();
                                  controller.passwordController.clear();
                                  Get.offAll(() => Home());
                                  Get.snackbar(
                                    "Welcome!",
                                    "Signed in successfully.",
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.white,
                                    colorText: Color(0xFF014185),
                                  );
                                } else {
                                  Get.snackbar(
                                    "Login Failed",
                                    "Please check your credentials.",
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.redAccent,
                                    colorText: Colors.white,
                                  );
                                }
                              } catch (e) {
                                controller.isLoading.value = false;
                                Get.snackbar(
                                  "Oops!",
                                  "An unexpected error occurred.",
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white,
                                );
                              }
                            },
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              "SIGN IN",
                              style: GoogleFonts.k2d(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    );
                  }),
                ),
              ),
              Positioned(
                bottom:
                    MediaQuery.of(context).size.height *
                    0.28, // Adjusted position
                right: 30,
                child: TextButton(
                  onPressed: () {
                    Get.offAll(() => ForgotPasswordPage());
                  },
                  child: Text(
                    "Forgot Password",
                    style: GoogleFonts.k2d(color: Color(0xFF014185)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
