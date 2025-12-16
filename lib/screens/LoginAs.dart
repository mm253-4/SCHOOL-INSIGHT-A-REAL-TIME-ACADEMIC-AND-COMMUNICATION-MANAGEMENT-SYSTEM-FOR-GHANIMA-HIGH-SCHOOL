// ignore_for_file: unused_local_variable

import 'package:classinsight/Widgets/PageTransitions.dart';
import 'package:classinsight/models/SchoolModel.dart';
import 'package:classinsight/screens/adminSide/LoginScreen.dart';
import 'package:classinsight/screens/parentSide/ParentLogin.dart';
import 'package:classinsight/screens/studentSide/StudentLogin.dart';
import 'package:classinsight/Services/Auth_Service.dart';
import 'package:classinsight/Services/Database_Service.dart';
import 'package:classinsight/utils/fontStyles.dart';
import 'package:classinsight/utils/AppColors.dart';
import 'package:classinsight/Widgets/BaseScreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// ignore: must_be_immutable
class LoginAs extends StatelessWidget {
  LoginAs({Key? key}) : super(key: key);

  School? get school {
    try {
      final args = Get.arguments;
      if (args == null) return null;
      if (args is School) return args;
      return null;
    } catch (e) {
      return null;
    }
  }
  bool adminOrNot = true;

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Modern Header Section with Gradient
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  children: [
                    // School Logo/Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(6),
                        child: Image.asset(
                          'lib/assets/ghanima_splash.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    // School Name
                    Text(
                      'Ghanima Girls',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'High School',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Welcome to your digital campus',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 40),
              
              // Role Selection Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Your Role',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Choose how you want to access the platform',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // Role Cards Grid
                    _buildRoleCard(
                      context: context,
                      title: 'Parent',
                      icon: Icons.family_restroom_rounded,
                      gradient: AppColors.secondaryGradient,
                      onTap: () {
                        Go.to(() => ParentLoginScreen());
                      },
                    ),
                    SizedBox(height: 16),
                    _buildRoleCard(
                      context: context,
                      title: 'Student',
                      icon: Icons.school_rounded,
                      gradient: AppColors.primaryGradient,
                      onTap: () {
                        Go.to(() => StudentLoginScreen(), arguments: school);
                      },
                    ),
                    SizedBox(height: 16),
                    _buildRoleCard(
                      context: context,
                      title: 'Teacher',
                      icon: Icons.person_outline_rounded,
                      gradient: AppColors.orangeGradient,
                      onTap: () {
                        adminOrNot = false;
                        var args = {
                          'school': school,
                          'adminOrNot': adminOrNot,
                        };
                        Go.to(() => LoginScreen(), arguments: args);
                      },
                    ),
                    SizedBox(height: 16),
                    _buildRoleCard(
                      context: context,
                      title: 'Admin',
                      icon: Icons.admin_panel_settings_rounded,
                      gradient: AppColors.successGradient,
                      onTap: () {
                        adminOrNot = true;
                        var args = {
                          'school': school,
                          'adminOrNot': adminOrNot,
                        };
                        Go.to(() => LoginScreen(), arguments: args);
                      },
                    ),
                    
                    SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.borderRadiusLarge),
        child: Container(
          padding: EdgeInsets.all(AppColors.spacingLG),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppColors.borderRadiusLarge),
            boxShadow: AppColors.cardShadowHover,
          ),
          child: Row(
            children: [
              // Icon Container
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppColors.borderRadiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              SizedBox(width: AppColors.spacingMD),
              // Title
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              // Arrow Icon
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
