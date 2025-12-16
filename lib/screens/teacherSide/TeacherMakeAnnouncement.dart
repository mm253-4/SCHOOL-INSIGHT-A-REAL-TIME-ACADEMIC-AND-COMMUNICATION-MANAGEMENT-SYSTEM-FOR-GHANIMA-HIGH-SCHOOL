import 'package:classinsight/Services/Database_Service.dart';
import 'package:classinsight/models/SchoolModel.dart';
import 'package:classinsight/models/TeacherModel.dart';
import 'package:classinsight/utils/AppColors.dart';
import 'package:classinsight/utils/fontStyles.dart';
import 'package:classinsight/utils/name_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TeacherMakeAnnouncementController extends GetxController {
  final Teacher teacher;
  final School school;
  
  final TextEditingController announcementController = TextEditingController();
  final TextEditingController timelineController = TextEditingController();
  RxList<String> classesList = <String>[].obs;
  RxList<String> selectedClasses = <String>[].obs;
  RxBool isLoading = false.obs;
  RxBool isSending = false.obs;
  Rx<DateTime?> deadline = Rx<DateTime?>(null);
  
  TeacherMakeAnnouncementController(this.teacher, this.school);
  
  @override
  void onInit() {
    super.onInit();
    loadClasses();
  }
  
  @override
  void onClose() {
    announcementController.dispose();
    timelineController.dispose();
    super.onClose();
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
  
  Future<void> sendAnnouncement() async {
    if (announcementController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please write an announcement before sending it.',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    
    if (selectedClasses.isEmpty) {
      Get.snackbar('Error', 'Please select at least one class.',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    if (deadline.value == null) {
      Get.snackbar('Error', 'Please select a deadline for the announcement.',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    if (timelineController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please provide a timeline for the announcement.',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    
    try {
      isSending.value = true;
      
      int totalStudents = 0;
      List<String> classNames = [];
      
      // Get all students from all selected classes
      for (final className in selectedClasses) {
        final students = await Database_Service.getStudentsOfASpecificClass(
          school.schoolId,
          className,
        );
        
        if (students.isNotEmpty) {
          classNames.add(className);
          totalStudents += students.length;
          
          // Create announcement for each student in the class
          for (final student in students) {
            await Database_Service.createAnnouncement(
              school.schoolId,
              student.studentID,
              announcementController.text.trim(),
              formatTeacherTitle(teacher.name, teacher.gender),
              false, // Not an admin announcement
              deadline: deadline.value,
              timeline: timelineController.text.trim(),
            );
          }
        }
      }
      
      if (totalStudents == 0) {
        Get.snackbar('Error', 'No students found in selected classes',
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }
      
      final classListText = classNames.length == 1 
          ? classNames.first 
          : '${classNames.length} classes';
      
      Get.snackbar(
        'Success',
        'Announcement sent to $totalStudents students in $classListText',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
      
      announcementController.clear();
      selectedClasses.clear();
      deadline.value = null;
      timelineController.clear();
      
      // Navigate back after a short delay
      await Future.delayed(Duration(seconds: 1));
      Get.back();
    } catch (e) {
      print('Error sending announcement: $e');
      Get.snackbar('Error', 'Failed to send announcement: ${e.toString()}',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isSending.value = false;
    }
  }

  Future<void> selectDeadline(BuildContext context) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: deadline.value ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(deadline.value ?? now),
      );

      if (pickedTime != null) {
        deadline.value = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      }
    }
  }
  
  void toggleClassSelection(String className) {
    if (selectedClasses.contains(className)) {
      selectedClasses.remove(className);
    } else {
      selectedClasses.add(className);
    }
  }
}

class TeacherMakeAnnouncementScreen extends StatelessWidget {
  TeacherMakeAnnouncementScreen({Key? key}) : super(key: key);
  
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
          title: Text('Make Announcement', style: Font_Styles.labelHeadingLight(context)),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    final Teacher teacher = args[0] as Teacher;
    final School school = args[1] as School;
    
    final TeacherMakeAnnouncementController controller = Get.put(TeacherMakeAnnouncementController(teacher, school));
    
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: AppColors.appLightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.appLightBlue,
        title: Text('Make Announcement', style: Font_Styles.labelHeadingLight(context)),
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
                            'Announcement Information',
                            style: Font_Styles.mediumHeadingBold(context),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Select one or more classes. All students and parents in selected classes will see this announcement.',
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
                    Row(
                      children: [
                        Text(
                          'Select Classes *',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Spacer(),
                        Obx(() => Text(
                          '${controller.selectedClasses.length} selected',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.appDarkBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        )),
                      ],
                    ),
                    SizedBox(height: 10),
                    Obx(() {
                      if (controller.classesList.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.all(10),
                          child: Text(
                            'No classes available',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }
                      
                      return Container(
                        constraints: BoxConstraints(
                          maxHeight: screenHeight * 0.3,
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: controller.classesList.length,
                          itemBuilder: (context, index) {
                            final className = controller.classesList[index];
                            final isSelected = controller.selectedClasses.contains(className);
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (index == 0 && controller.selectedClasses.isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 12),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: controller.selectedClasses
                                          .map((selectedClass) => Chip(
                                                backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                                                label: Text(
                                                  selectedClass,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.primaryColor,
                                                  ),
                                                ),
                                                deleteIcon: Icon(Icons.close, size: 18, color: AppColors.primaryColor),
                                                onDeleted: () => controller.toggleClassSelection(selectedClass),
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                CheckboxListTile(
                                  title: Text(
                                    className,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  value: isSelected,
                                  onChanged: (bool? value) {
                                    controller.toggleClassSelection(className);
                                  },
                                  activeColor: AppColors.appDarkBlue,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                              ],
                            );
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
              
              SizedBox(height: 20),

              // Deadline selection
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
                      'Deadline *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 10),
                    Obx(
                      () => InkWell(
                        onTap: () => controller.selectDeadline(context),
                        child: Container(
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: AppColors.appDarkBlue,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  controller.deadline.value != null
                                      ? '${controller.deadline.value!.day}/${controller.deadline.value!.month}/${controller.deadline.value!.year} ${controller.deadline.value!.hour.toString().padLeft(2, '0')}:${controller.deadline.value!.minute.toString().padLeft(2, '0')}'
                                      : 'Select deadline date and time',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: controller.deadline.value != null
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: controller.deadline.value != null
                                        ? AppColors.textPrimary
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Timeline input
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
                      'Timeline *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: controller.timelineController,
                      decoration: InputDecoration(
                        hintText: 'e.g., Conference Hall • 4:00 PM - 6:00 PM',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: EdgeInsets.all(15),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),
              
              // Announcement Text Field
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
                      'Announcement *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: controller.announcementController,
                      maxLines: 8,
                      minLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Type your announcement here...',
                        contentPadding: EdgeInsets.all(15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: AppColors.appDarkBlue, width: 2),
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 30),
              
              // Send Button
              Obx(() => ElevatedButton(
                onPressed: controller.isSending.value ? null : controller.sendAnnouncement,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.appDarkBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: controller.isSending.value
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
                          Text('Sending...'),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send),
                          SizedBox(width: 10),
                          Text(
                            'Send Announcement',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

