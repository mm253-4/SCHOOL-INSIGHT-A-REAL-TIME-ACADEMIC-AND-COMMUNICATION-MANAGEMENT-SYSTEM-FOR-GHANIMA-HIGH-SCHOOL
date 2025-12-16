import 'package:classinsight/Services/Auth_Service.dart';
import 'package:classinsight/models/SchoolModel.dart';
import 'package:classinsight/models/StudentModel.dart';
import 'package:classinsight/utils/AppColors.dart';
import 'package:classinsight/utils/fontStyles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StudentChangePasswordController extends GetxController {
  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  
  var obscureCurrentPassword = true.obs;
  var obscureNewPassword = true.obs;
  var obscureConfirmPassword = true.obs;
  
  var currentPasswordValid = true.obs;
  var newPasswordValid = true.obs;
  var confirmPasswordValid = true.obs;
  
  final Student student;
  final School school;
  
  StudentChangePasswordController(this.student, this.school);
  
  @override
  void onClose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
  
  bool validateForm() {
    currentPasswordValid.value = currentPasswordController.text.isNotEmpty;
    newPasswordValid.value = newPasswordController.text.isNotEmpty && newPasswordController.text.length >= 6;
    confirmPasswordValid.value = confirmPasswordController.text.isNotEmpty && 
        confirmPasswordController.text == newPasswordController.text;
    
    return currentPasswordValid.value && newPasswordValid.value && confirmPasswordValid.value;
  }
  
  Future<void> changePassword() async {
    if (!validateForm()) {
      Get.snackbar('Error', 'Please fill all fields correctly',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    
    // Show loading indicator
    Get.dialog(
      Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    
    final success = await Auth_Service.changeStudentPassword(
      school.schoolId,
      student.studentID,
      currentPasswordController.text,
      newPasswordController.text,
    );
    
    // Close loading indicator
    Get.back();
    
    if (success) {
      // Show success notification
      Get.snackbar(
        'Success',
        'Password Changed Successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
        icon: Icon(Icons.check_circle, color: Colors.white),
        snackPosition: SnackPosition.TOP,
      );
      
      // Clear fields
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
      
      // Go back after a short delay to show the notification
      await Future.delayed(Duration(seconds: 1));
      Get.back();
    }
  }
}

class StudentChangePasswordScreen extends StatelessWidget {
  StudentChangePasswordScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final List<dynamic>? args = Get.arguments as List<dynamic>?;
    if (args == null || args.length < 2) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.appLightBlue,
          title: Text('Change Password', style: Font_Styles.labelHeadingLight(context)),
        ),
        body: Center(
          child: Text('Error: Missing required arguments', style: Font_Styles.labelHeadingRegular(context)),
        ),
      );
    }
    final Student student = args[0] as Student;
    final School school = args[1] as School;
    
    final StudentChangePasswordController controller = Get.put(StudentChangePasswordController(student, school));
    
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: AppColors.appLightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.appLightBlue,
        title: Text('Change Password', style: Font_Styles.labelHeadingLight(context)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: screenHeight * 0.05),
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Change Password',
                      style: Font_Styles.mediumHeadingBold(context),
                    ),
                    SizedBox(height: 20),
                    
                    // Current Password
                    Obx(() => TextFormField(
                      controller: controller.currentPasswordController,
                      obscureText: controller.obscureCurrentPassword.value,
                      decoration: InputDecoration(
                        labelText: 'Current Password *',
                        hintText: 'Enter current password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.obscureCurrentPassword.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            controller.obscureCurrentPassword.value = 
                                !controller.obscureCurrentPassword.value;
                          },
                        ),
                        errorText: controller.currentPasswordValid.value 
                            ? null 
                            : 'Current password is required',
                      ),
                    )),
                    SizedBox(height: 15),
                    
                    // New Password
                    Obx(() => TextFormField(
                      controller: controller.newPasswordController,
                      obscureText: controller.obscureNewPassword.value,
                      decoration: InputDecoration(
                        labelText: 'New Password *',
                        hintText: 'Enter new password (min 6 characters)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.obscureNewPassword.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            controller.obscureNewPassword.value = 
                                !controller.obscureNewPassword.value;
                          },
                        ),
                        errorText: controller.newPasswordValid.value 
                            ? null 
                            : 'Password must be at least 6 characters',
                      ),
                    )),
                    SizedBox(height: 15),
                    
                    // Confirm Password
                    Obx(() => TextFormField(
                      controller: controller.confirmPasswordController,
                      obscureText: controller.obscureConfirmPassword.value,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password *',
                        hintText: 'Confirm new password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.obscureConfirmPassword.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            controller.obscureConfirmPassword.value = 
                                !controller.obscureConfirmPassword.value;
                          },
                        ),
                        errorText: controller.confirmPasswordValid.value 
                            ? null 
                            : 'Passwords do not match',
                      ),
                    )),
                    SizedBox(height: 25),
                    
                    // Change Password Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.appDarkBlue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Change Password',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

