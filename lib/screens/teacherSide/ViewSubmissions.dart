import 'dart:io';
import 'package:classinsight/Services/Database_Service.dart';
import 'package:classinsight/models/AssignmentModel.dart';
import 'package:classinsight/models/AssignmentSubmissionModel.dart';
import 'package:classinsight/models/StudentModel.dart';
import 'package:classinsight/models/TeacherModel.dart';
import 'package:classinsight/models/SchoolModel.dart';
import 'package:classinsight/utils/AppColors.dart';
import 'package:classinsight/utils/fontStyles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;

class ViewSubmissionsController extends GetxController {
  final Assignment assignment;
  final Teacher teacher;
  final School school;
  
  RxList<Student> allStudents = <Student>[].obs;
  RxMap<String, AssignmentSubmission?> submissions = <String, AssignmentSubmission?>{}.obs;
  RxBool isLoading = true.obs;
  RxString selectedFilter = 'all'.obs; // 'all', 'submitted', 'pending'
  
  ViewSubmissionsController(this.assignment, this.teacher, this.school);
  
  @override
  void onInit() {
    super.onInit();
    loadData();
  }
  
  Future<void> loadData() async {
    try {
      isLoading.value = true;
      
      // Get all students in the assigned classes
      List<String> classes = [];
      if (assignment.assignedClasses != null && assignment.assignedClasses!.isNotEmpty) {
        classes = assignment.assignedClasses!;
      } else if (assignment.className != null) {
        classes = [assignment.className!];
      }
      
      List<Student> students = [];
      for (var className in classes) {
        final classStudents = await Database_Service.getStudentsOfASpecificClass(
          school.schoolId,
          className,
        );
        students.addAll(classStudents);
      }
      allStudents.assignAll(students);
      
      // Load submissions for all students
      if (assignment.id != null) {
        final submissionsList = await Database_Service.getAssignmentSubmissions(assignment.id!);
        for (var submission in submissionsList) {
          if (submission.studentId != null) {
            submissions[submission.studentId!] = submission;
          }
        }
      }
    } catch (e) {
      print('Error loading submissions: $e');
      Get.snackbar('Error', 'Failed to load submissions');
    } finally {
      isLoading.value = false;
    }
  }
  
  List<Student> getFilteredStudents() {
    switch (selectedFilter.value) {
      case 'submitted':
        return allStudents.where((student) => 
          submissions[student.studentID] != null
        ).toList();
      case 'pending':
        return allStudents.where((student) => 
          submissions[student.studentID] == null
        ).toList();
      default:
        return allStudents.toList();
    }
  }
  
  int getSubmittedCount() {
    return submissions.values.where((s) => s != null).length;
  }
  
  int getPendingCount() {
    return allStudents.length - getSubmittedCount();
  }
  
  String formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class ViewSubmissionsScreen extends StatelessWidget {
  ViewSubmissionsScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final List<dynamic>? args = Get.arguments as List<dynamic>?;
    if (args == null || args.length < 3) {
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
          title: Text('View Submissions', style: Font_Styles.labelHeadingLight(context)),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    final Assignment assignment = args[0] as Assignment;
    final Teacher teacher = args[1] as Teacher;
    final School school = args[2] as School;
    
    final ViewSubmissionsController controller = Get.put(
      ViewSubmissionsController(assignment, teacher, school)
    );
    
    return Scaffold(
      backgroundColor: AppColors.appLightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.appLightBlue,
        title: Text('Submissions', style: Font_Styles.labelHeadingLight(context)),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }
        
        return Column(
          children: [
            // Statistics Card
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
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
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        'Total Students',
                        controller.allStudents.length.toString(),
                        Colors.blue,
                        Icons.people,
                      ),
                      _buildStatCard(
                        'Submitted',
                        controller.getSubmittedCount().toString(),
                        Colors.green,
                        Icons.check_circle,
                      ),
                      _buildStatCard(
                        'Pending',
                        controller.getPendingCount().toString(),
                        Colors.orange,
                        Icons.pending,
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Filter buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFilterButton('All', 'all', controller),
                      _buildFilterButton('Submitted', 'submitted', controller),
                      _buildFilterButton('Pending', 'pending', controller),
                    ],
                  ),
                ],
              ),
            ),
            
            // Students List
            Expanded(
              child: controller.getFilteredStudents().isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No students found',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: controller.getFilteredStudents().length,
                      itemBuilder: (context, index) {
                        final student = controller.getFilteredStudents()[index];
                        final submission = controller.submissions[student.studentID];
                        
                        return Card(
                          margin: EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: submission != null
                                ? () => _showSubmissionDetails(context, student, submission, controller)
                                : null,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Student Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              student.name,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              '(${student.studentRollNo})',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 4),
                                        if (submission != null) ...[
                                          Text(
                                            'Submitted: ${controller.formatDateTime(submission.submittedDate!)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.green,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (submission.submissionText != null && submission.submissionText!.isNotEmpty) ...[
                                            SizedBox(height: 4),
                                            Text(
                                              submission.submissionText!.length > 50
                                                  ? '${submission.submissionText!.substring(0, 50)}...'
                                                  : submission.submissionText!,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ] else ...[
                                          Text(
                                            'Not submitted',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.orange,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  // Status Icon
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: submission != null
                                          ? Colors.green.shade50
                                          : Colors.orange.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      submission != null
                                          ? Icons.check_circle
                                          : Icons.pending,
                                      color: submission != null
                                          ? Colors.green
                                          : Colors.orange,
                                      size: 24,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }
  
  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
  
  Widget _buildFilterButton(String label, String value, ViewSubmissionsController controller) {
    final isSelected = controller.selectedFilter.value == value;
    return InkWell(
      onTap: () => controller.selectedFilter.value = value,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.appDarkBlue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
  
  void _showSubmissionDetails(
    BuildContext context,
    Student student,
    AssignmentSubmission submission,
    ViewSubmissionsController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          constraints: BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.appDarkBlue,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Roll No: ${student.studentRollNo}',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Submitted Date', controller.formatDateTime(submission.submittedDate!)),
                      SizedBox(height: 16),
                      
                      if (submission.submissionText != null && submission.submissionText!.isNotEmpty) ...[
                        Text(
                          'Submission Text:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            submission.submissionText!,
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        SizedBox(height: 16),
                      ],
                      
                      if (submission.documentPath != null) ...[
                        Text(
                          'Attachments:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        InkWell(
                          onTap: () => _openDocument(context, submission.documentPath!),
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.description, color: Colors.blue, size: 24),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        path.basename(submission.documentPath!),
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        'Tap to open',
                                        style: TextStyle(
                                          color: Colors.blue.shade700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.open_in_new, color: Colors.blue, size: 20),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                      ],
                      
                      if (submission.imagePath != null) ...[
                        if (submission.documentPath == null) ...[
                          Text(
                            'Attachments:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                        ],
                        InkWell(
                          onTap: () => _viewImage(context, submission.imagePath!),
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.image, color: Colors.green, size: 24),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        path.basename(submission.imagePath!),
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        'Tap to view',
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.visibility, color: Colors.green, size: 20),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Footer
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Close'),
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
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _openDocument(BuildContext context, String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final result = await OpenFile.open(filePath);
        if (result.type != ResultType.done) {
          Get.snackbar(
            'Error',
            'Could not open file: ${result.message}',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } else {
        Get.snackbar(
          'Error',
          'File not found',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to open file: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  void _viewImage(BuildContext context, String imagePath) {
    final file = File(imagePath);
    if (!file.existsSync()) {
      Get.snackbar(
        'Error',
        'Image file not found',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(10),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.file(
                  file,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  shape: CircleBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

