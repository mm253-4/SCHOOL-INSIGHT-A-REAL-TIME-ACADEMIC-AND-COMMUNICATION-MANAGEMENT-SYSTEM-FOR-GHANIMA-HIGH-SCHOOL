import 'dart:io';
import 'package:classinsight/Services/Database_Service.dart';
import 'package:classinsight/models/AssignmentModel.dart';
import 'package:classinsight/models/TeacherModel.dart';
import 'package:classinsight/models/SchoolModel.dart';
import 'package:classinsight/utils/AppColors.dart';
import 'package:classinsight/utils/fontStyles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;

class TeacherViewAssignmentsController extends GetxController {
  final Teacher teacher;
  final School school;
  
  RxList<Assignment> assignments = <Assignment>[].obs;
  RxMap<String, int> submissionCounts = <String, int>{}.obs;
  RxMap<String, int> totalStudentCounts = <String, int>{}.obs;
  RxBool isLoading = true.obs;
  
  TeacherViewAssignmentsController(this.teacher, this.school);
  
  @override
  void onInit() {
    super.onInit();
    loadAssignments();
  }
  
  Future<void> loadAssignments() async {
    try {
      isLoading.value = true;
      print('Loading assignments for teacher: ${teacher.empID} in school: ${school.schoolId}');
      final assignmentsList = await Database_Service.fetchTeacherAssignments(
        school.schoolId,
        teacher.empID,
      );
      print('Received ${assignmentsList.length} assignments from database');
      assignments.assignAll(assignmentsList);
      print('Updated assignments list, now has ${assignments.length} items');
      
      // Load submission counts for each assignment
      for (var assignment in assignmentsList) {
        if (assignment.id != null) {
          await _loadSubmissionStats(assignment.id!, assignment);
        }
      }
    } catch (e) {
      print('Error loading assignments: $e');
      print('Stack trace: ${StackTrace.current}');
      Get.snackbar('Error', 'Failed to load assignments: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> _loadSubmissionStats(String assignmentId, Assignment assignment) async {
    try {
      // Get all students in the assigned classes
      List<String> classes = [];
      if (assignment.assignedClasses != null && assignment.assignedClasses!.isNotEmpty) {
        classes = assignment.assignedClasses!;
      } else if (assignment.className != null) {
        classes = [assignment.className!];
      }
      
      int totalStudents = 0;
      for (var className in classes) {
        final students = await Database_Service.getStudentsOfASpecificClass(
          school.schoolId,
          className,
        );
        totalStudents += students.length;
      }
      totalStudentCounts[assignmentId] = totalStudents;
      
      // Count actual submissions
      final submissions = await Database_Service.getAssignmentSubmissions(assignmentId);
      submissionCounts[assignmentId] = submissions.length;
    } catch (e) {
      print('Error loading submission stats: $e');
      totalStudentCounts[assignmentId] = 0;
      submissionCounts[assignmentId] = 0;
    }
  }
  
  String formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  bool isOverdue(DateTime dueDate) {
    return DateTime.now().isAfter(dueDate);
  }
  
  String getAssignedClasses(Assignment assignment) {
    if (assignment.assignedClasses != null && assignment.assignedClasses!.isNotEmpty) {
      return assignment.assignedClasses!.join(', ');
    }
    return assignment.className ?? 'N/A';
  }
}

class TeacherViewAssignmentsScreen extends StatelessWidget {
  TeacherViewAssignmentsScreen({Key? key}) : super(key: key);
  
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
          title: Text('My Assignments', style: Font_Styles.labelHeadingLight(context)),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    final Teacher teacher = args[0] as Teacher;
    final School school = args[1] as School;
    
    final TeacherViewAssignmentsController controller = Get.put(
      TeacherViewAssignmentsController(teacher, school)
    );
    
    return Scaffold(
      backgroundColor: AppColors.appLightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.appLightBlue,
        title: Text('My Assignments', style: Font_Styles.labelHeadingLight(context)),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (controller.assignments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No assignments posted yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Post your first assignment to get started',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }
        
        return RefreshIndicator(
          onRefresh: controller.loadAssignments,
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: controller.assignments.length,
            itemBuilder: (context, index) {
              final assignment = controller.assignments[index];
              final isOverdue = controller.isOverdue(assignment.dueDate!);
              final submissionCount = controller.submissionCounts[assignment.id] ?? 0;
              final totalStudents = controller.totalStudentCounts[assignment.id] ?? 0;
              
              return Card(
                margin: EdgeInsets.only(bottom: 16),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: InkWell(
                  onTap: () {
                    _showAssignmentDetails(context, assignment, controller);
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                assignment.title ?? 'Untitled',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ),
                            if (isOverdue)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Overdue',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.subject, size: 18, color: AppColors.primaryColor),
                            SizedBox(width: 6),
                            Text(
                              assignment.subject ?? '',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(width: 16),
                            Icon(Icons.class_, size: 18, color: AppColors.primaryColor),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                controller.getAssignedClasses(assignment),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: isOverdue ? Colors.red : AppColors.warningColor,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Due: ${controller.formatDateTime(assignment.dueDate!)}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isOverdue ? Colors.red : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        if (assignment.description != null && assignment.description!.isNotEmpty) ...[
                          SizedBox(height: 10),
                          Text(
                            assignment.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                        // Show attachments if available
                        if (assignment.documentPath != null || assignment.imagePath != null) ...[
                          SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (assignment.documentPath != null)
                                InkWell(
                                  onTap: () => _openDocument(context, assignment.documentPath!),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.blue.shade200),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.description, size: 16, color: Colors.blue),
                                        SizedBox(width: 6),
                                        Text(
                                          'View Document',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (assignment.imagePath != null)
                                InkWell(
                                  onTap: () => _viewImage(context, assignment.imagePath!),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.green.shade200),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.image, size: 16, color: Colors.green),
                                        SizedBox(width: 6),
                                        Text(
                                          'View Image',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                        SizedBox(height: 12),
                        // Submission Statistics with View Button
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.people, color: Colors.blue, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Submissions: $submissionCount / $totalStudents students',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                              if (totalStudents > 0)
                                TextButton.icon(
                                  onPressed: () {
                                    Get.toNamed(
                                      '/ViewSubmissionsScreen',
                                      arguments: [
                                        assignment,
                                        controller.teacher,
                                        controller.school,
                                      ],
                                    );
                                  },
                                  icon: Icon(Icons.visibility, size: 16),
                                  label: Text('View'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.blue.shade700,
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            },
          ),
        );
      }),
    );
  }
  
  void _showAssignmentDetails(BuildContext context, Assignment assignment, TeacherViewAssignmentsController controller) {
    final isOverdue = controller.isOverdue(assignment.dueDate!);
    final submissionCount = controller.submissionCounts[assignment.id] ?? 0;
    final totalStudents = controller.totalStudentCounts[assignment.id] ?? 0;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(assignment.title ?? 'Assignment'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Subject', assignment.subject ?? ''),
              _buildDetailRow('Class(es)', controller.getAssignedClasses(assignment)),
              _buildDetailRow(
                'Posted',
                controller.formatDateTime(assignment.postedDate!),
              ),
              _buildDetailRow(
                'Due Date',
                controller.formatDateTime(assignment.dueDate!),
                isOverdue: isOverdue,
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.people, color: Colors.blue, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Submission Statistics',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '$submissionCount out of $totalStudents students submitted',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          if (totalStudents > 0) ...[
                            SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: submissionCount / totalStudents,
                              backgroundColor: Colors.blue.shade100,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${((submissionCount / totalStudents) * 100).toStringAsFixed(1)}% completion rate',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (assignment.description != null && assignment.description!.isNotEmpty) ...[
                SizedBox(height: 16),
                Text(
                  'Description:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(assignment.description!),
              ],
              if (assignment.documentPath != null || assignment.imagePath != null) ...[
                SizedBox(height: 16),
                Text(
                  'Attachments:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                if (assignment.documentPath != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => _openDocument(context, assignment.documentPath!),
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
                                    path.basename(assignment.documentPath!),
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 4),
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
                  ),
                if (assignment.imagePath != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => _viewImage(context, assignment.imagePath!),
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
                                    path.basename(assignment.imagePath!),
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 4),
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
                  ),
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              Get.toNamed(
                '/ViewSubmissionsScreen',
                arguments: [
                  assignment,
                  controller.teacher,
                  controller.school,
                ],
              );
            },
            icon: Icon(Icons.people),
            label: Text('View Submissions'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.appDarkBlue,
              foregroundColor: Colors.white,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value, {bool isOverdue = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isOverdue ? Colors.red : Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: isOverdue ? Colors.red : Colors.black87),
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

