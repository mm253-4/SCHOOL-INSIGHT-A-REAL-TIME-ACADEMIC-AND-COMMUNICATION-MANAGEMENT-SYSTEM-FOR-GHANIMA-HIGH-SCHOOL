import 'package:classinsight/Services/Auth_Service.dart';
import 'package:classinsight/utils/AppColors.dart';
import 'package:classinsight/utils/fontStyles.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminSignupController extends GetxController {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController schoolNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  
  RxBool isPasswordVisible = true.obs;
  RxBool isConfirmPasswordVisible = true.obs;
  RxBool isLoading = false.obs;

  @override
  void onClose() {
    nameController.dispose();
    idController.dispose();
    emailController.dispose();
    schoolNameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  bool validateInputs() {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter your name', backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    if (idController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter your ID', backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    if (emailController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter your email', backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    if (!GetUtils.isEmail(emailController.text.trim())) {
      Get.snackbar('Error', 'Please enter a valid email', backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    if (schoolNameController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter School Name', backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    if (passwordController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter a password', backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    if (passwordController.text.trim().length < 6) {
      Get.snackbar('Error', 'Password must be at least 6 characters', backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    if (confirmPasswordController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please confirm your password', backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    if (passwordController.text.trim() != confirmPasswordController.text.trim()) {
      Get.snackbar('Error', 'Passwords do not match', backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    return true;
  }

  Future<void> signUp() async {
    if (!validateInputs()) return;
    
    isLoading.value = true;
    try {
      await Auth_Service.signUpAdminWithDetails(
        nameController.text.trim(),
        idController.text.trim(),
        emailController.text.trim(),
        schoolNameController.text.trim(),
        passwordController.text.trim(),
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to sign up: ${e.toString()}', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
}

class AdminSignupScreen extends StatelessWidget {
  AdminSignupScreen({Key? key}) : super(key: key);
  
  final AdminSignupController controller = Get.put(AdminSignupController());

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.appLightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.appLightBlue,
        title: Text('Admin Sign Up', style: Font_Styles.labelHeadingLight(context)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.02),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: screenHeight * 0.02),
              
              // Name Field
              TextField(
                controller: controller.nameController,
                decoration: InputDecoration(
                  labelText: 'Name *',
                  hintText: 'Enter your full name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.appDarkBlue),
                  ),
                ),
              ),
              
              SizedBox(height: screenHeight * 0.02),
              
              // ID Field
              TextField(
                controller: controller.idController,
                decoration: InputDecoration(
                  labelText: 'ID Number *',
                  hintText: 'Enter your ID number',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.appDarkBlue),
                  ),
                ),
              ),
              
              SizedBox(height: screenHeight * 0.02),
              
              // Email Field
              TextField(
                controller: controller.emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email *',
                  hintText: 'Enter your email address',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.appDarkBlue),
                  ),
                ),
              ),
              
              SizedBox(height: screenHeight * 0.02),
              
              // School Name Field
              TextField(
                controller: controller.schoolNameController,
                decoration: InputDecoration(
                  labelText: 'School Name *',
                  hintText: 'Enter your school name',
                  prefixIcon: Icon(Icons.school),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.appDarkBlue),
                  ),
                ),
              ),
              
              SizedBox(height: screenHeight * 0.02),
              
              // Password Field
              Obx(() => TextField(
                controller: controller.passwordController,
                obscureText: controller.isPasswordVisible.value,
                decoration: InputDecoration(
                  labelText: 'Password *',
                  hintText: 'Enter password (min 6 characters)',
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.isPasswordVisible.value
                          ? CupertinoIcons.eye_slash_fill
                          : CupertinoIcons.eye_fill,
                    ),
                    onPressed: () {
                      controller.isPasswordVisible.value = !controller.isPasswordVisible.value;
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.appDarkBlue),
                  ),
                ),
              )),
              
              SizedBox(height: screenHeight * 0.02),
              
              // Confirm Password Field
              Obx(() => TextField(
                controller: controller.confirmPasswordController,
                obscureText: controller.isConfirmPasswordVisible.value,
                decoration: InputDecoration(
                  labelText: 'Confirm Password *',
                  hintText: 'Re-enter your password',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.isConfirmPasswordVisible.value
                          ? CupertinoIcons.eye_slash_fill
                          : CupertinoIcons.eye_fill,
                    ),
                    onPressed: () {
                      controller.isConfirmPasswordVisible.value = !controller.isConfirmPasswordVisible.value;
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.appDarkBlue),
                  ),
                ),
              )),
              
              SizedBox(height: screenHeight * 0.03),
              
              // Sign Up Button
              Obx(() => SizedBox(
                width: double.infinity,
                height: screenHeight * 0.06,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value ? null : controller.signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.appDarkBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Sign Up',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              )),
              
              SizedBox(height: screenHeight * 0.02),
            ],
          ),
        ),
      ),
    );
  }
}

