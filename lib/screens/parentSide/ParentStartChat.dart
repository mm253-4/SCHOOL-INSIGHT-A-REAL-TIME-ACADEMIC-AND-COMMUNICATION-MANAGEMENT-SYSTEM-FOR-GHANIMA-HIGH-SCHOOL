import 'dart:convert';
import 'package:classinsight/Services/Database_Service.dart';
import 'package:classinsight/models/SchoolModel.dart';
import 'package:classinsight/models/StudentModel.dart';
import 'package:classinsight/models/TeacherModel.dart';
import 'package:classinsight/utils/AppColors.dart';
import 'package:classinsight/utils/fontStyles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ParentStartChatController extends GetxController {
  final Student student;
  final School school;
  
  RxList<Teacher> teachers = <Teacher>[].obs;
  RxBool isLoading = true.obs;
  
  ParentStartChatController(this.student, this.school);
  
  @override
  void onInit() {
    super.onInit();
    loadTeachers();
  }
  
  Future<void> loadTeachers() async {
    try {
      // Get all teachers in the school
      final teacherList = await Database_Service.fetchTeachers(school.schoolId);
      // Filter teachers who teach the student's class
      // A teacher teaches the student if:
      // 1. They are assigned to the student's class, OR
      // 2. They teach any subject to the student's class, OR
      // 3. They are the class teacher for the student's class
      final relevantTeachers = teacherList.where((teacher) {
        // Check if teacher is assigned to this class
        final teachesClass = teacher.classes.contains(student.classSection);
        
        // Check if teacher teaches any subject to this class
        final teachesSubjects = teacher.subjects.containsKey(student.classSection) &&
            teacher.subjects[student.classSection]!.isNotEmpty;
        
        // Check if teacher is the class teacher for this class
        // classTeacher can be a JSON list or a single string
        bool isClassTeacher = false;
        try {
          if (teacher.classTeacher.isNotEmpty) {
            // Try parsing as JSON list first
            try {
              final classTeacherList = List<String>.from(jsonDecode(teacher.classTeacher));
              isClassTeacher = classTeacherList.contains(student.classSection);
            } catch (e) {
              // If not JSON, check as single string
              isClassTeacher = teacher.classTeacher == student.classSection;
            }
          }
        } catch (e) {
          // Fallback to simple string comparison
          isClassTeacher = teacher.classTeacher == student.classSection;
        }
        
        return teachesClass || teachesSubjects || isClassTeacher;
      }).toList();
      teachers.assignAll(relevantTeachers);
    } catch (e) {
      print('Error loading teachers: $e');
      Get.snackbar('Error', 'Failed to load teachers');
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> startChat(Teacher teacher) async {
    try {
      // Get parent info from student
      final parentId = student.studentRollNo; // Use admission number as parent identifier
      final parentName = student.fatherName.isNotEmpty 
          ? student.fatherName 
          : 'Parent of ${student.name}';
      
      // Create or get chat
      final chatId = await Database_Service.getOrCreateChat(
        school.schoolId,
        teacher.empID,
        teacher.name,
        parentId,
        parentName,
        student.studentID,
        student.name,
      );
      
      // Get the chat object
      final chats = await Database_Service.getParentChats(school.schoolId, student.studentID);
      final chat = chats.firstWhere((c) => c.chatId == chatId);
      
      Get.back(); // Close teacher selection
      Get.toNamed('/ParentChat', arguments: [chat, this.student, this.school]);
    } catch (e) {
      print('Error starting chat: $e');
      Get.snackbar('Error', 'Failed to start chat');
    }
  }
}

bool _isClassTeacher(Teacher teacher, String classSection) {
  try {
    if (teacher.classTeacher.isEmpty) return false;
    // Try parsing as JSON list first
    try {
      final classTeacherList = List<String>.from(jsonDecode(teacher.classTeacher));
      return classTeacherList.contains(classSection);
    } catch (e) {
      // If not JSON, check as single string
      return teacher.classTeacher == classSection;
    }
  } catch (e) {
    return teacher.classTeacher == classSection;
  }
}

class ParentStartChatScreen extends StatelessWidget {
  ParentStartChatScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final List<dynamic>? args = Get.arguments as List<dynamic>?;
    if (args == null || args.length < 2) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.appLightBlue,
          title: Text('Start Chat', style: Font_Styles.labelHeadingLight(context)),
        ),
        body: Center(
          child: Text('Error: Missing required arguments', style: Font_Styles.labelHeadingRegular(context)),
        ),
      );
    }
    final Student student = args[0] as Student;
    final School school = args[1] as School;
    
    final ParentStartChatController controller = Get.put(ParentStartChatController(student, school));
    
    return Scaffold(
      backgroundColor: AppColors.appLightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.appLightBlue,
        title: Text('Select Teacher', style: Font_Styles.labelHeadingLight(context)),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (controller.teachers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off, size: 80, color: Colors.grey),
                SizedBox(height: 20),
                Text(
                  'No teachers found for ${controller.student.classSection}',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: EdgeInsets.all(8),
          itemCount: controller.teachers.length,
          itemBuilder: (context, index) {
            final teacher = controller.teachers[index];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.appOrange,
                  child: Text(
                    teacher.name[0].toUpperCase(),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(teacher.name, style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (teacher.email.isNotEmpty)
                      Text('Email: ${teacher.email}'),
                    if (_isClassTeacher(teacher, controller.student.classSection))
                      Text('Class Teacher', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.appOrange)),
                    if (teacher.subjects.containsKey(controller.student.classSection) && 
                        teacher.subjects[controller.student.classSection]!.isNotEmpty)
                      Text('Subjects: ${teacher.subjects[controller.student.classSection]!.join(", ")}'),
                    if (teacher.classes.contains(controller.student.classSection))
                      Text('Assigned to ${controller.student.classSection}'),
                  ],
                ),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => controller.startChat(teacher),
              ),
            );
          },
        );
      }),
    );
  }
}

