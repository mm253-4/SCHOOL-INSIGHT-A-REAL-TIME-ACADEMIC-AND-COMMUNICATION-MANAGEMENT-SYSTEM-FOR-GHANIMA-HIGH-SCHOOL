import 'package:classinsight/Services/Database_Service.dart';
import 'package:classinsight/models/SchoolModel.dart';
import 'package:classinsight/models/TeacherModel.dart';
import 'package:classinsight/utils/AppColors.dart';
import 'package:classinsight/utils/fontStyles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateGroupChatController extends GetxController {
  final Teacher teacher;
  final School school;
  
  RxList<String> classesList = <String>[].obs;
  RxList<String> subjectsList = <String>[].obs;
  RxString selectedClass = ''.obs;
  RxString selectedSubject = ''.obs;
  RxBool isLoading = true.obs;
  RxBool isCreating = false.obs;
  
  CreateGroupChatController(this.teacher, this.school);
  
  @override
  void onInit() {
    super.onInit();
    loadClasses();
  }
  
  Future<void> loadClasses() async {
    try {
      isLoading.value = true;
      // Get teacher's classes - already a List<String>
      if (teacher.classes.isNotEmpty) {
        classesList.assignAll(teacher.classes);
      }
    } catch (e) {
      print('Error loading classes: $e');
      Get.snackbar('Error', 'Failed to load classes');
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> updateSubjects(String? className) async {
    try {
      if (className == null || className.isEmpty) {
        subjectsList.clear();
        selectedSubject.value = '';
        return;
      }
      
      // Get subjects for this class from teacher's subjects map
      final subjectsMap = teacher.subjects;
      if (subjectsMap.containsKey(className)) {
        subjectsList.assignAll(subjectsMap[className]!);
      } else {
        subjectsList.clear();
      }
      selectedSubject.value = '';
    } catch (e) {
      print('Error updating subjects: $e');
    }
  }
  
  Future<void> createGroupChat() async {
    if (selectedClass.value.isEmpty) {
      Get.snackbar('Error', 'Please select a class', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    
    if (selectedSubject.value.isEmpty) {
      Get.snackbar('Error', 'Please select a subject', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    
    try {
      isCreating.value = true;
      
      // Check if teacher teaches this subject to this class
      final teachesSubject = teacher.subjects.containsKey(selectedClass.value) &&
          teacher.subjects[selectedClass.value]!.contains(selectedSubject.value);
      
      if (!teachesSubject) {
        Get.snackbar('Error', 'You do not teach $selectedSubject to $selectedClass', 
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }
      
      // Create group chat
      final chatId = await Database_Service.createGroupChat(
        school.schoolId,
        teacher.empID,
        teacher.name,
        selectedClass.value,
        selectedSubject.value,
      );
      
      Get.snackbar('Success', 'Group chat created successfully!', 
          backgroundColor: Colors.green, colorText: Colors.white);
      
      // Navigate back
      Get.back();
      
      // Navigate to group chat list
      Get.toNamed('/TeacherGroupChatList', arguments: [teacher, school]);
    } catch (e) {
      print('Error creating group chat: $e');
      Get.snackbar('Error', 'Failed to create group chat: ${e.toString()}', 
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isCreating.value = false;
    }
  }
}

class CreateGroupChatScreen extends StatelessWidget {
  CreateGroupChatScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final List<dynamic>? args = Get.arguments as List<dynamic>?;
    if (args == null || args.length < 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar('Error', 'Missing required arguments. Please try again.', 
          backgroundColor: Colors.red, 
          colorText: Colors.white,
          duration: Duration(seconds: 2),
        );
        Get.back();
      });
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.appLightBlue,
          title: Text('Create Group Chat', style: Font_Styles.labelHeadingLight(context)),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    final Teacher teacher = args[0] as Teacher;
    final School school = args[1] as School;
    
    final CreateGroupChatController controller = Get.put(CreateGroupChatController(teacher, school));
    
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: AppColors.appLightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.appLightBlue,
        title: Text('Create Group Chat', style: Font_Styles.labelHeadingLight(context)),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20),
              
              // Info Card
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.appDarkBlue),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Group Chat Information',
                            style: Font_Styles.mediumHeadingBold(context),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Create a group chat for a class and subject. All students in the class and their parents will be automatically added to the group.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 30),
              
              // Class Selection
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Class *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: controller.selectedClass.value.isEmpty ? null : controller.selectedClass.value,
                      decoration: InputDecoration(
                        hintText: 'Choose a class',
                        contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.appDarkBlue, width: 2),
                        ),
                      ),
                      items: controller.classesList.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        controller.selectedClass.value = newValue ?? '';
                        controller.updateSubjects(newValue);
                      },
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 20),
              
              // Subject Selection
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Subject *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 10),
                    Obx(() => DropdownButtonFormField<String>(
                      value: controller.selectedSubject.value.isEmpty ? null : controller.selectedSubject.value,
                      decoration: InputDecoration(
                        hintText: controller.selectedClass.value.isEmpty 
                            ? 'Select a class first' 
                            : 'Choose a subject',
                        contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.appDarkBlue, width: 2),
                        ),
                      ),
                      items: controller.subjectsList.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: controller.selectedClass.value.isEmpty 
                          ? null 
                          : (String? newValue) {
                              controller.selectedSubject.value = newValue ?? '';
                            },
                    )),
                  ],
                ),
              ),
              
              SizedBox(height: 30),
              
              // Create Button
              Obx(() => ElevatedButton(
                onPressed: controller.isCreating.value ? null : controller.createGroupChat,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.appDarkBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: controller.isCreating.value
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 10),
                          Text('Creating...'),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.group_add),
                          SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'Create Group Chat',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
              )),
              
              SizedBox(height: 20),
            ],
          ),
        );
      }),
    );
  }
}

