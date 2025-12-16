import 'dart:async';

import 'package:classinsight/Services/Database_Service.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:classinsight/models/SchoolModel.dart';
import 'package:classinsight/Services/Auth_Service.dart';
import 'package:classinsight/utils/AppColors.dart';
import 'package:classinsight/utils/fontStyles.dart';
import 'package:classinsight/Widgets/shadowButton.dart';
import 'package:classinsight/Widgets/ModernCard.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AdminHomeController extends GetxController {
  var email = 'test@gmail.com'.obs;
  var schoolName = 'School1'.obs;
  var schoolId = "j".obs;
  RxString totalStudents = '0'.obs;
  RxString totalTeachers = '0'.obs;
  RxInt height = 120.obs;
  Rx<School?> school = Rx<School?>(null);
  final GetStorage _storage = GetStorage();
  StreamSubscription? studentsSubscription;
  StreamSubscription? teachersSubscription;

  @override
  void onInit() {
    super.onInit();
    loadCachedSchoolData();
    var schoolFromArguments = Get.arguments;
    if (schoolFromArguments != null) {
      cacheSchoolData(schoolFromArguments);
      updateSchoolData(schoolFromArguments);
    }
    totalInformation();
    startListeners();
  }

  @override
  void onClose() {
    studentsSubscription?.cancel();
    teachersSubscription?.cancel();
    super.onClose();
  }

  void totalInformation() async {
    print('Fetching counts - schoolName: ${schoolName.value}, schoolId: ${schoolId.value}');
    // Use schoolId directly for more reliable counting
    if (schoolId.value.isNotEmpty) {
      totalTeachers.value = await Database_Service.fetchCountsBySchoolId(schoolId.value, "Teachers");
      totalStudents.value = await Database_Service.fetchCountsBySchoolId(schoolId.value, "Students");
    } else {
      // Fallback to schoolName if schoolId is not available
      totalTeachers.value = await Database_Service.fetchCounts(schoolName.value, "Teachers");
      totalStudents.value = await Database_Service.fetchCounts(schoolName.value, "Students");
    }
    cacheTotalCounts();
    update();
  }

  // Method to refresh counts immediately (call this after adding students/teachers)
  void refreshCounts() {
    print('Refreshing counts immediately');
    totalInformation();
  }

  void startListeners() async {
    try {
      // Ensure schoolId is not empty
      if (schoolId.value.isEmpty) {
        print('Error: schoolId is empty');
        totalStudents.value = '0';
        totalTeachers.value = '0';
        return;
      }

      // Use Database_Service to fetch counts instead of Firebase listeners
      if (schoolId.value.isNotEmpty) {
        totalStudents.value = await Database_Service.fetchCountsBySchoolId(schoolId.value, "Students");
        totalTeachers.value = await Database_Service.fetchCountsBySchoolId(schoolId.value, "Teachers");
      } else {
        totalStudents.value = await Database_Service.fetchCounts(schoolName.value, "Students");
        totalTeachers.value = await Database_Service.fetchCounts(schoolName.value, "Teachers");
      }
      cacheTotalCounts();
      
      // Set up periodic refresh (every 2 seconds) for more responsive updates
      studentsSubscription?.cancel();
      teachersSubscription?.cancel();
      
      studentsSubscription = Stream.periodic(const Duration(seconds: 2)).asyncMap((_) async {
        if (schoolId.value.isNotEmpty) {
          return await Database_Service.fetchCountsBySchoolId(schoolId.value, "Students");
        } else {
          return await Database_Service.fetchCounts(schoolName.value, "Students");
        }
      }).listen((count) {
        totalStudents.value = count;
        cacheTotalCounts();
      });

      teachersSubscription = Stream.periodic(const Duration(seconds: 2)).asyncMap((_) async {
        if (schoolId.value.isNotEmpty) {
          return await Database_Service.fetchCountsBySchoolId(schoolId.value, "Teachers");
        } else {
          return await Database_Service.fetchCounts(schoolName.value, "Teachers");
        }
      }).listen((count) {
        totalTeachers.value = count;
        cacheTotalCounts();
      });
    } catch (e) {
      print('Error starting listeners: $e');
      totalStudents.value = '0';
      totalTeachers.value = '0';
    }
  }


  void clearCachedSchoolData() {
    _storage.remove('cachedSchool');
    _storage.remove('totalTeachers');
    _storage.remove('totalStudents');
  }

  void loadCachedSchoolData() {
    var cachedSchool = _storage.read('cachedSchool');
    if (cachedSchool != null) {
      school.value = School.fromJson(cachedSchool);
      updateSchoolData(school.value!);
    }
    var cachedTotalTeachers = _storage.read('totalTeachers');
    if (cachedTotalTeachers != null) {
      totalTeachers.value = cachedTotalTeachers;
    }
    var cachedTotalStudents = _storage.read('totalStudents');
    if (cachedTotalStudents != null) {
      totalStudents.value = cachedTotalStudents;
    }
  }

  void cacheSchoolData(School school) {
    _storage.write('cachedSchool', school.toJson());
  }

  void cacheTotalCounts() {
    _storage.write('totalTeachers', totalTeachers.value);
    _storage.write('totalStudents', totalStudents.value);
  }

  void updateSchoolData(School school) {
    totalStudents.value = '-';
    totalTeachers.value = '-';
    this.school.value = school;
    schoolId.value = school.schoolId;
    email.value = school.adminEmail;
    schoolName.value = school.name;

     print("Updated schoolId: ${this.schoolId.value}");
  print("Updated schoolName: ${schoolName.value}");
  print("Updated email: ${email.value}");

    if (totalTeachers.value == '-' || totalStudents.value == '-') {
      totalInformation();
    }
    startListeners();
  }
}



class AdminHome extends StatelessWidget {
  AdminHome({Key? key}) : super(key: key);

  final AdminHomeController _controller = Get.put(AdminHomeController());

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
        title: Text(
          "Dashboard",
          style: Font_Styles.labelHeadingLight(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Auth_Service.logout(context);
              _controller.clearCachedSchoolData();
            },
            icon: Icon(Icons.logout_rounded, color: AppColors.textPrimary),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(AppColors.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Padding(
                padding: EdgeInsets.only(bottom: AppColors.spacingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hi, Admin",
                      style: Font_Styles.largeHeadingBold(context).copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: AppColors.spacingXS),
                    Obx(
                      () => Text(
                        _controller.email.value,
                        style: Font_Styles.labelHeadingRegular(context).copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: ModernCard(
                      gradient: AppColors.cardGradient1,
                      padding: EdgeInsets.all(AppColors.spacingLG),
                      margin: EdgeInsets.only(right: AppColors.spacingSM),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(AppColors.spacingMD),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              FontAwesomeIcons.userGraduate,
                              color: AppColors.primaryColor,
                              size: 28,
                            ),
                          ),
                          SizedBox(height: AppColors.spacingMD),
                          Obx(() {
                            return Text(
                              _controller.totalStudents.value,
                              style: Font_Styles.mediumHeadingBold(context).copyWith(
                                fontSize: 32,
                                color: AppColors.primaryColor,
                              ),
                            );
                          }),
                          SizedBox(height: AppColors.spacingXS),
                          Text(
                            "Total Students",
                            textAlign: TextAlign.center,
                            style: Font_Styles.labelHeadingRegular(context).copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ModernCard(
                      gradient: AppColors.cardGradient2,
                      padding: EdgeInsets.all(AppColors.spacingLG),
                      margin: EdgeInsets.only(left: AppColors.spacingSM),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(AppColors.spacingMD),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              FontAwesomeIcons.graduationCap,
                              color: AppColors.secondaryColor,
                              size: 28,
                            ),
                          ),
                          SizedBox(height: AppColors.spacingMD),
                          Obx(() {
                            return Text(
                              _controller.totalTeachers.value,
                              style: Font_Styles.mediumHeadingBold(context).copyWith(
                                fontSize: 32,
                                color: AppColors.secondaryColor,
                              ),
                            );
                          }),
                          SizedBox(height: AppColors.spacingXS),
                          Text(
                            "Total Teachers",
                            textAlign: TextAlign.center,
                            style: Font_Styles.labelHeadingRegular(context).copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: AppColors.spacingLG),
              
              // Quick Actions Section
              Text(
                "Quick Actions",
                style: Font_Styles.mediumHeadingBold(context).copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: AppColors.spacingMD),
              
              // Action Buttons Grid
              Wrap(
                spacing: AppColors.spacingMD,
                runSpacing: AppColors.spacingMD,
                children: [
                  _buildActionButton(
                    context,
                    "Manage Students",
                    Icons.people,
                    AppColors.primaryColor,
                    () => Get.toNamed("/ManageStudents"),
                  ),
                  _buildActionButton(
                    context,
                    "Manage Teachers",
                    Icons.school,
                    AppColors.secondaryColor,
                    () => Get.toNamed("/ManageTeachers", arguments: _controller.school.value),
                  ),
                  _buildActionButton(
                    context,
                    "Manage Timetable",
                    Icons.calendar_today,
                    AppColors.accentColor,
                    () => Get.toNamed("/ManageTimetable"),
                  ),
                  _buildActionButton(
                    context,
                    "Announcements",
                    Icons.announcement,
                    AppColors.warningColor,
                    () => Get.toNamed("/MakeAnnouncements"),
                  ),
                  _buildActionButton(
                    context,
                    "Classes & Subjects",
                    Icons.class_,
                    AppColors.primaryLight,
                    () => Get.toNamed("/AddClassSections"),
                  ),
                  _buildActionButton(
                    context,
                    "Results",
                    Icons.assessment,
                    AppColors.errorColor,
                    () => Get.toNamed("/SubjectResult"),
                  ),
                  _buildActionButton(
                    context,
                    "Database Backup",
                    Icons.backup,
                    AppColors.textSecondary,
                    () => Get.toNamed("/DatabaseBackup"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
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
              padding: EdgeInsets.all(AppColors.spacingSM),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppColors.borderRadiusMedium),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            SizedBox(height: AppColors.spacingSM),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Font_Styles.labelHeadingRegular(context).copyWith(
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