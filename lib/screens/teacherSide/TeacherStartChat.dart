import 'package:classinsight/Services/Database_Service.dart';
import 'package:classinsight/models/SchoolModel.dart';
import 'package:classinsight/models/StudentModel.dart';
import 'package:classinsight/models/TeacherModel.dart';
import 'package:classinsight/utils/AppColors.dart';
import 'package:classinsight/utils/fontStyles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TeacherStartChatController extends GetxController {
  final Teacher teacher;
  final School school;
  
  RxList<Student> students = <Student>[].obs;
  RxBool isLoading = true.obs;
  Student? selectedStudent;
  
  TeacherStartChatController(this.teacher, this.school);
  
  @override
  void onInit() {
    super.onInit();
    loadStudents();
  }
  
  Future<void> loadStudents() async {
    try {
      final studentList = await Database_Service.getTeacherStudents(
        school.schoolId,
        teacher.empID,
      );
      students.assignAll(studentList);
    } catch (e) {
      print('Error loading students: $e');
      Get.snackbar('Error', 'Failed to load students');
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> startChat(Student student) async {
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
      final chats = await Database_Service.getTeacherChats(school.schoolId, teacher.empID);
      final chat = chats.firstWhere((c) => c.chatId == chatId);
      
      Get.back(); // Close student selection
      Get.toNamed('/TeacherChat', arguments: [chat, teacher, school]);
    } catch (e) {
      print('Error starting chat: $e');
      Get.snackbar('Error', 'Failed to start chat');
    }
  }
}

class TeacherStartChatScreen extends StatelessWidget {
  TeacherStartChatScreen({Key? key}) : super(key: key);
  
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
    final Teacher teacher = args[0] as Teacher;
    final School school = args[1] as School;
    
    final TeacherStartChatController controller = Get.put(TeacherStartChatController(teacher, school));
    
    return Scaffold(
      backgroundColor: AppColors.appLightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.appLightBlue,
        title: Text('Select Student', style: Font_Styles.labelHeadingLight(context)),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (controller.students.isEmpty) {
          return Center(
            child: Text(
              'No students found in your classes',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }
        
        return ListView.builder(
          itemCount: controller.students.length,
          itemBuilder: (context, index) {
            final student = controller.students[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.appDarkBlue,
                child: Text(
                  student.name[0].toUpperCase(),
                  style: TextStyle(color: Colors.white),
                ),
              ),
              title: Text(student.name, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Admission: ${student.studentRollNo}'),
                  Text('Class: ${student.classSection}'),
                  if (student.fatherName.isNotEmpty)
                    Text('Parent: ${student.fatherName}'),
                ],
              ),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => controller.startChat(student),
            );
          },
        );
      }),
    );
  }
}

