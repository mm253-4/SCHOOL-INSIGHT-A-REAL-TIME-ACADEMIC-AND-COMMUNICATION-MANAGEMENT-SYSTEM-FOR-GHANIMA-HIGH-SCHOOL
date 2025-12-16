import 'package:classinsight/Services/Auth_Service.dart';
import 'package:classinsight/models/SchoolModel.dart';
import 'package:classinsight/models/TeacherModel.dart';
import 'package:classinsight/utils/AppColors.dart';
import 'package:classinsight/utils/fontStyles.dart';
import 'package:classinsight/Widgets/ModernCard.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class TeacherDashboardController extends GetxController {
  RxInt height = 120.obs;
  Rx<Teacher?> teacher = Rx<Teacher?>(null);
  Rx<School?> school = Rx<School?>(null);
  final GetStorage _storage = GetStorage();
  var subjectsList = <String>[].obs;
  var classesList = <String>[].obs;
  var selectedClass = ''.obs;
  var arguments;

  @override
  void onInit() {
    super.onInit();
    try {
      arguments = Get.arguments as List?;
    } catch (e) {
      print(e);
      loadCachedData();
    }

    if (arguments != null && arguments.length >= 2) {
      print('I am in if');
      teacher.value = arguments[0] as Teacher?;
      school.value = arguments[1] as School?;

      if (teacher.value != null && school.value != null) {
        cacheData(school.value!, teacher.value!);
      }
    } else {
      loadCachedData();
    }

    fetchClasses();

    if (classesList.isNotEmpty) {
      selectedClass.value = classesList.first;
      updateSubjects(selectedClass.value);
    }

    setupRealTimeListeners();
  }

  void fetchClasses() {
    if (teacher.value != null) {
      classesList.value = teacher.value!.classes;
    }
  }

  void loadCachedData() {
    var cachedSchool = _storage.read('cachedSchool');
    if (cachedSchool != null) {
      school.value = School.fromJson(cachedSchool);
    }
    var cachedTeacher = _storage.read('cachedTeacher');
    if (cachedTeacher != null) {
      teacher.value = Teacher.fromJson(cachedTeacher);
    }
  }

  void cacheData(School school, Teacher teacher) {
    print('Caching data');
    _storage.write('cachedSchool', school.toJson());
    _storage.write('cachedTeacher', teacher.toJson());
    _storage.write('isTeacherLogged', true);
    print('Data cached');
  }

  void clearCachedData() {
    _storage.remove('cachedSchool');
    _storage.remove('cachedTeacher');
    _storage.remove('isTeacherLogged');
  }

  void updateData(School school, Teacher teacher) {
    this.school.value = school;
    this.teacher.value = teacher;
    cacheData(school, teacher);
    fetchClasses();
  }

  void updateSubjects(String selectedClass) {
    subjectsList.value = teacher.value!.subjects[selectedClass] ?? [];
  }

  void setupRealTimeListeners() {
    // SQLite doesn't have real-time listeners
    // Data will be refreshed when screens are opened or actions are performed
    // If periodic refresh is needed, use Stream.periodic similar to AdminHome
    if (teacher.value != null && school.value != null) {
      // Data is already loaded, listeners not needed for SQLite
      // Refresh can be done manually when needed
    }
  }
}

class TeacherDashboard extends StatelessWidget {
  TeacherDashboard({super.key});

  final TeacherDashboardController _controller =
      Get.put(TeacherDashboardController());

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > 350 && screenWidth <= 400) {
      _controller.height.value = 135;
    } else if (screenWidth > 400 && screenWidth <= 500) {
      _controller.height.value = 160;
    } else if (screenWidth > 500 && screenWidth <= 768) {
      _controller.height.value = 220;
    } else if (screenWidth > 768) {
      _controller.height.value = 270;
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(
          "Dashboard",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              _controller.clearCachedData();
              Auth_Service.logout(context);
            },
            icon: Icon(Icons.logout_rounded, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(AppColors.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card with Teacher Info
              ModernCard(
                gradient: AppColors.primaryGradient,
                padding: EdgeInsets.all(AppColors.spacingLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(AppColors.spacingMD),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        SizedBox(width: AppColors.spacingMD),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Hi, ${_controller.teacher.value!.name}",
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: AppColors.spacingXS),
                              Text(
                                _controller.teacher.value!.email,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppColors.spacingMD),
                    if (_controller.teacher.value!.classTeacher.isNotEmpty)
                      ModernCard(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        padding: EdgeInsets.all(AppColors.spacingMD),
                        isElevated: false,
                        child: Row(
                          children: [
                            Icon(Icons.class_, color: Colors.white, size: 20),
                            SizedBox(width: AppColors.spacingSM),
                            Expanded(
                              child: Text(
                                'Class Teacher: ${_controller.teacher.value!.classTeacher}',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              
              SizedBox(height: AppColors.spacingLG),
              
              // Class Selection
              Text(
                "Select Class",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: AppColors.spacingMD),
              
              Obx(
                () => ModernCard(
                  padding: EdgeInsets.all(AppColors.spacingMD),
                  child: DropdownButtonFormField<String>(
                    value: _controller.classesList.contains(
                            _controller.selectedClass.value)
                        ? _controller.selectedClass.value
                        : null,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.class_, color: AppColors.primaryColor),
                      labelText: "Class",
                      labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.backgroundLight,
                    ),
                    items: _controller.classesList.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: GoogleFonts.inter(color: AppColors.textPrimary),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      _controller.selectedClass.value = newValue ?? '';
                      _controller.updateSubjects(newValue ?? '');
                    },
                  ),
                ),
              ),
              
              SizedBox(height: AppColors.spacingLG),
              
              // Quick Actions
              Text(
                "Quick Actions",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: AppColors.spacingMD),
              
              // Action Buttons Grid
              Wrap(
                spacing: AppColors.spacingMD,
                runSpacing: AppColors.spacingMD,
                children: [
                  _buildActionCard(
                    context,
                    "Attendance",
                    Icons.people,
                    AppColors.primaryColor,
                    () {
                      if (_controller.teacher.value != null && _controller.school.value != null && _controller.selectedClass.value.isNotEmpty) {
                        Get.toNamed("/MarkAttendance", arguments: [
                          _controller.school.value!.schoolId,
                          _controller.selectedClass.value,
                          _controller.teacher.value!,
                          _controller.subjectsList.toList()
                        ]);
                      } else {
                        Get.snackbar('Error', 'Please wait for data to load', backgroundColor: Colors.red, colorText: Colors.white);
                      }
                    },
                  ),
                  _buildActionCard(
                    context,
                    "Marks",
                    Icons.assessment,
                    AppColors.warningColor,
                    () {
                      if (_controller.teacher.value != null && _controller.school.value != null && _controller.selectedClass.value.isNotEmpty) {
                        Get.toNamed('/DisplayMarks', arguments: [
                          _controller.school.value!.schoolId,
                          _controller.selectedClass.value,
                          _controller.teacher.value
                        ]);
                      } else {
                        Get.snackbar('Error', 'Please wait for data to load', backgroundColor: Colors.red, colorText: Colors.white);
                      }
                    },
                  ),
                  _buildActionCard(
                    context,
                    "Chat",
                    Icons.chat,
                    AppColors.secondaryColor,
                    () {
                      if (_controller.teacher.value != null && _controller.school.value != null) {
                        Get.toNamed("/TeacherChatList", arguments: [
                          _controller.teacher.value!,
                          _controller.school.value!
                        ]);
                      } else {
                        Get.snackbar('Error', 'Please wait for data to load', backgroundColor: Colors.red, colorText: Colors.white);
                      }
                    },
                  ),
                  _buildActionCard(
                    context,
                    "Group Chats",
                    Icons.group,
                    AppColors.primaryColor,
                    () {
                      if (_controller.teacher.value != null && _controller.school.value != null) {
                        Get.toNamed("/TeacherGroupChatList", arguments: [
                          _controller.teacher.value!,
                          _controller.school.value!
                        ]);
                      } else {
                        Get.snackbar('Error', 'Please wait for data to load', backgroundColor: Colors.red, colorText: Colors.white);
                      }
                    },
                  ),
                  _buildActionCard(
                    context,
                    "Announcements",
                    Icons.campaign,
                    AppColors.warningColor,
                    () {
                      if (_controller.teacher.value != null && _controller.school.value != null) {
                        Get.toNamed("/TeacherMakeAnnouncement", arguments: [
                          _controller.teacher.value!,
                          _controller.school.value!
                        ]);
                      } else {
                        Get.snackbar('Error', 'Please wait for data to load', backgroundColor: Colors.red, colorText: Colors.white);
                      }
                    },
                  ),
                  _buildActionCard(
                    context,
                    "Post Assignment",
                    Icons.assignment,
                    AppColors.accentColor,
                    () {
                      if (_controller.teacher.value != null && _controller.school.value != null) {
                        Get.toNamed("/PostAssignmentScreen", arguments: [
                          _controller.teacher.value!,
                          _controller.school.value!
                        ]);
                      } else {
                        Get.snackbar('Error', 'Please wait for data to load', backgroundColor: Colors.red, colorText: Colors.white);
                      }
                    },
                  ),
                  _buildActionCard(
                    context,
                    "My Assignments",
                    Icons.assignment_turned_in,
                    AppColors.primaryColor,
                    () {
                      if (_controller.teacher.value != null && _controller.school.value != null) {
                        Get.toNamed("/TeacherViewAssignmentsScreen", arguments: [
                          _controller.teacher.value!,
                          _controller.school.value!
                        ]);
                      } else {
                        Get.snackbar('Error', 'Please wait for data to load', backgroundColor: Colors.red, colorText: Colors.white);
                      }
                    },
                  ),
                  _buildActionCard(
                    context,
                    "Change Password",
                    Icons.lock,
                    AppColors.textSecondary,
                    () {
                      if (_controller.teacher.value != null && _controller.school.value != null) {
                        Get.toNamed("/ChangePassword", arguments: [
                          _controller.teacher.value!,
                          _controller.school.value!
                        ]);
                      } else {
                        Get.snackbar('Error', 'Please wait for data to load', backgroundColor: Colors.red, colorText: Colors.white);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String text,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    double screenWidth = MediaQuery.of(context).size.width;
    double buttonWidth = (screenWidth - (AppColors.spacingMD * 3)) / 2;
    
    return SizedBox(
      width: buttonWidth,
      child: ModernCard(
        onTap: onTap,
        padding: EdgeInsets.all(AppColors.spacingMD),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(AppColors.spacingMD),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppColors.borderRadiusMedium),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            SizedBox(height: AppColors.spacingSM),
            Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
