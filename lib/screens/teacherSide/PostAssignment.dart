import 'dart:io';
import 'package:classinsight/Services/Database_Service.dart';
import 'package:classinsight/models/AssignmentModel.dart';
import 'package:classinsight/models/SchoolModel.dart';
import 'package:classinsight/models/TeacherModel.dart';
import 'package:classinsight/utils/AppColors.dart';
import 'package:classinsight/utils/fontStyles.dart';
import 'package:classinsight/utils/name_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class PostAssignmentController extends GetxController {
  final Teacher teacher;
  final School school;
  
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  RxList<String> classesList = <String>[].obs;
  RxList<String> subjectsList = <String>[].obs;
  RxString selectedClass = ''.obs;
  RxString selectedSubject = ''.obs;
  RxList<String> selectedClasses = <String>[].obs;
  Rx<DateTime?> dueDate = Rx<DateTime?>(null);
  Rx<String?> documentPath = Rx<String?>(null);
  Rx<String?> imagePath = Rx<String?>(null);
  RxBool isLoading = false.obs;
  RxBool isPosting = false.obs;
  
  PostAssignmentController(this.teacher, this.school);
  
  @override
  void onInit() {
    super.onInit();
    loadClasses();
  }
  
  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    super.onClose();
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
        final String fileName = 'assignment_${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}';
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

  Future<void> pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      
      if (image != null) {
        // Copy image to app's document directory
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String appDocPath = appDocDir.path;
        final String fileName = 'assignment_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
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

  Future<void> removeImage() async {
    if (imagePath.value != null) {
      try {
        final File imgFile = File(imagePath.value!);
        if (await imgFile.exists()) {
          await imgFile.delete();
        }
      } catch (e) {
        print('Error deleting image: $e');
      }
    }
    imagePath.value = null;
  }
  
  Future<void> loadClasses() async {
    try {
      isLoading.value = true;
      if (teacher.classes.isNotEmpty) {
        classesList.assignAll(teacher.classes);
        if (classesList.isNotEmpty) {
          selectedClass.value = classesList.first;
          loadSubjects(classesList.first);
        }
      }
    } catch (e) {
      print('Error loading classes: $e');
      Get.snackbar('Error', 'Failed to load classes');
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> loadSubjects(String className) async {
    try {
      final subjects = await Database_Service.fetchSubjects(school.schoolId, className);
      subjectsList.assignAll(subjects);
      if (subjectsList.isNotEmpty && selectedSubject.value.isEmpty) {
        selectedSubject.value = subjectsList.first;
      }
    } catch (e) {
      print('Error loading subjects: $e');
    }
  }
  
  Future<void> selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        dueDate.value = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );
      }
    }
  }
  
  Future<void> postAssignment() async {
    if (titleController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter an assignment title',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    
    if (selectedSubject.value.isEmpty) {
      Get.snackbar('Error', 'Please select a subject',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    
    if (selectedClasses.isEmpty) {
      Get.snackbar('Error', 'Please select at least one class',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    
    if (dueDate.value == null) {
      Get.snackbar('Error', 'Please select a due date',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    
    try {
      isPosting.value = true;
      
      final now = DateTime.now();
      
      // Create assignment for each selected class
      for (int i = 0; i < selectedClasses.length; i++) {
        final className = selectedClasses[i];
        // Add index to timestamp to ensure unique IDs when posting to multiple classes
        final assignmentId = '${school.schoolId}_${teacher.empID}_${now.millisecondsSinceEpoch}_${i}_$className';
        
        final assignment = Assignment(
          id: assignmentId,
          schoolId: school.schoolId,
          teacherId: teacher.empID,
          teacherName: formatTeacherTitle(teacher.name, teacher.gender),
          className: className,
          subject: selectedSubject.value,
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          dueDate: dueDate.value,
          postedDate: now,
          documentPath: documentPath.value,
          imagePath: imagePath.value,
          assignedClasses: selectedClasses.length > 1 ? selectedClasses : null,
        );
        
        print('Creating assignment for class: $className');
        print('Assignment ID: $assignmentId');
        await Database_Service.createAssignment(assignment);
        print('Assignment created successfully for class: $className');
      }
      
      final classListText = selectedClasses.length == 1 
          ? selectedClasses.first 
          : '${selectedClasses.length} classes';
      
      Get.snackbar(
        'Success',
        'Assignment posted to $classListText',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
      
      titleController.clear();
      descriptionController.clear();
      selectedClasses.clear();
      dueDate.value = null;
      documentPath.value = null;
      imagePath.value = null;
      
      await Future.delayed(Duration(seconds: 1));
      Get.back();
    } catch (e) {
      print('Error posting assignment: $e');
      Get.snackbar('Error', 'Failed to post assignment: ${e.toString()}',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isPosting.value = false;
    }
  }
  
  void toggleClassSelection(String className) {
    if (selectedClasses.contains(className)) {
      selectedClasses.remove(className);
    } else {
      selectedClasses.add(className);
    }
  }
  
  void onClassChanged(String? newClass) {
    if (newClass != null) {
      selectedClass.value = newClass;
      loadSubjects(newClass);
      selectedSubject.value = '';
    }
  }
}

class PostAssignmentScreen extends StatelessWidget {
  PostAssignmentScreen({Key? key}) : super(key: key);
  
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
          title: Text('Post Assignment', style: Font_Styles.labelHeadingLight(context)),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    final Teacher teacher = args[0] as Teacher;
    final School school = args[1] as School;
    
    final PostAssignmentController controller = Get.put(PostAssignmentController(teacher, school));
    
    double screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: AppColors.appLightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.appLightBlue,
        title: Text('Post Assignment', style: Font_Styles.labelHeadingLight(context)),
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
              
              // Title Field
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
                      'Assignment Title *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: controller.titleController,
                      decoration: InputDecoration(
                        hintText: 'Enter assignment title...',
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
                      textCapitalization: TextCapitalization.words,
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
                      'Subject *',
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
                      items: controller.subjectsList.map((subject) {
                        return DropdownMenuItem(
                          value: subject,
                          child: Text(subject),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          controller.selectedSubject.value = value;
                        }
                      },
                      hint: Text('Select Subject'),
                    )),
                  ],
                ),
              ),
              
              SizedBox(height: 20),
              
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
                          maxHeight: screenHeight * 0.25,
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
              
              // Due Date Selection
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
                      'Due Date *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 10),
                    Obx(() => InkWell(
                      onTap: () => controller.selectDueDate(context),
                      child: Container(
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: AppColors.appDarkBlue),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                controller.dueDate.value != null
                                    ? '${controller.dueDate.value!.day}/${controller.dueDate.value!.month}/${controller.dueDate.value!.year} ${controller.dueDate.value!.hour.toString().padLeft(2, '0')}:${controller.dueDate.value!.minute.toString().padLeft(2, '0')}'
                                    : 'Select due date and time',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: controller.dueDate.value != null ? Colors.black87 : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                  ],
                ),
              ),
              
              SizedBox(height: 20),
              
              // Description Field
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
                      'Description (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: controller.descriptionController,
                      maxLines: 6,
                      minLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter assignment description...',
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
              
              SizedBox(height: 30),
              
              // Post Button
              Obx(() => ElevatedButton(
                onPressed: controller.isPosting.value ? null : controller.postAssignment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.appDarkBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: controller.isPosting.value
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
                          Text('Posting...'),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment),
                          SizedBox(width: 10),
                          Text(
                            'Post Assignment',
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
  
  void _showImageSourceDialog(BuildContext context, PostAssignmentController controller) {
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
}

