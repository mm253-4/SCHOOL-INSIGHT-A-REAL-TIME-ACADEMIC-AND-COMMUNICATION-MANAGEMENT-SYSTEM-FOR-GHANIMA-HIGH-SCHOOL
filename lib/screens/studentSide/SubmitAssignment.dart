import 'dart:io';
import 'package:classinsight/Services/Database_Service.dart';
import 'package:classinsight/models/AssignmentModel.dart';
import 'package:classinsight/models/AssignmentSubmissionModel.dart';
import 'package:classinsight/models/StudentModel.dart';
import 'package:classinsight/utils/AppColors.dart';
import 'package:classinsight/utils/fontStyles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class SubmitAssignmentController extends GetxController {
  final Assignment assignment;
  final Student student;
  final String schoolId;
  
  final TextEditingController submissionTextController = TextEditingController();
  Rx<String?> imagePath = Rx<String?>(null);
  Rx<String?> documentPath = Rx<String?>(null);
  RxBool isLoading = false.obs;
  RxBool isSubmitting = false.obs;
  AssignmentSubmission? existingSubmission;
  
  SubmitAssignmentController(this.assignment, this.student, this.schoolId);
  
  @override
  void onInit() {
    super.onInit();
    loadExistingSubmission();
  }
  
  @override
  void onClose() {
    submissionTextController.dispose();
    super.onClose();
  }
  
  Future<void> loadExistingSubmission() async {
    try {
      isLoading.value = true;
      existingSubmission = await Database_Service.getStudentSubmission(
        assignment.id!,
        student.studentID,
      );
      
      if (existingSubmission != null) {
        submissionTextController.text = existingSubmission!.submissionText ?? '';
        imagePath.value = existingSubmission!.imagePath;
        documentPath.value = existingSubmission!.documentPath;
      }
    } catch (e) {
      print('Error loading existing submission: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      
      if (image != null) {
        // Copy image to app's document directory
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String appDocPath = appDocDir.path;
        final String fileName = 'assignment_${assignment.id}_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
        final String newPath = path.join(appDocPath, fileName);
        
        // Copy the file
        final File imageFile = File(image.path);
        await imageFile.copy(newPath);
        
        imagePath.value = newPath;
      }
    } catch (e) {
      print('Error picking image: $e');
      Get.snackbar('Error', 'Failed to pick image');
    }
  }
  
  Future<void> pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        // Copy document to app's document directory
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String appDocPath = appDocDir.path;
        final String fileName = 'submission_${assignment.id}_${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}';
        final String newPath = path.join(appDocPath, fileName);
        
        // Copy the file
        final File sourceFile = File(result.files.single.path!);
        await sourceFile.copy(newPath);
        
        documentPath.value = newPath;
      }
    } catch (e) {
      print('Error picking document: $e');
      Get.snackbar('Error', 'Failed to pick document');
    }
  }

  Future<void> removeImage() async {
    if (imagePath.value != null) {
      try {
        final File imageFile = File(imagePath.value!);
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
      } catch (e) {
        print('Error deleting image: $e');
      }
    }
    imagePath.value = null;
  }

  Future<void> removeDocument() async {
    if (documentPath.value != null) {
      try {
        final File docFile = File(documentPath.value!);
        if (await docFile.exists()) {
          await docFile.delete();
        }
      } catch (e) {
        print('Error deleting document: $e');
      }
    }
    documentPath.value = null;
  }
  
  Future<void> submitAssignment() async {
    if (submissionTextController.text.trim().isEmpty && 
        imagePath.value == null && 
        documentPath.value == null) {
      Get.snackbar('Error', 'Please provide text, an image, or a document',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    
    try {
      isSubmitting.value = true;
      
      final submissionId = existingSubmission?.id ?? 
          '${assignment.id}_${student.studentID}_${DateTime.now().millisecondsSinceEpoch}';
      
      final submission = AssignmentSubmission(
        id: submissionId,
        assignmentId: assignment.id,
        schoolId: schoolId,
        studentId: student.studentID,
        studentName: student.name,
        submissionText: submissionTextController.text.trim().isEmpty 
            ? null 
            : submissionTextController.text.trim(),
        imagePath: imagePath.value,
        documentPath: documentPath.value,
        submittedDate: DateTime.now(),
        status: 'submitted',
      );
      
      await Database_Service.submitAssignment(submission);
      
      Get.snackbar(
        'Success',
        'Assignment submitted successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
      
      await Future.delayed(Duration(seconds: 1));
      Get.back();
    } catch (e) {
      print('Error submitting assignment: $e');
      Get.snackbar('Error', 'Failed to submit assignment: ${e.toString()}',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isSubmitting.value = false;
    }
  }
}

class SubmitAssignmentScreen extends StatelessWidget {
  SubmitAssignmentScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args = Get.arguments as Map<String, dynamic>;
    final Assignment assignment = args['assignment'];
    final Student student = args['student'];
    final String schoolId = args['schoolId'];
    
    final SubmitAssignmentController controller = Get.put(
      SubmitAssignmentController(assignment, student, schoolId)
    );
    
    return Scaffold(
      backgroundColor: AppColors.appLightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.appLightBlue,
        title: Text('Submit Assignment', style: Font_Styles.labelHeadingLight(context)),
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
              
              // Assignment Info Card
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
                      assignment.title ?? 'Assignment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.appDarkBlue,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Subject: ${assignment.subject ?? ''}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    Text(
                      'Due: ${_formatDateTime(assignment.dueDate!)}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 20),
              
              // Submission Text Field
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
                      'Your Answer (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: controller.submissionTextController,
                      maxLines: 10,
                      minLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Type your answer here...',
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
              
              SizedBox(height: 20),
              
              // Document Upload Section
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
                      'Upload Document (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 10),
                    Obx(() {
                      if (controller.documentPath.value != null) {
                        return Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.description, color: Colors.blue, size: 24),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      path.basename(controller.documentPath.value!),
                                      style: TextStyle(fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: controller.removeDocument,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      } else {
                        return ElevatedButton.icon(
                          onPressed: controller.pickDocument,
                          icon: Icon(Icons.upload_file),
                          label: Text('Select Document (PDF, DOC, DOCX, TXT)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.appDarkBlue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        );
                      }
                    }),
                  ],
                ),
              ),
              
              SizedBox(height: 20),
              
              // Image Upload Section
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
                      'Upload Image (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 10),
                    Obx(() {
                      if (controller.imagePath.value != null) {
                        return Column(
                          children: [
                            Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  File(controller.imagePath.value!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _showImageSourceDialog(context, controller),
                                  icon: Icon(Icons.change_circle),
                                  label: Text('Change Image'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.appDarkBlue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 10),
                                ElevatedButton.icon(
                                  onPressed: controller.removeImage,
                                  icon: Icon(Icons.delete),
                                  label: Text('Remove'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => controller.pickImage(ImageSource.camera),
                              icon: Icon(Icons.camera_alt),
                              label: Text('Camera'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.appDarkBlue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => controller.pickImage(ImageSource.gallery),
                              icon: Icon(Icons.photo_library),
                              label: Text('Gallery'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.appDarkBlue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        );
                      }
                    }),
                  ],
                ),
              ),
              
              SizedBox(height: 20),
              
              // Info Text
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.appDarkBlue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.appDarkBlue, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You can submit text, an image, a document, or any combination. At least one is required.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 30),
              
              // Submit Button
              Obx(() => ElevatedButton(
                onPressed: controller.isSubmitting.value ? null : controller.submitAssignment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.appDarkBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: controller.isSubmitting.value
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
                          Text('Submitting...'),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send),
                          SizedBox(width: 10),
                          Text(
                            controller.existingSubmission != null 
                                ? 'Update Submission' 
                                : 'Submit Assignment',
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
  
  void _showImageSourceDialog(BuildContext context, SubmitAssignmentController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                controller.pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                controller.pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

