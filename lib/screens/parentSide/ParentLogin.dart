// ignore_for_file: prefer_const_constructors, must_be_immutable

import 'package:classinsight/Services/Auth_Service.dart';
import 'package:classinsight/utils/AppColors.dart';
import 'package:classinsight/Widgets/ModernCard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ParentLoginController extends GetxController {
  Rx<TextEditingController> challanIDbFormController = TextEditingController().obs;
  Rx<bool> isDisabled = true.obs;
}

class ParentLoginScreen extends StatelessWidget {
  final ParentLoginController _controller = Get.put(ParentLoginController());


  @override
  Widget build(BuildContext context) {
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
          gradient: AppColors.secondaryGradient,
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
                                gradient: AppColors.secondaryGradient,
                                shape: BoxShape.circle,
                                boxShadow: AppColors.buttonShadow,
                              ),
                              child: Icon(
                                Icons.family_restroom_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            SizedBox(height: AppColors.spacingLG),
                            Text(
                              "Parent Login",
                              style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: AppColors.spacingXS),
                            Text(
                              "Enter your child's admission number to continue",
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
                      Obx(() => TextFormField(
                        controller: _controller.challanIDbFormController.value,
                        style: GoogleFonts.inter(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.badge_outlined, color: AppColors.secondaryColor),
                          suffixIcon: IconButton(
                            onPressed: () {
                              if (_controller.challanIDbFormController.value.text.isNotEmpty) {
                                Auth_Service.loginParent(_controller.challanIDbFormController.value.text);
                              } else {
                                Get.snackbar('Error', 'Please enter admission number',
                                    backgroundColor: Colors.red, colorText: Colors.white);
                              }
                            },
                            icon: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: AppColors.secondaryGradient,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          hintText: "Admission Number",
                          labelText: "Admission Number",
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
                            gradient: AppColors.secondaryGradient,
                            borderRadius: BorderRadius.circular(AppColors.borderRadiusMedium),
                            boxShadow: AppColors.buttonShadow,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                if (_controller.challanIDbFormController.value.text.isNotEmpty) {
                                  Auth_Service.loginParent(_controller.challanIDbFormController.value.text);
                                } else {
                                  Get.snackbar('Error', 'Please enter admission number',
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
