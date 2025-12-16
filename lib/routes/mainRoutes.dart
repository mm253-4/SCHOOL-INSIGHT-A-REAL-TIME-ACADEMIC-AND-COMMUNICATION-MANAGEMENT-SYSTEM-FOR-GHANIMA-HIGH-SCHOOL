// ignore_for_file: prefer_const_constructors

import 'package:classinsight/models/StudentModel.dart';
import 'package:classinsight/screens/adminSide/AddClassSections.dart';
import 'package:classinsight/screens/adminSide/AddExamSystem.dart';
import 'package:classinsight/screens/adminSide/AddStudent.dart';
import 'package:classinsight/screens/LoginAs.dart';
import 'package:classinsight/screens/SplashScreen.dart';
import 'package:classinsight/screens/adminSide/AddSubjects.dart';
import 'package:classinsight/screens/adminSide/AddWeightage.dart';
import 'package:classinsight/screens/adminSide/AddTeacher.dart';
import 'package:classinsight/screens/adminSide/AddTimetable.dart';
import 'package:classinsight/screens/adminSide/AdminHome.dart';
import 'package:classinsight/screens/adminSide/DeleteTimetable.dart';
import 'package:classinsight/screens/adminSide/EditStudent.dart';
import 'package:classinsight/screens/adminSide/EditTeacher.dart';
import 'package:classinsight/screens/adminSide/LoginScreen.dart';
import 'package:classinsight/screens/adminSide/MakeAnnouncements.dart';
import 'package:classinsight/screens/adminSide/ManageStudents.dart';
import 'package:classinsight/screens/adminSide/ManageTeachers.dart';
import 'package:classinsight/screens/adminSide/ManageTimetable.dart';
import 'package:classinsight/screens/adminSide/StudentResult.dart';
import 'package:classinsight/screens/adminSide/SubjectResult.dart';
import 'package:classinsight/screens/parentSide/ParentDashboard.dart';
import 'package:classinsight/screens/parentSide/ParentLogin.dart';
import 'package:classinsight/screens/parentSide/ParentPayment.dart';
import 'package:classinsight/screens/parentSide/viewAttendance.dart';
import 'package:classinsight/screens/parentSide/viewTimetable.dart';
import 'package:classinsight/screens/studentSide/StudentLogin.dart';
import 'package:classinsight/screens/studentSide/StudentDashboard.dart';
import 'package:classinsight/screens/studentSide/StudentPayment.dart';
import 'package:classinsight/screens/teacherSide/TeacherDashboard.dart';
import 'package:classinsight/screens/teacherSide/MarkAttendance.dart';
import 'package:classinsight/screens/teacherSide/MarksScreen.dart';
import 'package:classinsight/screens/parentSide/Result.dart';
import 'package:classinsight/screens/teacherSide/DisplayMarks.dart';
import 'package:classinsight/screens/teacherSide/ChangePassword.dart';
import 'package:classinsight/screens/studentSide/ChangePassword.dart';
import 'package:classinsight/screens/teacherSide/TeacherChatList.dart';
import 'package:classinsight/screens/teacherSide/TeacherStartChat.dart';
import 'package:classinsight/screens/teacherSide/TeacherChat.dart';
import 'package:classinsight/screens/teacherSide/CreateGroupChat.dart';
import 'package:classinsight/screens/teacherSide/TeacherGroupChatList.dart';
import 'package:classinsight/screens/teacherSide/TeacherGroupChat.dart';
import 'package:classinsight/screens/teacherSide/TeacherMakeAnnouncement.dart';
import 'package:classinsight/screens/parentSide/ParentChatList.dart';
import 'package:classinsight/screens/parentSide/ParentChat.dart';
import 'package:classinsight/screens/parentSide/ParentStartChat.dart';
import 'package:classinsight/screens/parentSide/ParentGroupChatList.dart';
import 'package:classinsight/screens/parentSide/ParentGroupChat.dart';
import 'package:classinsight/screens/studentSide/StudentGroupChatList.dart';
import 'package:classinsight/screens/studentSide/StudentGroupChat.dart';
import 'package:classinsight/screens/adminSide/DatabaseBackup.dart';
import 'package:classinsight/screens/adminSide/AdminSignupScreen.dart';
import 'package:classinsight/screens/teacherSide/PostAssignment.dart';
import 'package:classinsight/screens/teacherSide/TeacherViewAssignments.dart';
import 'package:classinsight/screens/teacherSide/ViewSubmissions.dart';
import 'package:classinsight/screens/studentSide/ViewAssignments.dart';
import 'package:classinsight/screens/studentSide/SubmitAssignment.dart';
import 'package:classinsight/screens/parentSide/ViewAssignments.dart';
import 'package:get/get.dart';

class MainRoutes {
  static List<GetPage> routes = [
    GetPage(
      name: "/splash",
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: "/loginAs",
      page: () => LoginAs(),
    ),
    GetPage(
      name: "/AddStudent",
      page: () => const AddStudent(),
    ),
    GetPage(
      name: "/ManageStudents",
      page: () => ManageStudents(),
    ),
    GetPage(
      name: "/LoginScreen",
      page: () => LoginScreen(),
    ),
    GetPage(
      name: "/AdminHome",
      page: () => AdminHome(),
    ),
    GetPage(
      name: "/EditStudent",
      page: () => EditStudent(
        student: Get.arguments as Student,
      ),
    ),
    GetPage(
      name: "/AddClassSections",
      page: () => AddClassSections(),
    ),
    GetPage(
      name: "/AddSubjects",
      page: () => AddSubjects(),
    ),
    GetPage(
      name: "/AddExamSystem",
      page: () => AddExamSystem(),
    ),
    GetPage(
      name: "/AddTimetable",
      page: () => AddTimetable(),
    ),
    GetPage(
      name: "/ManageTimetable",
      page: () => ManageTimetable(),
    ),
    GetPage(
      name: "/DeleteTimetable",
      page: () => DeleteTimetable(),
    ),
    GetPage(
      name: "/ManageTeachers",
      page: () => ManageTeachers(),
    ),
    GetPage(
      name: "/AddTeacher",
      page: () => AddTeacher(),
    ),
    GetPage(
      name: "/EditTeacher",
      page: () => EditTeacher(),
    ),
    GetPage(
      name: "/StudentResult",
      page: () => StudentResult(),
    ),
    GetPage(
      name: "/MakeAnnouncements",
      page: () => MakeAnnouncements(),
    ),
    GetPage(
      name: "/SubjectResult",
      page: () => SubjectResult(),
    ),
    GetPage(
      name: "/TeacherDashboard",
      page: () => TeacherDashboard(),
    ),
    GetPage(
      name: "/ParentDashboard",
      page: () => ParentDashboard(),
    ),
    GetPage(
      name: "/ParentLogin",
      page: () => ParentLoginScreen(),
    ),
    GetPage(
      name: "/StudentLogin",
      page: () => StudentLoginScreen(),
    ),
    GetPage(
      name: "/StudentDashboard",
      page: () => StudentDashboard(),
    ),
    GetPage(
      name: "/MarksScreen",
      page: () => MarksScreen(),
    ),
    GetPage(
      name: "/Result",
      page: () => Result(),
    ),
    GetPage(
      name: "/AddWeightage",
      page: () => AddWeightage(),
    ),
    GetPage(
      name: "/DisplayMarks",
      page: () => DisplayMarks(),
    ),
    GetPage(
      name: "/MarkAttendance",
      page: () => MarkAttendance(),
    ),
    GetPage(
      name: "/ViewAttendance",
      page: () => ViewAttendance(),
    ),
    GetPage(
      name: "/ViewTimetable",
      page: () => ViewTimetable(),
    ),
    GetPage(
      name: "/ParentPayment",
      page: () => ParentPaymentScreen(),
    ),
    GetPage(
      name: "/StudentPayment",
      page: () => StudentPaymentScreen(),
    ),
    GetPage(
      name: "/ChangePassword",
      page: () => ChangePasswordScreen(),
    ),
    GetPage(
      name: "/StudentChangePassword",
      page: () => StudentChangePasswordScreen(),
    ),
    GetPage(
      name: "/TeacherChatList",
      page: () => TeacherChatListScreen(),
    ),
    GetPage(
      name: "/TeacherStartChat",
      page: () => TeacherStartChatScreen(),
    ),
    GetPage(
      name: "/TeacherChat",
      page: () => TeacherChatScreen(),
    ),
    GetPage(
      name: "/ParentChatList",
      page: () => ParentChatListScreen(),
    ),
    GetPage(
      name: "/ParentChat",
      page: () => ParentChatScreen(),
    ),
    GetPage(
      name: "/ParentStartChat",
      page: () => ParentStartChatScreen(),
    ),
    GetPage(
      name: "/DatabaseBackup",
      page: () => DatabaseBackupScreen(),
    ),
    GetPage(
      name: "/AdminSignup",
      page: () => AdminSignupScreen(),
    ),
    GetPage(
      name: "/CreateGroupChat",
      page: () => CreateGroupChatScreen(),
    ),
    GetPage(
      name: "/TeacherGroupChatList",
      page: () => TeacherGroupChatListScreen(),
    ),
    GetPage(
      name: "/TeacherGroupChat",
      page: () => TeacherGroupChatScreen(),
    ),
    GetPage(
      name: "/ParentGroupChatList",
      page: () => ParentGroupChatListScreen(),
    ),
    GetPage(
      name: "/ParentGroupChat",
      page: () => ParentGroupChatScreen(),
    ),
    GetPage(
      name: "/StudentGroupChatList",
      page: () => StudentGroupChatListScreen(),
    ),
    GetPage(
      name: "/StudentGroupChat",
      page: () => StudentGroupChatScreen(),
    ),
    GetPage(
      name: "/TeacherMakeAnnouncement",
      page: () => TeacherMakeAnnouncementScreen(),
    ),
    GetPage(
      name: "/PostAssignmentScreen",
      page: () => PostAssignmentScreen(),
    ),
    GetPage(
      name: "/TeacherViewAssignmentsScreen",
      page: () => TeacherViewAssignmentsScreen(),
    ),
    GetPage(
      name: "/ViewSubmissionsScreen",
      page: () => ViewSubmissionsScreen(),
    ),
    GetPage(
      name: "/ViewAssignmentsScreen",
      page: () => ViewAssignmentsScreen(),
    ),
    GetPage(
      name: "/SubmitAssignmentScreen",
      page: () => SubmitAssignmentScreen(),
    ),
    GetPage(
      name: "/ParentViewAssignmentsScreen",
      page: () => ParentViewAssignmentsScreen(),
    ),
  ];
}
