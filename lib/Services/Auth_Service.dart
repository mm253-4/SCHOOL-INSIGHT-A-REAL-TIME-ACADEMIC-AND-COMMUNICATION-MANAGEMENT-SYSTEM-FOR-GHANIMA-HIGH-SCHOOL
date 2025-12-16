// ignore_for_file: unused_local_variable

import 'package:classinsight/models/SchoolModel.dart';
import 'package:classinsight/models/StudentModel.dart';
import 'package:classinsight/models/TeacherModel.dart';
import 'package:classinsight/utils/AppColors.dart';
import 'package:classinsight/Services/DatabaseHelper.dart';
import 'package:classinsight/Services/Database_Service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'dart:convert';

class Auth_Service {
  static final DatabaseHelper _dbHelper = DatabaseHelper();

static Future<void> loginAdmin(String email, String password, School school) async {
  try {
      print("HEREEE" + school.schoolId);
      final db = await _dbHelper.database;
      
      // Verify admin credentials
      final result = await db.query(
        'Schools',
        where: 'schoolId = ? AND adminEmail = ?',
        whereArgs: [school.schoolId, email],
      );

      if (result.isEmpty && email != 'teamclassinsight@gmail.com') {
        Get.snackbar('Login Error', 'Email does not match the admin email for the school');
        return;
      }

      // For now, we'll skip password check for SQLite migration
      // In production, you should hash and compare passwords
      if (email == 'teamclassinsight@gmail.com' || (result.isNotEmpty && school.adminEmail == email)) {
        Get.snackbar('Logging In', '',
          backgroundColor: Colors.white, 
          showProgressIndicator: true,
          progressIndicatorBackgroundColor: AppColors.appDarkBlue
          );

        await Future.delayed(const Duration(seconds: 1));

        Get.offAllNamed('/AdminHome', arguments: school);
        Get.snackbar('Logged in Successfully', "Welcome, Admin - ${school.name}", duration: const Duration(seconds: 1));
        print("Logged IN");
      } else {
        Get.snackbar('Login Error', 'Invalid credentials');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  static Future<void> loginOrSignupAdmin(String email, String password) async {
    try {
      final db = await _dbHelper.database;
      
      // Check if admin exists with this email
      final result = await db.query(
        'Schools',
        where: 'adminEmail = ?',
        whereArgs: [email],
      );

      if (result.isNotEmpty) {
        // Admin exists - login
        final school = School(
          name: result.first['schoolName'] as String,
          schoolId: result.first['schoolId'] as String,
          adminEmail: result.first['adminEmail'] as String,
        );

        Get.snackbar('Logging In', '',
          backgroundColor: Colors.white, 
          showProgressIndicator: true,
          progressIndicatorBackgroundColor: AppColors.appDarkBlue
          );

        await Future.delayed(const Duration(seconds: 1));

        Get.offAllNamed('/AdminHome', arguments: school);
        Get.snackbar('Logged in Successfully', "Welcome, Admin - ${school.name}", duration: const Duration(seconds: 1));
      } else {
        // Admin doesn't exist - create new school
        // Generate school ID from email
        final schoolId = email.split('@')[0].replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_') + '_' + DateTime.now().millisecondsSinceEpoch.toString();
        final schoolName = 'New School'; // User can update this later
        
        await Database_Service.saveSchool(schoolName, schoolId, email, password);
        
        final school = School(
          name: schoolName,
          schoolId: schoolId,
          adminEmail: email,
        );
        
        Get.snackbar('Sign Up Successful', 'New school created. Please update school details in settings.',
          duration: const Duration(seconds: 2));
        
        await Future.delayed(const Duration(seconds: 1));
        
        Get.offAllNamed('/AdminHome', arguments: school);
        Get.snackbar('Welcome', "Welcome, Admin - ${school.name}", duration: const Duration(seconds: 1));
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  // Separate login function for admin without school
  static Future<void> loginAdminWithoutSchool(String email, String password) async {
    try {
      final db = await _dbHelper.database;
      
      // Check if admin exists with this email
      final result = await db.query(
        'Schools',
        where: 'adminEmail = ?',
        whereArgs: [email],
      );

      if (result.isEmpty) {
        Get.snackbar('Login Error', 'No admin account found with this email. Please sign up instead.');
        return;
      }

      // Verify password
      final storedPassword = result.first['adminPassword'] as String?;
      if (storedPassword != password) {
        Get.snackbar('Error', 'Incorrect password');
        return;
      }

      // Admin exists - login
      final school = School(
        name: result.first['schoolName'] as String,
        schoolId: result.first['schoolId'] as String,
        adminEmail: result.first['adminEmail'] as String,
      );

      Get.snackbar('Logging In', '',
        backgroundColor: Colors.white, 
        showProgressIndicator: true,
        progressIndicatorBackgroundColor: AppColors.appDarkBlue
      );

      await Future.delayed(const Duration(seconds: 1));

      Get.offAllNamed('/AdminHome', arguments: school);
      Get.snackbar('Logged in Successfully', "Welcome, Admin - ${school.name}", duration: const Duration(seconds: 1));
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  // Separate signup function for admin without school
  static Future<void> signUpAdminWithoutSchool(String email, String password) async {
    try {
      final db = await _dbHelper.database;
      
      // Check if admin email already exists
      final existingResult = await db.query(
        'Schools',
        where: 'adminEmail = ?',
        whereArgs: [email],
      );

      if (existingResult.isNotEmpty) {
        Get.snackbar('Sign Up Error', 'An account with this email already exists. Please login instead.');
        return;
      }

      // Generate school ID from email
      final schoolId = email.split('@')[0].replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_') + '_' + DateTime.now().millisecondsSinceEpoch.toString();
      final schoolName = 'New School'; // User can update this later
      
      await Database_Service.saveSchool(schoolName, schoolId, email, password);
      
      final school = School(
        name: schoolName,
        schoolId: schoolId,
        adminEmail: email,
      );
      
      Get.snackbar('Sign Up Successful', 'New school created. Please update school details in settings.',
        duration: const Duration(seconds: 2));
      
      await Future.delayed(const Duration(seconds: 1));
      
      Get.offAllNamed('/AdminHome', arguments: school);
      Get.snackbar('Welcome', "Welcome, Admin - ${school.name}", duration: const Duration(seconds: 1));
    } catch (e) {
      Get.snackbar('Error', 'Failed to sign up: ${e.toString()}');
    }
  }

  // Sign up admin with full details (name, ID, email, schoolName, password)
  static Future<void> signUpAdminWithDetails(
    String name,
    String id,
    String email,
    String schoolName,
    String password,
  ) async {
    try {
      final db = await _dbHelper.database;
      
      // Check if admin email already exists
      final existingEmailResult = await db.query(
        'Schools',
        where: 'adminEmail = ?',
        whereArgs: [email],
      );

      if (existingEmailResult.isNotEmpty) {
        Get.snackbar('Sign Up Error', 'An account with this email already exists. Please login instead.',
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      // Check if school name already exists
      final existingSchoolNameResult = await db.query(
        'Schools',
        where: 'schoolName = ?',
        whereArgs: [schoolName],
      );

      if (existingSchoolNameResult.isNotEmpty) {
        Get.snackbar('Sign Up Error', 'This School Name is already taken. Please choose a different one.',
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      // Generate school ID from school name and timestamp
      final schoolId = schoolName.toLowerCase()
          .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '') + '_' + DateTime.now().millisecondsSinceEpoch.toString();
      
      await Database_Service.saveSchool(schoolName, schoolId, email, password, adminName: name, adminId: id);
      
      final school = School(
        name: schoolName,
        schoolId: schoolId,
        adminEmail: email,
      );
      
      Get.snackbar('Sign Up Successful', 'Your admin account has been created successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2));
      
      await Future.delayed(const Duration(seconds: 1));
      
      Get.offAllNamed('/AdminHome', arguments: school);
      Get.snackbar('Welcome', "Welcome, ${name} - ${school.name}", 
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2));
    } catch (e) {
      Get.snackbar('Error', 'Failed to sign up: ${e.toString()}',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  static Future<void> signUpAdmin(String schoolName, String email, String password) async {
    try {
      final db = await _dbHelper.database;
      
      // Check if admin email already exists
      final existingResult = await db.query(
        'Schools',
        where: 'adminEmail = ?',
        whereArgs: [email],
      );

      if (existingResult.isNotEmpty) {
        Get.snackbar('Sign Up Error', 'An account with this email already exists. Please login instead.');
        return;
      }

      // Generate school ID from email
      final schoolId = email.split('@')[0].replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_') + '_' + DateTime.now().millisecondsSinceEpoch.toString();
      
      await Database_Service.saveSchool(schoolName, schoolId, email, password);
      
      final school = School(
        name: schoolName,
        schoolId: schoolId,
        adminEmail: email,
      );
      
      Get.snackbar('Sign Up Successful', 'Your school account has been created successfully!',
        duration: const Duration(seconds: 2));
      
      await Future.delayed(const Duration(seconds: 1));
      
      Get.offAllNamed('/AdminHome', arguments: school);
      Get.snackbar('Welcome', "Welcome, Admin - ${school.name}", duration: const Duration(seconds: 1));
    } catch (e) {
      Get.snackbar('Error', 'Failed to sign up: ${e.toString()}');
    }
  }

  static Future<void> loginTeacherWithoutSchool(String email, String password) async {
    try {
      final db = await _dbHelper.database;
      
      // Find teacher by email
      final result = await db.query(
        'Teachers',
        where: 'email = ?',
        whereArgs: [email],
      );

      if (result.isEmpty) {
        Get.snackbar('Login Error', 'No teacher found with this email. Please select a school or contact your administrator.');
        return;
      }

      // Verify password
      final teacherData = result.first;
      final storedPassword = teacherData['password'] as String?;

      if (storedPassword != password) {
        Get.snackbar('Error', 'Email or password incorrect');
        return;
      }

      // Get school info
      final schoolResult = await db.query(
        'Schools',
        where: 'schoolId = ?',
        whereArgs: [teacherData['schoolId']],
      );

      if (schoolResult.isEmpty) {
        Get.snackbar('Error', 'School not found');
        return;
      }

      final school = School(
        name: schoolResult.first['schoolName'] as String,
        schoolId: schoolResult.first['schoolId'] as String,
        adminEmail: schoolResult.first['adminEmail'] as String,
      );

      // Login teacher
      await loginTeacher(email, password, school);
  } catch (e) {
    Get.snackbar('Error', e.toString());
  }
}

static Future<void> logout(BuildContext context) async {
    // Show confirmation dialog
    final shouldLogout = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Logout'),
        content: Text('Do you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('Yes'),
          ),
        ],
      ),
    );

    // If user clicked "No" or dismissed the dialog, don't logout
    if (shouldLogout != true) {
      return;
    }

    try {
      Get.snackbar('Logging out', '',
          backgroundColor: Colors.white, 
          showProgressIndicator: true,
          progressIndicatorBackgroundColor: AppColors.appDarkBlue
          );

      await Future.delayed(const Duration(seconds: 2));

      Get.deleteAll();

      Get.snackbar('Logged out successfully!', '',
          backgroundColor: Colors.white, duration: const Duration(seconds: 2));

      Get.offAllNamed("/loginAs");
    } catch (e) {
      print('Error logging out: $e');
      Get.snackbar('Error logging out', e.toString(),
          backgroundColor: Colors.red, duration: const Duration(seconds: 2));
    }
  }

  static Future<void> signUpTeacher(
    School school,
    String name,
    String email,
    String password,
    String employeeId,
    String phoneNo,
  ) async {
    try {
      final db = await _dbHelper.database;
      
      // Check if teacher email already exists
      final existingResult = await db.query(
        'Teachers',
        where: 'email = ? AND schoolId = ?',
        whereArgs: [email, school.schoolId],
      );

      if (existingResult.isNotEmpty) {
        Get.snackbar('Sign Up Error', 'A teacher with this email already exists in this school.');
        return;
      }

      // Check if employee ID already exists
      if (employeeId.isNotEmpty) {
        final empIdResult = await db.query(
          'Teachers',
          where: 'employeeId = ? AND schoolId = ?',
          whereArgs: [employeeId, school.schoolId],
        );
        
        if (empIdResult.isNotEmpty) {
          Get.snackbar('Sign Up Error', 'Employee ID already exists. Please use a different ID.');
          return;
        }
      }

      // Create teacher account
      await Database_Service.saveTeacher(
        school.schoolId,
        employeeId,
        name,
        'Not Specified', // Gender - can be updated later
        email,
        phoneNo,
        '', // CNIC - can be added later
        '', // Father Name - can be added later
        [], // Classes - can be assigned by admin
        {}, // Subjects - can be assigned by admin
        '', // Class Teacher - can be assigned by admin
        password,
      );

      Get.snackbar('Sign Up Successful', 'Your teacher account has been created! Please contact admin for account activation.',
        duration: const Duration(seconds: 3));
      
      // Navigate to login screen
      await Future.delayed(const Duration(seconds: 1));
      Get.back(); // Go back to LoginAs screen
      Get.snackbar('Info', 'Please login with your email and password');
    } catch (e) {
      Get.snackbar('Error', 'Failed to sign up: ${e.toString()}');
    }
  }

  static Future<void> signUpParent(School school, String admissionNumber) async {
    try {
      final db = await _dbHelper.database;
      
      // Check if student with this admission number (studentRollNo) exists
      final studentResult = await db.query(
        'Students',
        where: 'studentRollNo = ? AND schoolId = ?',
        whereArgs: [admissionNumber, school.schoolId],
      );

      if (studentResult.isEmpty) {
        Get.snackbar('Sign Up Error', 'No student found with this admission number. Please contact your school administrator.');
        return;
      }

      Get.snackbar('Sign Up Successful', 'Your parent account is ready! You can now login.',
        duration: const Duration(seconds: 2));
      
      // Navigate to parent login
      await Future.delayed(const Duration(seconds: 1));
      Get.offNamed('/ParentLogin', arguments: school);
    } catch (e) {
      Get.snackbar('Error', 'Failed to sign up: ${e.toString()}');
    }
  }

  static Future<void> signUpStudent(
    School school,
    String name,
    String admissionNumber,
    String email,
    String password,
  ) async {
    try {
      final db = await _dbHelper.database;
      
      // Check if student with this admission number exists
      final studentResult = await db.query(
        'Students',
        where: 'studentRollNo = ? AND schoolId = ?',
        whereArgs: [admissionNumber, school.schoolId],
      );

      if (studentResult.isEmpty) {
        Get.snackbar('Sign Up Error', 'No student found with this admission number. Please contact your school administrator.');
        return;
      }

      // Check if email is already registered
      final emailCheck = await db.query(
        'Students',
        where: 'email = ? AND schoolId = ? AND email IS NOT NULL AND email != ""',
        whereArgs: [email, school.schoolId],
      );

      if (emailCheck.isNotEmpty) {
        Get.snackbar('Sign Up Error', 'An account with this email already exists.');
        return;
      }

      // Verify name matches (optional validation)
      final studentData = studentResult.first;
      final existingName = studentData['name'] as String;
      if (name.trim().toLowerCase() != existingName.trim().toLowerCase()) {
        Get.snackbar('Warning', 'Name does not match records. Please verify your details.');
      }

      // Update student record with email and password
      await db.update(
        'Students',
        {
          'email': email,
          'password': password,
          'name': name, // Update name if different
        },
        where: 'studentRollNo = ? AND schoolId = ?',
        whereArgs: [admissionNumber, school.schoolId],
      );

      Get.snackbar('Sign Up Successful', 'Your student account has been created! You can now login.',
        duration: const Duration(seconds: 2));
      
      // Navigate to student login
      await Future.delayed(const Duration(seconds: 1));
      Get.offNamed('/StudentLogin', arguments: school);
    } catch (e) {
      Get.snackbar('Error', 'Failed to sign up: ${e.toString()}');
    }
  }

  static Future<bool> changeStudentPassword(String schoolId, String studentId, String currentPassword, String newPassword) async {
    try {
      final db = await _dbHelper.database;
      
      // Get current student data
      final studentResult = await db.query(
        'Students',
        where: 'studentId = ? AND schoolId = ?',
        whereArgs: [studentId, schoolId],
      );

      if (studentResult.isEmpty) {
        Get.snackbar('Error', 'Student not found');
        return false;
      }

      final studentData = studentResult.first;
      final storedPassword = studentData['password'] as String? ?? '1234567';
      
      // Verify current password
      if (storedPassword != currentPassword) {
        Get.snackbar('Error', 'Current password is incorrect');
        return false;
      }

      // Update password
      await db.update(
        'Students',
        {'password': newPassword},
        where: 'studentId = ? AND schoolId = ?',
        whereArgs: [studentId, schoolId],
      );

      // Success notification is handled in the UI
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to change password: ${e.toString()}');
      return false;
    }
  }

  static Future<bool> changeTeacherPassword(String schoolId, String employeeId, String currentPassword, String newPassword) async {
    try {
      final db = await _dbHelper.database;
      
      // Get current teacher data
      final teacherResult = await db.query(
        'Teachers',
        where: 'employeeId = ? AND schoolId = ?',
        whereArgs: [employeeId, schoolId],
      );

      if (teacherResult.isEmpty) {
        Get.snackbar('Error', 'Teacher not found');
        return false;
      }

      final teacherData = teacherResult.first;
      final storedPassword = teacherData['password'] as String?;
      
      if (storedPassword == null || storedPassword.isEmpty) {
        Get.snackbar('Error', 'Password not set for this teacher');
        return false;
      }
      
      // Verify current password
      if (storedPassword != currentPassword) {
        Get.snackbar('Error', 'Current password is incorrect');
        return false;
      }

      // Update password
      await db.update(
        'Teachers',
        {'password': newPassword},
        where: 'employeeId = ? AND schoolId = ?',
        whereArgs: [employeeId, schoolId],
      );

      // Success notification is handled in the UI
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to change password: ${e.toString()}');
      return false;
    }
  }

  static Future<void> loginStudent(School? school, String admissionNumber, String password) async {
    try {
      Get.snackbar('Logging In', '',
          backgroundColor: Colors.white, 
          showProgressIndicator: true,
          progressIndicatorBackgroundColor: AppColors.appDarkBlue
      );

      final db = await _dbHelper.database;

      // Trim and normalize the admission number
      final trimmedAdmissionNumber = admissionNumber.trim().toLowerCase();

      // If no school provided, find student across all schools by admission number
      String? schoolId;
      if (school != null) {
        schoolId = school.schoolId;
      }

      // Get all students (or filtered by school) and filter in Dart for better compatibility
      List<Map<String, dynamic>> allStudents;
      if (schoolId != null) {
        allStudents = await db.query(
          'Students',
          where: 'schoolId = ?',
          whereArgs: [schoolId],
        );
      } else {
        allStudents = await db.query('Students');
      }

      // Find student by admission number - case insensitive search in Dart
      Map<String, dynamic>? foundStudent;
      for (var studentRow in allStudents) {
        final rollNo = (studentRow['studentRollNo'] as String? ?? '').trim().toLowerCase();
        final bFormId = (studentRow['bFormChallanId'] as String? ?? '').trim().toLowerCase();
        
        if (rollNo == trimmedAdmissionNumber || bFormId == trimmedAdmissionNumber) {
          foundStudent = studentRow;
          break;
        }
      }

      if (foundStudent == null) {
        Get.snackbar('Error', 'No student found with this admission number');
        print('Searching for admission number: "$trimmedAdmissionNumber"');
        return;
      }

      final studentData = foundStudent;
      
      // Verify password
      final storedPassword = studentData['password'] as String? ?? '1234567';
      if (storedPassword != password) {
        Get.snackbar('Error', 'Incorrect password. Default password is 1234567');
        return;
      }

      // Get school for navigation if not provided
      School? studentSchool = school;
      if (studentSchool == null) {
        final schoolIdFromStudent = studentData['schoolId'] as String;
        final schoolResult = await db.query(
          'Schools',
          where: 'schoolId = ?',
          whereArgs: [schoolIdFromStudent],
        );
        if (schoolResult.isNotEmpty) {
          final schoolData = schoolResult.first;
          studentSchool = School(
            schoolId: schoolData['schoolId'] as String,
            name: schoolData['schoolName'] as String,
            adminEmail: schoolData['adminEmail'] as String,
          );
        }
      }

      Student student = Student(
        name: studentData['name'] as String,
        gender: studentData['gender'] as String,
        bFormChallanId: studentData['bFormChallanId'] as String,
        fatherName: studentData['fatherName'] as String,
        fatherPhoneNo: studentData['fatherPhoneNo'] as String,
        fatherCNIC: studentData['fatherCNIC'] as String,
        studentRollNo: studentData['studentRollNo'] as String,
        studentID: studentData['studentId'] as String,
        classSection: studentData['classSection'] as String,
        feeStatus: studentData['feeStatus'] as String,
        feeStartDate: studentData['feeStartDate'] as String? ?? '',
        feeEndDate: studentData['feeEndDate'] as String? ?? '',
        resultMap: _parseNestedMapFromJson(studentData['resultMap'] as String?),
        attendance: _parseNestedMapFromJson(studentData['attendance'] as String?),
      );

      if (studentSchool == null) {
        Get.snackbar('Error', 'School information not found');
        return;
      }

      Get.snackbar('Success', 'Login successful');
      Get.offAllNamed('/StudentDashboard', arguments: [student, studentSchool]);
    } catch (e) {
      Get.snackbar('Error', 'An error occurred: ${e.toString()}');
    }
  }

  static Future<void> registerTeacher(String email, String password, String schoolId) async {
    try {
      // Password will be stored in Teachers table when teacher is created
      // This method can be used to validate email uniqueness if needed
      final db = await _dbHelper.database;
      final result = await db.query(
        'Teachers',
        where: 'email = ? AND schoolId = ?',
        whereArgs: [email, schoolId],
      );

      if (result.isNotEmpty) {
        Get.snackbar('Registration Error', 'A teacher with this email already exists');
        return;
      }

      // Teacher registration will be completed when teacher details are saved
      print('Teacher email registered: $email');
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

static Future<void> loginTeacher(String email, String password, School school) async {
  try {
        Get.snackbar('Logging In', '',
        backgroundColor: Colors.white, 
        showProgressIndicator: true,
        progressIndicatorBackgroundColor: AppColors.appDarkBlue
      );

      final db = await _dbHelper.database;

      // Find teacher by email
      final teacherResult = await db.query(
        'Teachers',
        where: 'email = ? AND schoolId = ?',
        whereArgs: [email, school.schoolId],
      );

      if (teacherResult.isEmpty) {
      Get.snackbar('Error', 'No teacher found with this email');
      return;
    }

      // Verify password (in production, use hashed passwords)
      final teacherData = teacherResult.first;
      final storedPassword = teacherData['password'] as String?;

      if (storedPassword != password) {
        Get.snackbar('Error', 'Email or password incorrect');
        return;
      }

      // Parse teacher data
      Teacher teacher = Teacher(
        empID: teacherData['employeeId'] as String,
        name: teacherData['name'] as String,
        gender: teacherData['gender'] as String,
        email: teacherData['email'] as String,
        cnic: teacherData['cnic'] as String,
        phoneNo: teacherData['phoneNo'] as String,
        fatherName: teacherData['fatherName'] as String,
        classes: _parseJsonToList(teacherData['classes'] as String?),
        subjects: _parseSubjectsFromJson(teacherData['subjects'] as String?),
        classTeacher: teacherData['classTeacher'] as String,
      );

      print('Hi ${teacher.email}');

      Get.snackbar('Success', 'Login successful');
      Get.offAllNamed('/TeacherDashboard', arguments: [teacher, school]);
  } catch (e) {
    Get.snackbar('Error', 'Email or password incorrect');
  }
}

  static List<String> _parseJsonToList(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      return List<String>.from(jsonDecode(jsonStr));
    } catch (e) {
      return [];
    }
  }

  static Map<String, List<String>> _parseSubjectsFromJson(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return {};
    try {
      Map<String, dynamic> decoded = jsonDecode(jsonStr);
      Map<String, List<String>> result = {};
      decoded.forEach((key, value) {
        if (value is String) {
          result[key] = _parseJsonToList(value);
        } else if (value is List) {
          result[key] = List<String>.from(value);
        }
      });
      return result;
    } catch (e) {
      return {};
    }
  }

static Future<void> sendPasswordEmail(String teacherEmail, String teacherName, String password) async {
    try {
      final googleEmail = dotenv.env['GOOGLE_EMAIL'];
      final googlePassword = dotenv.env['GOOGLE_PASSWORD'];
      
      if (googleEmail == null || googlePassword == null || googleEmail.isEmpty || googlePassword.isEmpty) {
        print('Email configuration not found in .env file. Skipping email send.');
        Get.snackbar('Note', 'Password generated: $password. Email not sent - .env configuration missing.');
        return;
      }
      
      final smtpServer = gmail(googleEmail, googlePassword);

    final message = Message()
        ..from = Address(googleEmail, 'Class Insight')
      ..recipients.add(teacherEmail)
      ..subject = 'Login Credentials for Class Insight'
      ..text = 'Hi $teacherName,\n\nWelcome to Class Insight 😀. Please use the following password to log in to your Teacher Dashboard:\n\nPassword: $password\n\nBest Regards,\nClass Insight Team';

      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
    } on MailerException catch (e) {
      print('Message not sent.');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
      Get.snackbar('Email Error', 'Failed to send email. Password: $password');
    } catch (e) {
      print('An unexpected error occurred: $e');
      Get.snackbar('Email Error', 'Failed to send email. Password: $password');
    }
  }

  static Future<void> loginParent(String admissionNumber) async {
    try {
      Get.snackbar('Logging In', '',
          backgroundColor: Colors.white, 
          showProgressIndicator: true,
          progressIndicatorBackgroundColor: AppColors.appDarkBlue
          );

      final db = await _dbHelper.database;

      // Trim and normalize the admission number
      final trimmedAdmissionNumber = admissionNumber.trim().toLowerCase();

      // Get all students and filter in Dart for better compatibility
      final allStudents = await db.query('Students');

      // Find student by admission number (studentRollNo) - case insensitive search
      Map<String, dynamic>? foundStudent;
      for (var studentRow in allStudents) {
        final rollNo = (studentRow['studentRollNo'] as String? ?? '').trim().toLowerCase();
        final bFormId = (studentRow['bFormChallanId'] as String? ?? '').trim().toLowerCase();
        
        if (rollNo == trimmedAdmissionNumber || bFormId == trimmedAdmissionNumber) {
          foundStudent = studentRow;
          break;
        }
      }

      if (foundStudent == null) {
        Get.snackbar('Error', 'No student found with this admission number');
        print('Searching for admission number: "$trimmedAdmissionNumber"');
        // Debug: List all student roll numbers for troubleshooting
        print('Available students: ${allStudents.map((s) => '${s['studentRollNo']} / ${s['bFormChallanId']}').join(', ')}');
        return;
      }

      // Use found student
      final studentData = foundStudent;
      final schoolId = studentData['schoolId'] as String;
      
      // Get the school information
      final schoolResult = await db.query(
        'Schools',
        where: 'schoolId = ?',
        whereArgs: [schoolId],
      );

      if (schoolResult.isEmpty) {
        Get.snackbar('Error', 'School information not found');
        return;
      }

      final schoolData = schoolResult.first;
      School school = School(
        schoolId: schoolData['schoolId'] as String,
        name: schoolData['schoolName'] as String,
        adminEmail: schoolData['adminEmail'] as String,
      );

      Student student = Student(
        name: studentData['name'] as String,
        gender: studentData['gender'] as String,
        bFormChallanId: studentData['bFormChallanId'] as String,
        fatherName: studentData['fatherName'] as String,
        fatherPhoneNo: studentData['fatherPhoneNo'] as String,
        fatherCNIC: studentData['fatherCNIC'] as String,
        studentRollNo: studentData['studentRollNo'] as String,
        studentID: studentData['studentId'] as String,
        classSection: studentData['classSection'] as String,
        feeStatus: studentData['feeStatus'] as String,
        feeStartDate: studentData['feeStartDate'] as String? ?? '',
        feeEndDate: studentData['feeEndDate'] as String? ?? '',
        resultMap: _parseNestedMapFromJson(studentData['resultMap'] as String?),
        attendance: _parseNestedMapFromJson(studentData['attendance'] as String?),
      );

        Get.snackbar('Success', 'Login successful');
      Get.offAllNamed('/ParentDashboard', arguments: [student, school]);
    } catch (e) {
      Get.snackbar('Error', 'An error occurred: ${e.toString()}');
    }
  }

  static Map<String, Map<String, String>> _parseNestedMapFromJson(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return {};
    try {
      Map<String, dynamic> decoded = jsonDecode(jsonStr);
      Map<String, Map<String, String>> result = {};
      decoded.forEach((key, value) {
        if (value is Map) {
          result[key] = Map<String, String>.from(value.map((k, v) => MapEntry(k.toString(), v.toString())));
        }
      });
      return result;
    } catch (e) {
      return {};
    }
  }
}
