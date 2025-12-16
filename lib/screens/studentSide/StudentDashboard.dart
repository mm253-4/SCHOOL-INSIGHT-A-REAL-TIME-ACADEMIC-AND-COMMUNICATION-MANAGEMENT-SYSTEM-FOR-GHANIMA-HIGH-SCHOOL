import 'dart:async';

import 'package:classinsight/Services/Auth_Service.dart';
import 'package:classinsight/Services/Database_Service.dart';
import 'package:classinsight/models/AnnouncementsModel.dart';
import 'package:classinsight/models/SchoolModel.dart';
import 'package:classinsight/models/StudentModel.dart';
import 'package:classinsight/utils/AppColors.dart';
import 'package:classinsight/utils/fontStyles.dart';
import 'package:classinsight/Widgets/ModernCard.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class StudentDashboardController extends GetxController {
  RxInt height = 120.obs;
  Rx<Student?> student = Rx<Student?>(null);
  Rx<School?> school = Rx<School?>(null);
  RxList<Announcement> mainAnnouncements = <Announcement>[].obs;
  RxList<Announcement> teacherComments = <Announcement>[].obs;
  var selectedClass = ''.obs;
  var feedetails = ''.obs;
  RxBool isLoading = true.obs;
  Color feeColor = Colors.red;
  final GetStorage _storage = GetStorage();
  var arguments;
  StreamSubscription<Student?>? studentSubscription;
  StreamSubscription<School?>? schoolSubscription;

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
      student.value = arguments[0] as Student?;
      school.value = arguments[1] as School?;

      if (student.value != null && school.value != null) {
        cacheData(school.value!, student.value!);
        addListeners();
      }
    } else {
      loadCachedData();
    }
    feeStatus();
    fetchAnnouncements();
  }

  @override
  void onClose() {
    super.onClose();
    studentSubscription?.cancel();
    schoolSubscription?.cancel();
  }

  void loadCachedData() {
    var cachedSchool = _storage.read('cachedSchool');
    if (cachedSchool != null) {
      school.value = School.fromJson(cachedSchool);
      if (school.value != null) {
        addListeners();
      }
    }
    var cachedStudent = _storage.read('cachedStudent');
    if (cachedStudent != null) {
      student.value = Student.fromJson(cachedStudent);
    }
  }

  void cacheData(School school, Student student) {
    print('Caching data');
    _storage.write('cachedSchool', school.toJson());
    _storage.write('cachedStudent', student.toJson());
    _storage.write('isStudentLogged', true);
    print('Data cached');
  }

  void clearCachedData() {
    _storage.remove('cachedSchool');
    _storage.remove('cachedStudent');
    _storage.remove('isStudentLogged');
  }

  void updateData(School school, Student student) {
    this.school.value = school;
    this.student.value = student;
    cacheData(school, student);
  }

  void feeStatus() {
    if (student.value != null && student.value!.feeStatus == 'paid') {
      feedetails.value = '${student.value!.feeStatus} (${student.value!.feeStartDate} ${student.value!.feeEndDate})';
      feeColor = Colors.green;
    } else {
      feeColor = Colors.red;
    }
  }

  void fetchAnnouncements() async {
    if (school.value != null && student.value != null) {
      isLoading.value = true;

      final adminAnnouncements = await Database_Service.fetchAdminAnnouncements(
          school.value!.schoolId);
      if (adminAnnouncements != null) {
        mainAnnouncements.assignAll(adminAnnouncements);
      }

      final studentAnnouncements = await Database_Service.fetchStudentAnnouncements(
          school.value!.schoolId, student.value!.studentID);
      if (studentAnnouncements != null) {
        teacherComments.assignAll(studentAnnouncements);
      }

      isLoading.value = false;
    }
  }

  void addListeners() {
    if (school.value != null && student.value != null) {
      // Use periodic refresh instead of Firebase real-time listeners
      studentSubscription?.cancel();
      schoolSubscription?.cancel();
      
      // Refresh student data every 5 seconds
      studentSubscription = Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
        return await Database_Service.getStudentByID(school.value!.schoolId, student.value!.studentID);
      }).listen((updatedStudent) {
        if (updatedStudent != null) {
          student.value = updatedStudent;
          feeStatus();
        }
      });

      // School data doesn't change frequently, so we can skip periodic refresh
      // Or refresh less frequently if needed
    }
  }
}



class StudentDashboard extends StatelessWidget {
  StudentDashboard({super.key});

  final StudentDashboardController _controller =
      Get.put(StudentDashboardController());

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    final dateFormatter = DateFormat('dd MMM yyyy, hh:mm a');

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
          "My Dashboard",
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
              // Welcome Card with Student Info
              ModernCard(
                gradient: AppColors.blueGradient,
                padding: EdgeInsets.all(AppColors.spacingLG),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(AppColors.spacingMD),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.school_rounded,
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
                                "Hi, ${_controller.student.value?.name ?? 'Student'}",
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: AppColors.spacingXS),
                              Text(
                                'Roll No: ${_controller.student.value?.studentRollNo ?? ''}',
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
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoChip(
                            Icons.class_,
                            'Class',
                            _controller.student.value?.classSection ?? '',
                            Colors.white.withOpacity(0.35),
                          ),
                        ),
                        SizedBox(width: AppColors.spacingSM),
                        Expanded(
                          child: Obx(() => Container(
                            padding: EdgeInsets.all(AppColors.spacingMD),
                            decoration: BoxDecoration(
                              color: _controller.feeColor == Colors.green 
                                  ? Colors.green.withOpacity(0.4)
                                  : Colors.red.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(AppColors.borderRadiusMedium),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _controller.feeColor == Colors.green 
                                      ? Icons.check_circle
                                      : Icons.error,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: AppColors.spacingXS),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Fee Status',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                      Text(
                                        _controller.feedetails.value.isNotEmpty 
                                            ? _controller.feedetails.value
                                            : (_controller.feeColor == Colors.green ? 'Paid' : 'Pending'),
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: AppColors.spacingLG),
              
              // Announcements Section
              Text(
                "Announcements",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: AppColors.spacingMD),
              
              Obx(() {
                if (_controller.isLoading.value) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppColors.spacingXL),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                      ),
                    ),
                  );
                } else {
                  return ModernCard(
                    padding: EdgeInsets.all(AppColors.spacingMD),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.announcement, color: AppColors.primaryColor, size: 20),
                            SizedBox(width: AppColors.spacingSM),
                            Text(
                              'Last 7 Days',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppColors.spacingMD),
                        if (_controller.mainAnnouncements.isEmpty && _controller.teacherComments.isEmpty)
                          Padding(
                            padding: EdgeInsets.all(AppColors.spacingMD),
                            child: Text(
                              'No announcements yet',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textLight,
                              ),
                            ),
                          )
                        else ...[
                          if (_controller.mainAnnouncements.isNotEmpty) ...[
                            Text(
                              'Announcements:',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: AppColors.spacingSM),
                            ..._controller.mainAnnouncements.take(3).map((announcement) {
                              final deadlineText = announcement.deadline != null
                                  ? dateFormatter.format(announcement.deadline!)
                                  : null;
                              final timelineText = (announcement.timeline ?? '').trim();

                              return Padding(
                                padding: EdgeInsets.only(bottom: AppColors.spacingSM),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryColor,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    SizedBox(width: AppColors.spacingSM),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            announcement.announcementDescription ?? '',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          if (deadlineText != null) ...[
                                            SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.event, size: 14, color: AppColors.textSecondary),
                                                SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    'Deadline: $deadlineText',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.textSecondary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          if (timelineText.isNotEmpty) ...[
                                            SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.schedule, size: 14, color: AppColors.textSecondary),
                                                SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    timelineText,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.textSecondary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          SizedBox(height: 4),
                                          Text(
                                            '- ${announcement.announcementBy ?? ''}',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                          if (_controller.teacherComments.isNotEmpty) ...[
                            SizedBox(height: AppColors.spacingMD),
                            Text(
                              'Teacher Comments:',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: AppColors.spacingSM),
                            ..._controller.teacherComments.take(3).map((comment) {
                              final deadlineText = comment.deadline != null
                                  ? dateFormatter.format(comment.deadline!)
                                  : null;
                              final timelineText = (comment.timeline ?? '').trim();

                              return Padding(
                                padding: EdgeInsets.only(bottom: AppColors.spacingSM),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppColors.secondaryColor,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    SizedBox(width: AppColors.spacingSM),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            comment.announcementDescription ?? '',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          if (deadlineText != null) ...[
                                            SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.event_available, size: 14, color: AppColors.textSecondary),
                                                SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    'Deadline: $deadlineText',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.textSecondary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          if (timelineText.isNotEmpty) ...[
                                            SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.schedule, size: 14, color: AppColors.textSecondary),
                                                SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    timelineText,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.textSecondary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          SizedBox(height: 4),
                                          Text(
                                            '- ${comment.announcementBy ?? ''}',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      ],
                    ),
                  );
                }
              }),
              
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
                    "Timetable",
                    Icons.schedule,
                    AppColors.primaryColor,
                    () => Get.toNamed("/ViewTimetable", arguments: [
                      _controller.school.value!.schoolId,
                      _controller.student.value
                    ]),
                  ),
                  _buildActionCard(
                    context,
                    "Attendance",
                    Icons.people,
                    AppColors.primaryColor,
                    () => Get.toNamed("/ViewAttendance", arguments: _controller.student.value),
                  ),
                  _buildActionCard(
                    context,
                    "Assignments",
                    Icons.assignment,
                    AppColors.warningColor,
                    () => Get.toNamed('/ViewAssignmentsScreen', arguments: {
                      'student': _controller.student.value,
                      'schoolId': _controller.school.value!.schoolId,
                    }),
                  ),
                  _buildActionCard(
                    context,
                    "Results",
                    Icons.assessment,
                    AppColors.accentColor,
                    () => Get.toNamed('/Result', arguments: {
                      'student': _controller.student.value,
                      'schoolId': _controller.school.value!.schoolId,
                    }),
                  ),
                  _buildActionCard(
                    context,
                    "Payment",
                    Icons.payment,
                    AppColors.accentColor,
                    () => Get.toNamed("/StudentPayment", arguments: [
                      _controller.student.value,
                      _controller.school.value,
                    ]),
                  ),
                  _buildActionCard(
                    context,
                    "Group Chats",
                    Icons.group,
                    AppColors.secondaryColor,
                    () => Get.toNamed("/StudentGroupChatList", arguments: [
                      _controller.student.value!,
                      _controller.school.value!
                    ]),
                  ),
                  _buildActionCard(
                    context,
                    "Change Password",
                    Icons.lock,
                    AppColors.textSecondary,
                    () => Get.toNamed("/StudentChangePassword", arguments: [
                      _controller.student.value!,
                      _controller.school.value!
                    ]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value, Color bgColor) {
    return Container(
      padding: EdgeInsets.all(AppColors.spacingMD),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppColors.borderRadiusMedium),
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          SizedBox(width: AppColors.spacingXS),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
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

