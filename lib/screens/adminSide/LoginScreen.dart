// ignore_for_file: prefer_const_constructors, must_be_immutable

import 'package:classinsight/models/SchoolModel.dart';
import 'package:classinsight/Services/Auth_Service.dart';
import 'package:classinsight/utils/AppColors.dart';
import 'package:classinsight/utils/fontStyles.dart';
import 'package:classinsight/Widgets/ModernCard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginController extends GetxController {
  Rx<TextEditingController> emailController = TextEditingController().obs;
  Rx<TextEditingController> passwordController= TextEditingController().obs;
  Rx<bool> isDisabled = true.obs;


}

class LoginScreen extends StatelessWidget {
  final LoginController _controller = Get.put(LoginController());


  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? arguments = Get.arguments as Map<String, dynamic>?;
    School? school = arguments?['school'] as School?;
    bool adminOrNot = arguments?['adminOrNot'] ?? true;
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
          gradient: AppColors.primaryGradient,
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
                                gradient: AppColors.primaryGradient,
                                shape: BoxShape.circle,
                                boxShadow: AppColors.buttonShadow,
                              ),
                              child: Icon(
                                adminOrNot ? Icons.admin_panel_settings : Icons.person_outline,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            SizedBox(height: AppColors.spacingLG),
                            Text(
                              school == null && adminOrNot ? "Admin Login" : adminOrNot ? "Admin Login" : "Teacher Login",
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
                      
                      // Email Field
                      Obx(() => TextField(
                        controller: _controller.emailController.value,
                        style: GoogleFonts.inter(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.email_outlined, color: AppColors.primaryColor),
                          hintText: "Enter your email address",
                          labelText: "Email",
                          labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                          filled: true,
                          fillColor: AppColors.backgroundLight,
                        ),
                      )),
                      
                      SizedBox(height: AppColors.spacingMD),
                      
                      // Password Field
                      Obx(() => TextField(
                        controller: _controller.passwordController.value,
                        style: GoogleFonts.inter(color: AppColors.textPrimary),
                        obscureText: _controller.isDisabled.value,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.lock_outline, color: AppColors.primaryColor),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _controller.isDisabled.value 
                                ? Icons.visibility_outlined 
                                : Icons.visibility_off_outlined,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              _controller.isDisabled.value = !_controller.isDisabled.value;
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
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(AppColors.borderRadiusMedium),
                            boxShadow: AppColors.buttonShadow,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                if (school == null && adminOrNot) {
                                  Auth_Service.loginAdminWithoutSchool(
                                    _controller.emailController.value.text,
                                    _controller.passwordController.value.text,
                                  );
                                } else if (school == null && !adminOrNot) {
                                  Auth_Service.loginTeacherWithoutSchool(
                                    _controller.emailController.value.text,
                                    _controller.passwordController.value.text,
                                  );
                                } else if (school != null) {
                                  if(adminOrNot){
                                    Auth_Service.loginAdmin(
                                      _controller.emailController.value.text,
                                      _controller.passwordController.value.text,
                                      school!
                                    );
                                  } else {
                                    Auth_Service.loginTeacher(
                                      _controller.emailController.value.text,
                                      _controller.passwordController.value.text,
                                      school!
                                    );
                                  }
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
                          "Enter your email and password to login",
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