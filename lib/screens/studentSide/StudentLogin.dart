// ignore_for_file: prefer_const_constructors, must_be_immutable

import 'package:classinsight/models/SchoolModel.dart';
import 'package:classinsight/Services/Auth_Service.dart';
import 'package:classinsight/utils/AppColors.dart';
import 'package:classinsight/Widgets/ModernCard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class StudentLoginController extends GetxController {
  final TextEditingController admissionNumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  var obscurePassword = true.obs;
  School? school;

  @override
  void onInit() {
    final args = Get.arguments;
    if (args != null && args is School) {
      school = args;
    }
    super.onInit();
  }

  @override
  void onClose() {
    admissionNumberController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}

class StudentLoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final StudentLoginController _controller;
    if (Get.isRegistered<StudentLoginController>()) {
      _controller = Get.find<StudentLoginController>();
    } else {
      _controller = Get.put(StudentLoginController());
    }
    
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.blueGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(AppColors.spacingLG),
                child: ModernCard(
                  padding: EdgeInsets.all(AppColors.spacingXL),
                  margin: EdgeInsets.zero,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: AppColors.blueGradient,
                                shape: BoxShape.circle,
                                boxShadow: AppColors.buttonShadow,
                              ),
                              child: Icon(
                                Icons.school_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            SizedBox(height: AppColors.spacingLG),
                            Text(
                              "Student Login",
                              style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: AppColors.spacingXS),
                            Text(
                              "Welcome back! Please login to continue",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: AppColors.spacingXL),
                      
                      // Admission Number Field
                      TextFormField(
                        controller: _controller.admissionNumberController,
                        style: GoogleFonts.inter(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.badge_outlined, color: AppColors.primaryColor),
                          hintText: "Admission Number",
                          labelText: "Admission Number",
                          labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                          filled: true,
                          fillColor: AppColors.backgroundLight,
                        ),
                      ),
                      
                      SizedBox(height: AppColors.spacingMD),
                      
                      // Password Field
                      Obx(() => TextFormField(
                        controller: _controller.passwordController,
                        obscureText: _controller.obscurePassword.value,
                        style: GoogleFonts.inter(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.lock_outline, color: AppColors.primaryColor),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _controller.obscurePassword.value
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              _controller.obscurePassword.value = !_controller.obscurePassword.value;
                            },
                          ),
                          hintText: "Enter your password",
                          labelText: "Password",
                          labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                          filled: true,
                          fillColor: AppColors.backgroundLight,
                        ),
                      )),
                      
                      SizedBox(height: AppColors.spacingXL),
                      
                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.blueGradient,
                            borderRadius: BorderRadius.circular(AppColors.borderRadiusMedium),
                            boxShadow: AppColors.buttonShadow,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                if (_controller.admissionNumberController.text.isNotEmpty &&
                                    _controller.passwordController.text.isNotEmpty) {
                                  Auth_Service.loginStudent(
                                    _controller.school,
                                    _controller.admissionNumberController.text,
                                    _controller.passwordController.text,
                                  );
                                } else {
                                  Get.snackbar('Error', 'Please enter both admission number and password',
                                      backgroundColor: Colors.red, colorText: Colors.white);
                                }
                              },
                              borderRadius: BorderRadius.circular(AppColors.borderRadiusMedium),
                              child: Center(
                                child: Text(
                                  "Login",
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: AppColors.spacingMD),
                      
                      // Helper Text
                      Center(
                        child: Text(
                          "Enter your admission number and password to login",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

