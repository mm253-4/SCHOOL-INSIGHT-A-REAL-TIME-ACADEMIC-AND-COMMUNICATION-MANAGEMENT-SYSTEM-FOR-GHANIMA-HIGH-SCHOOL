import 'dart:convert';
import 'package:classinsight/models/AnnouncementsModel.dart';
import 'package:classinsight/models/SchoolModel.dart';
import 'package:classinsight/models/TeacherModel.dart';
import 'package:classinsight/models/StudentModel.dart';
import 'package:classinsight/models/PaymentModel.dart';
import 'package:classinsight/models/ChatModel.dart';
import 'package:classinsight/models/AssignmentModel.dart';
import 'package:classinsight/models/AssignmentSubmissionModel.dart';
import 'package:classinsight/Services/DatabaseHelper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';

class Database_Service extends GetxService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Helper methods for JSON serialization
  String _mapToJson(Map<String, dynamic> map) {
    return jsonEncode(map);
  }

  Map<String, dynamic> _jsonToMap(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(jsonStr));
    } catch (e) {
      return {};
    }
  }

  String _listToJson(List<dynamic> list) {
    return jsonEncode(list);
  }

  List<String> _jsonToList(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      return List<String>.from(jsonDecode(jsonStr));
    } catch (e) {
      return [];
    }
  }

  String _nestedMapToJson(Map<String, Map<String, String>> map) {
    Map<String, dynamic> converted = {};
    map.forEach((key, value) {
      converted[key] = value;
    });
    return jsonEncode(converted);
  }

  Map<String, Map<String, String>> _jsonToNestedMap(String? jsonStr) {
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

  // Save Student
  Future<void> saveStudent(BuildContext? context, String schoolID,
      String classSection, Student student, String password) async {
    final db = await _dbHelper.database;
    try {
      // Check if student with same admission number already exists
      final existingStudent = await db.query(
        'Students',
        where: 'studentRollNo = ? AND schoolId = ?',
        whereArgs: [student.studentRollNo, schoolID],
      );

      if (existingStudent.isNotEmpty) {
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('A student with the same admission number already exists.')),
          );
        }
        return;
      }

      // Generate studentID if not provided
      if (student.studentID.isEmpty) {
        student.studentID = student.studentRollNo; // Use admission number as student ID
      }

      // Fetch subjects and exam types
      List<String> subjects = await fetchSubjects(schoolID, classSection);
      List<String> examTypes = await fetchExamStructure(schoolID, classSection);

      // Create resultMap
      Map<String, Map<String, String>> resultMap = {};
      for (String subject in subjects) {
        resultMap[subject] = {};
        for (String examType in examTypes) {
          resultMap[subject]![examType] = '-';
        }
      }

      // Prepare student data
      Map<String, dynamic> studentData = {
        'studentId': student.studentID,
        'schoolId': schoolID,
        'name': student.name,
        'gender': student.gender,
        'bFormChallanId': student.bFormChallanId,
        'fatherName': student.fatherName,
        'fatherPhoneNo': student.fatherPhoneNo,
        'fatherCNIC': student.fatherCNIC,
        'studentRollNo': student.studentRollNo,
        'classSection': student.classSection,
        'feeStatus': student.feeStatus,
        'feeStartDate': student.feeStartDate,
        'feeEndDate': student.feeEndDate,
        'resultMap': _nestedMapToJson(resultMap),
        'attendance': _nestedMapToJson(student.attendance),
      };

      // Check if password column exists before adding it
      try {
        final columns = await db.rawQuery('PRAGMA table_info(Students)');
        final hasPasswordColumn = columns.any((col) => col['name'] == 'password');
        if (hasPasswordColumn) {
          studentData['password'] = password; // Use provided password
        }
        
        // Add payment fields if columns exist
        final hasPaidAmountColumn = columns.any((col) => col['name'] == 'paidAmount');
        if (hasPaidAmountColumn) {
          studentData['paidAmount'] = 0.0;
          studentData['balanceAmount'] = 40000.0; // Default fee per term
          studentData['feePerTerm'] = 40000.0;
        }
      } catch (e) {
        print('Could not check for columns: $e');
        // Try to add fields anyway - will fail gracefully if columns don't exist
        studentData['password'] = password;
      }

      await db.insert('Students', studentData);

      print('Student saved successfully with ID: ${student.studentID}');
    } catch (e) {
      print('Error saving student: $e');
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving student: $e')),
        );
      }
    }
  }

  Future<Map<String, Map<String, String>>> fetchStudentResultMap(
      String schoolID, String studentID, {String? term}) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.query(
        'Students',
        where: 'studentId = ? AND schoolId = ?',
        whereArgs: [studentID, schoolID],
      );

      if (result.isNotEmpty) {
        final resultMapJson = result.first['resultMap'] as String?;
        if (resultMapJson == null || resultMapJson.isEmpty) {
          return {};
        }
        
        // Try to parse as year-term-based structure: Map<"YYYY_Class_Term", Map<Subject, Map<ExamType, Marks>>>
        try {
          final parsedMap = jsonDecode(resultMapJson);
          
          // Check if it's a year-term-based structure
          if (parsedMap is Map && parsedMap.isNotEmpty) {
            final firstKey = parsedMap.keys.first.toString();
            final isYearTermStructure = RegExp(r'^\d{4}_[^_]+_(Term\s*\d+|term\s*\d+)', caseSensitive: false).hasMatch(firstKey);
            
            if (isYearTermStructure) {
              // It's year-term-based structure
              if (term != null && term.isNotEmpty && parsedMap.containsKey(term)) {
                // Return results for specific year-term
                final termData = parsedMap[term] as Map;
                return Map<String, Map<String, String>>.from(
                  termData.map((key, value) => MapEntry(
                    key.toString(),
                    Map<String, String>.from(value as Map),
                  )),
                );
              } else if (term == null || term.isEmpty) {
                // No term specified, return latest year-term
                final terms = parsedMap.keys.toList();
                if (terms.isNotEmpty) {
                  // Sort to get the latest term
                  terms.sort((a, b) {
                    final aMatch = RegExp(r'^(\d{4})_([^_]+)_(Term\s*\d+|term\s*\d+)', caseSensitive: false).firstMatch(a.toString());
                    final bMatch = RegExp(r'^(\d{4})_([^_]+)_(Term\s*\d+|term\s*\d+)', caseSensitive: false).firstMatch(b.toString());
                    if (aMatch != null && bMatch != null) {
                      final aYear = int.parse(aMatch.group(1)!);
                      final bYear = int.parse(bMatch.group(1)!);
                      if (aYear != bYear) return bYear.compareTo(aYear);
                      final aTermNum = RegExp(r'\d+').firstMatch(aMatch.group(3)!);
                      final bTermNum = RegExp(r'\d+').firstMatch(bMatch.group(3)!);
                      if (aTermNum != null && bTermNum != null) {
                        return int.parse(bTermNum.group(0)!).compareTo(int.parse(aTermNum.group(0)!));
                      }
                    }
                    return b.toString().compareTo(a.toString());
                  });
                  
                  final latestTerm = terms.first;
                  final termData = parsedMap[latestTerm] as Map;
                  return Map<String, Map<String, String>>.from(
                    termData.map((key, value) => MapEntry(
                      key.toString(),
                      Map<String, String>.from(value as Map),
                    )),
                  );
                }
              }
            } else {
              // Check for old term-only structure (backward compatibility)
              final firstKeyValue = parsedMap[firstKey];
              if (firstKeyValue is Map) {
                // It's term-based structure (old format)
                if (term != null && term.isNotEmpty && parsedMap.containsKey(term)) {
                  final termData = parsedMap[term] as Map;
                  return Map<String, Map<String, String>>.from(
                    termData.map((key, value) => MapEntry(
                      key.toString(),
                      Map<String, String>.from(value as Map),
                    )),
                  );
                } else if (term == null || term.isEmpty) {
                  final terms = parsedMap.keys.toList();
                  if (terms.isNotEmpty) {
                    final latestTerm = terms.last;
                    final termData = parsedMap[latestTerm] as Map;
                    return Map<String, Map<String, String>>.from(
                      termData.map((key, value) => MapEntry(
                        key.toString(),
                        Map<String, String>.from(value as Map),
                      )),
                    );
                  }
                }
              }
            }
          }
        } catch (e) {
          print('Error parsing resultMap: $e');
        }
        
        // Fallback to old structure (backward compatibility)
        return _jsonToNestedMap(resultMapJson);
      }
      return {};
    } catch (e) {
      print('Error fetching resultMap: $e');
      return {};
    }
  }
  
  // Get available terms for a student (returns year-based terms)
  static Future<List<String>> getStudentTerms(String schoolID, String studentID) async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final result = await db.query(
        'Students',
        where: 'studentId = ? AND schoolId = ?',
        whereArgs: [studentID, schoolID],
      );

      if (result.isNotEmpty) {
        final resultMapJson = result.first['resultMap'] as String?;
        if (resultMapJson != null && resultMapJson.isNotEmpty) {
          try {
            final parsedMap = jsonDecode(resultMapJson);
            if (parsedMap is Map && parsedMap.isNotEmpty) {
              final keys = parsedMap.keys.map((e) => e.toString()).toList();
              
              // Filter keys that match year_class_term pattern: "YYYY_ClassName_TermN"
              final termKeys = keys.where((key) {
                // Pattern: 4 digits (year) + underscore + class name + underscore + term
                return RegExp(r'^\d{4}_[^_]+_(Term\s*\d+|term\s*\d+)', caseSensitive: false).hasMatch(key);
              }).toList();
              
              if (termKeys.isNotEmpty) {
                // Sort by year (descending), then by class, then by term number
                termKeys.sort((a, b) {
                  // Extract year, class, and term from keys
                  final aMatch = RegExp(r'^(\d{4})_([^_]+)_(Term\s*\d+|term\s*\d+)', caseSensitive: false).firstMatch(a);
                  final bMatch = RegExp(r'^(\d{4})_([^_]+)_(Term\s*\d+|term\s*\d+)', caseSensitive: false).firstMatch(b);
                  
                  if (aMatch != null && bMatch != null) {
                    final aYear = int.parse(aMatch.group(1)!);
                    final bYear = int.parse(bMatch.group(1)!);
                    
                    // Sort by year (newest first)
                    if (aYear != bYear) {
                      return bYear.compareTo(aYear);
                    }
                    
                    // Same year, sort by class name
                    final aClass = aMatch.group(2)!;
                    final bClass = bMatch.group(2)!;
                    if (aClass != bClass) {
                      return bClass.compareTo(aClass); // Reverse for newest class first
                    }
                    
                    // Same class, sort by term number
                    final aTermNum = RegExp(r'\d+').firstMatch(aMatch.group(3)!);
                    final bTermNum = RegExp(r'\d+').firstMatch(bMatch.group(3)!);
                    if (aTermNum != null && bTermNum != null) {
                      return int.parse(bTermNum.group(0)!).compareTo(int.parse(aTermNum.group(0)!));
                    }
                  }
                  return b.compareTo(a);
                });
                
                return termKeys;
              }
              
              // Check for old term-only format (backward compatibility)
              final oldTermKeys = keys.where((key) {
                final lowerKey = key.toLowerCase().trim();
                return lowerKey.startsWith('term') || 
                       RegExp(r'^term\s*\d+', caseSensitive: false).hasMatch(lowerKey);
              }).toList();
              
              if (oldTermKeys.isNotEmpty) {
                // Convert old format to new format with current year and class
                final currentClass = result.first['classSection'] as String? ?? '';
                final currentYear = DateTime.now().year.toString();
                return oldTermKeys.map((key) => '${currentYear}_${currentClass}_$key').toList();
              }
            }
          } catch (e) {
            print('Error parsing resultMap for terms: $e');
          }
        }
      }
      
      // Default: return current year terms if no data exists
      final currentClass = result.isNotEmpty ? (result.first['classSection'] as String? ?? '') : '';
      final currentYear = DateTime.now().year.toString();
      return [
        '${currentYear}_${currentClass}_Term 1',
        '${currentYear}_${currentClass}_Term 2',
        '${currentYear}_${currentClass}_Term 3'
      ];
    } catch (e) {
      print('Error getting student terms: $e');
      final currentYear = DateTime.now().year.toString();
      return [
        '${currentYear}_Class_Term 1',
        '${currentYear}_Class_Term 2',
        '${currentYear}_Class_Term 3'
      ];
    }
  }
  
  // Get formatted display string for term (e.g., "2024 - Class 6 - Term 1")
  static String formatTermDisplay(String termKey) {
    final match = RegExp(r'^(\d{4})_([^_]+)_(Term\s*\d+|term\s*\d+)', caseSensitive: false).firstMatch(termKey);
    if (match != null) {
      final year = match.group(1)!;
      final className = match.group(2)!;
      final term = match.group(3)!;
      return '$year - $className - $term';
    }
    // Fallback for old format
    return termKey;
  }
  
  // Get all unique terms from students in a specific class
  static Future<List<String>> getClassTerms(String schoolID, String className) async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      
      // Get all students in the class
      final students = await getStudentsOfASpecificClass(schoolID, className);
      
      if (students.isEmpty) {
        // Return default current year terms
        final currentYear = DateTime.now().year.toString();
        return [
          '${currentYear}_${className}_Term 1',
          '${currentYear}_${className}_Term 2',
          '${currentYear}_${className}_Term 3'
        ];
      }
      
      // Collect all unique terms from all students
      final Set<String> allTerms = {};
      
      for (var student in students) {
        final studentTerms = await getStudentTerms(schoolID, student.studentID);
        allTerms.addAll(studentTerms);
      }
      
      if (allTerms.isEmpty) {
        // Return default current year terms
        final currentYear = DateTime.now().year.toString();
        return [
          '${currentYear}_${className}_Term 1',
          '${currentYear}_${className}_Term 2',
          '${currentYear}_${className}_Term 3'
        ];
      }
      
      // Sort terms by year (descending), then class, then term
      final sortedTerms = allTerms.toList();
      sortedTerms.sort((a, b) {
        final aMatch = RegExp(r'^(\d{4})_([^_]+)_(Term\s*\d+|term\s*\d+)', caseSensitive: false).firstMatch(a);
        final bMatch = RegExp(r'^(\d{4})_([^_]+)_(Term\s*\d+|term\s*\d+)', caseSensitive: false).firstMatch(b);
        
        if (aMatch != null && bMatch != null) {
          final aYear = int.parse(aMatch.group(1)!);
          final bYear = int.parse(bMatch.group(1)!);
          
          if (aYear != bYear) {
            return bYear.compareTo(aYear); // Newest year first
          }
          
          final aClass = aMatch.group(2)!;
          final bClass = bMatch.group(2)!;
          if (aClass != bClass) {
            return bClass.compareTo(aClass);
          }
          
          final aTermNum = RegExp(r'\d+').firstMatch(aMatch.group(3)!);
          final bTermNum = RegExp(r'\d+').firstMatch(bMatch.group(3)!);
          if (aTermNum != null && bTermNum != null) {
            return int.parse(bTermNum.group(0)!).compareTo(int.parse(aTermNum.group(0)!));
          }
        }
        return b.compareTo(a);
      });
      
      return sortedTerms;
    } catch (e) {
      print('Error getting class terms: $e');
      final currentYear = DateTime.now().year.toString();
      return [
        '${currentYear}_${className}_Term 1',
        '${currentYear}_${className}_Term 2',
        '${currentYear}_${className}_Term 3'
      ];
    }
  }

  Future<void> updateOrAddMarks(String schoolID, String studentID,
      String subject, String examType, String obtainedMarks, {String? term, String? className, String? year}) async {
    try {
      final db = await _dbHelper.database;
      
      // Get current resultMap and student info
      final result = await db.query(
        'Students',
        where: 'studentId = ? AND schoolId = ?',
        whereArgs: [studentID, schoolID],
      );

      if (result.isEmpty) {
        print('Student document does not exist.');
        return;
      }

      String termKey;
      
      // Check if term is already in year_class_term format (e.g., "2024_Class 6_Term 1")
      if (term != null && term.isNotEmpty && RegExp(r'^\d{4}_[^_]+_(Term\s*\d+|term\s*\d+)', caseSensitive: false).hasMatch(term)) {
        // Term is already in the correct format, use it directly
        termKey = term;
      } else {
        // Construct the term key from components
        final currentYear = year ?? DateTime.now().year.toString();
        final currentClass = className ?? (result.first['classSection'] as String? ?? '');
        final termNumber = term ?? 'Term 1';
        
        // Create year-based term key: "YYYY_ClassName_TermN"
        termKey = '${currentYear}_${currentClass}_$termNumber';
      }
      
      final resultMapJson = result.first['resultMap'] as String?;
      
      Map<String, dynamic> resultMap;
      
      // Try to parse as year-term-based structure
      try {
        if (resultMapJson != null && resultMapJson.isNotEmpty) {
          final parsed = jsonDecode(resultMapJson);
          if (parsed is Map) {
            // Check if it's already year-term-based (has keys like "2024_Class 6_Term 1")
            final firstKey = parsed.keys.first.toString();
            if (firstKey.contains('_') && (firstKey.contains('Term') || RegExp(r'\d{4}_').hasMatch(firstKey))) {
              resultMap = Map<String, dynamic>.from(parsed);
            } else {
              // Convert old structure to year-term-based
              // Assume current year and class for migration
              resultMap = {
                termKey: parsed,
              };
            }
          } else {
            resultMap = {termKey: {}};
          }
        } else {
          resultMap = {termKey: {}};
        }
      } catch (e) {
        // If parsing fails, create new year-term-based structure
        resultMap = {termKey: {}};
      }
      
      // Ensure term key exists
      if (!resultMap.containsKey(termKey)) {
        resultMap[termKey] = {};
      }
      
      // Get term data
      Map<String, dynamic> termData = Map<String, dynamic>.from(resultMap[termKey] as Map);
      
      // Ensure subject exists
      if (!termData.containsKey(subject)) {
        termData[subject] = {};
      }
      
      // Get subject data
      Map<String, dynamic> subjectData = Map<String, dynamic>.from(termData[subject] as Map);
      subjectData[examType] = obtainedMarks;
      termData[subject] = subjectData;
      resultMap[termKey] = termData;

      // Also update in Marks table
      await db.insert(
        'Marks',
        {
          'schoolId': schoolID,
          'studentId': studentID,
          'subject': subject,
          'examType': examType,
          'marks': obtainedMarks,
          'term': termKey, // Store full year_class_term key
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Update resultMap in Students table
      await db.update(
        'Students',
        {'resultMap': jsonEncode(resultMap)},
        where: 'studentId = ? AND schoolId = ?',
        whereArgs: [studentID, schoolID],
      );

      print('Marks updated successfully for $termKey.');
    } catch (e) {
      print('Error updating or adding marks: $e');
    }
  }

  Future<List<String>> fetchExamStructure(String schoolID, String className) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.query(
        'ExamStructure',
        where: 'schoolId = ? AND className = ?',
        whereArgs: [schoolID, className],
      );

      return result.map((row) => row['examType'] as String).toList();
    } catch (e) {
      print('Error fetching exam types: $e');
      return [];
    }
  }

  static Future<List<Student>> getAllStudents(String schoolId) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      final result = await db.query(
        'Students',
        where: 'schoolId = ?',
        whereArgs: [schoolId],
      );

      return result.map((row) {
        return Student(
          name: row['name'] as String,
          gender: row['gender'] as String,
          bFormChallanId: row['bFormChallanId'] as String,
          fatherName: row['fatherName'] as String,
          fatherPhoneNo: row['fatherPhoneNo'] as String,
          fatherCNIC: row['fatherCNIC'] as String,
          studentRollNo: row['studentRollNo'] as String,
          studentID: row['studentId'] as String,
          classSection: row['classSection'] as String,
          feeStatus: row['feeStatus'] as String,
          feeStartDate: row['feeStartDate'] as String? ?? '',
          feeEndDate: row['feeEndDate'] as String? ?? '',
          resultMap: Database_Service()._jsonToNestedMap(row['resultMap'] as String?),
          attendance: Database_Service()._jsonToNestedMap(row['attendance'] as String?),
        );
      }).toList();
    } catch (e) {
      print('Error getting students: $e');
      return [];
    }
  }

  static Future<List<Student>> getStudentsOfASpecificClass(
      String school, String classSection) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      final result = await db.query(
        'Students',
        where: 'schoolId = ? AND classSection = ?',
        whereArgs: [school, classSection],
      );

      return result.map((row) {
        return Student(
          name: row['name'] as String,
          gender: row['gender'] as String,
          bFormChallanId: row['bFormChallanId'] as String,
          fatherName: row['fatherName'] as String,
          fatherPhoneNo: row['fatherPhoneNo'] as String,
          fatherCNIC: row['fatherCNIC'] as String,
          studentRollNo: row['studentRollNo'] as String,
          studentID: row['studentId'] as String,
          classSection: row['classSection'] as String,
          feeStatus: row['feeStatus'] as String,
          feeStartDate: row['feeStartDate'] as String? ?? '',
          feeEndDate: row['feeEndDate'] as String? ?? '',
          resultMap: Database_Service()._jsonToNestedMap(row['resultMap'] as String?),
          attendance: Database_Service()._jsonToNestedMap(row['attendance'] as String?),
        );
      }).toList();
    } catch (e) {
      print('Error getting students: $e');
      return [];
    }
  }

  static Future<void> updateFeeStatus(String schoolId, String studentID,
      String feeStatus, String startDate, String endDate) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    await db.update(
      'Students',
      {
        'feeStatus': feeStatus,
        'feeStartDate': startDate,
        'feeEndDate': endDate,
      },
      where: 'studentId = ? AND schoolId = ?',
      whereArgs: [studentID, schoolId],
    );
  }

  static Future<List<String>> fetchClasses(String schoolId) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      final result = await db.query(
        'Classes',
        where: 'schoolId = ?',
        whereArgs: [schoolId],
        distinct: true,
        columns: ['className'],
      );

      List<String> classes = result.map((row) => row['className'] as String).toList();
      classes.sort();
      return classes;
    } catch (e) {
      print('Error fetching classes: $e');
      return [];
    }
  }

  static Future<List<String>> fetchSubjects(String schoolId, String className) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      final result = await db.query(
        'Subjects',
        where: 'schoolId = ? AND className = ?',
        whereArgs: [schoolId, className],
        columns: ['subjectName'],
      );

      return result.map((row) => row['subjectName'] as String).toList();
    } catch (e) {
      print('Error fetching subjects: $e');
      return [];
    }
  }

  static Future<Map<String, List<String>>> fetchClassesAndSubjects(String schoolId) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.database; // Initialize database connection
    try {
      final classes = await fetchClasses(schoolId);
      Map<String, List<String>> result = {};

      for (String className in classes) {
        result[className] = await fetchSubjects(schoolId, className);
      }

      return result;
    } catch (e) {
      print('Error fetching classes and subjects: $e');
      return {};
    }
  }

  static Future<void> saveTeacher(
    String schoolID,
    String empID,
    String name,
    String gender,
    String email,
    String phoneNo,
    String cnic,
    String fatherName,
    List<String> classes,
    Map<String, List<String>> subjects,
    String classTeacher,
    String password,
  ) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      await db.insert('Teachers', {
        'employeeId': empID,
        'schoolId': schoolID,
        'name': name,
        'gender': gender,
        'email': email,
        'password': password,
        'cnic': cnic,
        'phoneNo': phoneNo,
        'fatherName': fatherName,
        'classes': Database_Service()._listToJson(classes),
        'subjects': Database_Service()._mapToJson(subjects.map((k, v) => MapEntry(k, Database_Service()._listToJson(v)))),
        'classTeacher': classTeacher,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      Get.back(result: 'updated');
      print('Teacher saved successfully');
    } catch (e) {
      print('Error saving teacher: $e');
    }
  }

  static Future<List<Teacher>> fetchTeachers(String schoolID) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      final result = await db.query(
        'Teachers',
        where: 'schoolId = ?',
        whereArgs: [schoolID],
      );

      return result.map((row) {
        Map<String, dynamic> subjectsJson = Database_Service()._jsonToMap(row['subjects'] as String?);
        Map<String, List<String>> subjects = {};
        subjectsJson.forEach((key, value) {
          if (value is String) {
            subjects[key] = Database_Service()._jsonToList(value);
          }
        });

        return Teacher(
          empID: row['employeeId'] as String,
          name: row['name'] as String,
          gender: row['gender'] as String,
          email: row['email'] as String,
          cnic: row['cnic'] as String,
          phoneNo: row['phoneNo'] as String,
          fatherName: row['fatherName'] as String,
          classes: Database_Service()._jsonToList(row['classes'] as String?),
          subjects: subjects,
          classTeacher: row['classTeacher'] as String,
        );
      }).toList();
    } catch (e) {
      print('Error fetching teachers: $e');
      return [];
    }
  }

  static Future<void> deleteTeacher(String schoolID, String empID) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    await db.delete(
      'Teachers',
      where: 'employeeId = ? AND schoolId = ?',
      whereArgs: [empID, schoolID],
    );
    print('Teacher with EmployeeID $empID deleted successfully');
  }

  static Future<List<Teacher>> searchTeachersByName(String schoolID, String searchText) async {
    final teachers = await fetchTeachers(schoolID);
    return teachers.where((teacher) => teacher.name.toLowerCase().contains(searchText.toLowerCase())).toList();
  }

  static Future<List<Teacher>> searchTeachersByEmployeeID(String schoolID, String employeeID) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      List<Map<String, dynamic>> result;
      if (employeeID.isNotEmpty) {
        result = await db.query(
          'Teachers',
          where: 'employeeId = ? AND schoolId = ?',
          whereArgs: [employeeID, schoolID],
        );
      } else {
        result = await db.query('Teachers', where: 'schoolId = ?', whereArgs: [schoolID]);
      }

      return result.map((row) {
        Map<String, dynamic> subjectsJson = Database_Service()._jsonToMap(row['subjects'] as String?);
        Map<String, List<String>> subjects = {};
        subjectsJson.forEach((key, value) {
          if (value is String) {
            subjects[key] = Database_Service()._jsonToList(value);
          }
        });

        return Teacher(
          empID: row['employeeId'] as String,
          name: row['name'] as String,
          gender: row['gender'] as String,
          email: row['email'] as String,
          cnic: row['cnic'] as String,
          phoneNo: row['phoneNo'] as String,
          fatherName: row['fatherName'] as String,
          classes: Database_Service()._jsonToList(row['classes'] as String?),
          subjects: subjects,
          classTeacher: row['classTeacher'] as String,
        );
      }).toList();
    } catch (e) {
      print('Error searching teachers: $e');
      return [];
    }
  }

  static Future<void> deleteClassByName(String schoolName, String className) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      // Get schoolId from schoolName
      final schoolResult = await db.query(
        'Schools',
        where: 'schoolName = ?',
        whereArgs: [schoolName],
      );

      if (schoolResult.isEmpty) {
        print('School not found with name: $schoolName');
        return;
      }

      String schoolId = schoolResult.first['schoolId'] as String;

      // Delete class
      await db.delete(
        'Classes',
        where: 'schoolId = ? AND className = ?',
        whereArgs: [schoolId, className],
      );

      // Delete related subjects
      await db.delete(
        'Subjects',
        where: 'schoolId = ? AND className = ?',
        whereArgs: [schoolId, className],
      );

      // Delete related exam structure
      await db.delete(
        'ExamStructure',
        where: 'schoolId = ? AND className = ?',
        whereArgs: [schoolId, className],
      );

      print('Successfully deleted class: $className');
    } catch (e) {
      print("Error deleting class: $e");
    }
  }

  static Future<String> fetchCounts(String schoolName, String collectionName) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      // Use case-insensitive matching for school name
      final schoolResult = await db.rawQuery(
        'SELECT * FROM Schools WHERE LOWER(TRIM(schoolName)) = LOWER(TRIM(?))',
        [schoolName],
      );

      if (schoolResult.isEmpty) {
        print('No school found with name: $schoolName');
        return "0";
      }

      String schoolId = schoolResult.first['schoolId'] as String;

      int count = 0;
      if (collectionName == 'Teachers') {
        final result = await db.rawQuery('SELECT COUNT(*) as count FROM Teachers WHERE schoolId = ?', [schoolId]);
        count = Sqflite.firstIntValue(result) ?? 0;
      } else if (collectionName == 'Students') {
        final result = await db.rawQuery('SELECT COUNT(*) as count FROM Students WHERE schoolId = ?', [schoolId]);
        count = Sqflite.firstIntValue(result) ?? 0;
      }

      print('Count for $collectionName in school $schoolName (ID: $schoolId): $count');
      return count.toString();
    } catch (e) {
      print('Error fetching count: $e');
      return "0";
    }
  }

  // Overloaded method to fetch counts directly by schoolId (more reliable)
  static Future<String> fetchCountsBySchoolId(String schoolId, String collectionName) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      int count = 0;
      if (collectionName == 'Teachers') {
        final result = await db.rawQuery('SELECT COUNT(*) as count FROM Teachers WHERE schoolId = ?', [schoolId]);
        count = Sqflite.firstIntValue(result) ?? 0;
      } else if (collectionName == 'Students') {
        final result = await db.rawQuery('SELECT COUNT(*) as count FROM Students WHERE schoolId = ?', [schoolId]);
        count = Sqflite.firstIntValue(result) ?? 0;
      }

      print('Count for $collectionName in schoolId $schoolId: $count');
      return count.toString();
    } catch (e) {
      print('Error fetching count by schoolId: $e');
      return "0";
    }
  }

  static Future<void> updateTeacher(
    String schoolID,
    String empID,
    String name,
    String gender,
    String email,
    String phoneNo,
    String cnic,
    String fatherName,
    List<String> classes,
    Map<String, List<String>> subjects,
    String classTeacher,
  ) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      await db.update(
        'Teachers',
        {
          'name': name,
          'gender': gender,
          'email': email,
          'phoneNo': phoneNo,
          'cnic': cnic,
          'fatherName': fatherName,
          'classes': Database_Service()._listToJson(classes),
          'subjects': Database_Service()._mapToJson(subjects.map((k, v) => MapEntry(k, Database_Service()._listToJson(v)))),
          'classTeacher': classTeacher,
        },
        where: 'employeeId = ? AND schoolId = ?',
        whereArgs: [empID, schoolID],
      );

      print('Teacher updated successfully');
    } catch (e) {
      print('Error updating teacher: $e');
    }
  }

  static Future<List<Student>> searchStudentsByRollNo(
      String school, String classSection, String rollNo) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      final result = await db.query(
        'Students',
        where: 'schoolId = ? AND classSection = ? AND studentRollNo = ?',
        whereArgs: [school, classSection, rollNo],
      );

      return result.map((row) {
        return Student(
          name: row['name'] as String,
          gender: row['gender'] as String,
          bFormChallanId: row['bFormChallanId'] as String,
          fatherName: row['fatherName'] as String,
          fatherPhoneNo: row['fatherPhoneNo'] as String,
          fatherCNIC: row['fatherCNIC'] as String,
          studentRollNo: row['studentRollNo'] as String,
          studentID: row['studentId'] as String,
          classSection: row['classSection'] as String,
          feeStatus: row['feeStatus'] as String,
          feeStartDate: row['feeStartDate'] as String? ?? '',
          feeEndDate: row['feeEndDate'] as String? ?? '',
          resultMap: Database_Service()._jsonToNestedMap(row['resultMap'] as String?),
          attendance: Database_Service()._jsonToNestedMap(row['attendance'] as String?),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<Student>> searchStudentsByName(
      String school, String classSection, String studentName) async {
    final students = await getStudentsOfASpecificClass(school, classSection);
    return students.where((student) => student.name.toLowerCase().contains(studentName.toLowerCase())).toList();
  }

  static Future<Student?> getStudentByID(String school, String studentID) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      final result = await db.query(
        'Students',
        where: 'studentId = ? AND schoolId = ?',
        whereArgs: [studentID, school],
      );

      if (result.isNotEmpty) {
        final row = result.first;
        return Student(
          name: row['name'] as String,
          gender: row['gender'] as String,
          bFormChallanId: row['bFormChallanId'] as String,
          fatherName: row['fatherName'] as String,
          fatherPhoneNo: row['fatherPhoneNo'] as String,
          fatherCNIC: row['fatherCNIC'] as String,
          studentRollNo: row['studentRollNo'] as String,
          studentID: row['studentId'] as String,
          classSection: row['classSection'] as String,
          feeStatus: row['feeStatus'] as String,
          feeStartDate: row['feeStartDate'] as String? ?? '',
          feeEndDate: row['feeEndDate'] as String? ?? '',
          resultMap: Database_Service()._jsonToNestedMap(row['resultMap'] as String?),
          attendance: Database_Service()._jsonToNestedMap(row['attendance'] as String?),
        );
      }
      return null;
    } catch (e) {
      print('Error searching students by ID $studentID: $e');
      return null;
    }
  }

  static Future<void> updateStudent(String school, String studentID, Map<String, dynamic> data) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      // Handle nested maps if present
      if (data.containsKey('ResultMap') || data.containsKey('resultMap')) {
        data['resultMap'] = Database_Service()._nestedMapToJson(data['ResultMap'] ?? data['resultMap']);
        data.remove('ResultMap');
      }
      if (data.containsKey('attendance')) {
        data['attendance'] = Database_Service()._nestedMapToJson(data['attendance']);
      }

      // Map field names to database column names
      Map<String, dynamic> dbData = {};
      final fieldMap = {
        'Name': 'name',
        'Gender': 'gender',
        'BForm_challanId': 'bFormChallanId',
        'FatherName': 'fatherName',
        'FatherPhoneNo': 'fatherPhoneNo',
        'FatherCNIC': 'fatherCNIC',
        'StudentRollNo': 'studentRollNo',
        'ClassSection': 'classSection',
        'FeeStatus': 'feeStatus',
        'FeeStartDate': 'feeStartDate',
        'FeeEndDate': 'feeEndDate',
      };

      data.forEach((key, value) {
        if (fieldMap.containsKey(key)) {
          dbData[fieldMap[key]!] = value;
        } else if (!['ResultMap', 'resultMap', 'StudentID'].contains(key)) {
          dbData[key.toLowerCase()] = value;
        }
      });

      await db.update(
        'Students',
        dbData,
        where: 'studentId = ? AND schoolId = ?',
        whereArgs: [studentID, school],
      );
      print('Student updated successfully');
    } catch (e) {
      print('Error updating student: $e');
    }
  }

  static Future<void> deleteStudent(String schoolID, String studentID) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    await db.delete(
      'Students',
      where: 'studentId = ? AND schoolId = ?',
      whereArgs: [studentID, schoolID],
    );
    print('Student deleted successfully');
  }

  static Future<void> saveSchool(String schoolName, String schoolId, String adminEmail, String adminPassword, {String? adminName, String? adminId}) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      Map<String, dynamic> schoolData = {
        'schoolId': schoolId,
        'schoolName': schoolName,
        'adminEmail': adminEmail,
        'adminPassword': adminPassword,
      };
      
      // Add adminName and adminId if provided
      if (adminName != null) {
        schoolData['adminName'] = adminName;
      }
      if (adminId != null) {
        schoolData['adminId'] = adminId;
      }
      
      await db.insert(
        'Schools',
        schoolData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('School saved successfully: $schoolName');
    } catch (e) {
      print('Error saving school: $e');
      rethrow;
    }
  }

  static Future<List<School>> getAllSchools() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      
      // Get all schools grouped by schoolId, keeping only the first occurrence
      final result = await db.query(
        'Schools',
        groupBy: 'schoolId',
      );
      
      // Remove any additional duplicates (in case groupBy doesn't work perfectly)
      Map<String, School> uniqueSchools = {};
      for (var row in result) {
        String schoolId = row['schoolId'] as String;
        if (!uniqueSchools.containsKey(schoolId)) {
          uniqueSchools[schoolId] = School(
          name: row['schoolName'] as String,
            schoolId: schoolId,
          adminEmail: row['adminEmail'] as String,
        );
        }
      }
      
      return uniqueSchools.values.toList();
    } catch (e) {
      print('Error getting schools: $e');
      // Return empty list on error - allows app to continue
      return [];
    }
  }

  static Future<void> removeDuplicateSchools() async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      
      // Get all schools ordered by rowid (SQLite automatically includes rowid)
      final allSchools = await db.rawQuery('SELECT *, rowid FROM Schools ORDER BY rowid');
      
      // Track seen schoolIds - keep track of last occurrence rowid, delete earlier ones
      Map<String, int> lastOccurrence = {};
      List<int> rowsToDelete = [];
      
      for (var school in allSchools) {
        String schoolId = school['schoolId'] as String;
        int rowId = school['rowid'] as int;
        
        if (lastOccurrence.containsKey(schoolId)) {
          // This is a duplicate - delete the previous occurrence, keep this one
          int previousRowId = lastOccurrence[schoolId]!;
          rowsToDelete.add(previousRowId);
          lastOccurrence[schoolId] = rowId; // Update to keep the later one
        } else {
          // First time seeing this schoolId
          lastOccurrence[schoolId] = rowId;
        }
      }
      
      // Delete duplicate rows (keeping the last occurrence of each schoolId)
      for (int rowId in rowsToDelete) {
        await db.delete('Schools', where: 'rowid = ?', whereArgs: [rowId]);
        print('Deleted duplicate school with rowid: $rowId (kept the later one)');
      }
      
      if (rowsToDelete.isNotEmpty) {
        print('Removed ${rowsToDelete.length} duplicate school(s) - kept the last occurrence');
      } else {
        print('No duplicate schools found');
      }
    } catch (e) {
      print('Error removing duplicate schools: $e');
    }
  }

  static Future<void> addClass(
      List<String>? classes,
      List<String>? subjects,
      List<String> examSystem,
      Map<String, String> weightage,
      String schoolID) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      await db.transaction((txn) async {
        for (String className in classes ?? []) {
          // Insert class
          await txn.insert('Classes', {
            'schoolId': schoolID,
            'className': className,
            'timetable': 0,
          }, conflictAlgorithm: ConflictAlgorithm.replace);

          // Insert subjects
          for (String subject in subjects ?? []) {
            await txn.insert('Subjects', {
              'schoolId': schoolID,
              'className': className,
              'subjectName': subject,
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          }

          // Insert exam structure
          for (String examType in examSystem) {
            await txn.insert('ExamStructure', {
              'schoolId': schoolID,
              'className': className,
              'examType': examType,
              'weightage': weightage[examType] != null ? double.tryParse(weightage[examType]!) : null,
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      });

      print('Classes added successfully');
    } catch (e) {
      print('Error adding classes: $e');
    }
  }

  static Future<List<String>> fetchAllClasses(String schoolID) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      final result = await db.query(
        'Classes',
        where: 'schoolId = ?',
        whereArgs: [schoolID],
        distinct: true,
        columns: ['className'],
      );

      List<String> classNames = result.map((row) => row['className'] as String).toList();
      classNames.sort();
      return classNames;
    } catch (e) {
      print('Error fetching classes: $e');
      return [];
    }
  }

  static Future<List<String>> fetchAllClassesbyTimetable(String schoolID, bool timetable) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      final result = await db.query(
        'Classes',
        where: 'schoolId = ? AND timetable = ?',
        whereArgs: [schoolID, timetable ? 1 : 0],
        distinct: true,
        columns: ['className'],
      );

      List<String> classNames = result.map((row) => row['className'] as String).toList();
      classNames.sort();
      return classNames;
    } catch (e) {
      print('Error fetching classes: $e');
      return [];
    }
  }

  static Future<void> addTimetablebyClass(String schoolId, String className,
      String format, Map<String, Map<String, String>> timetable) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      await db.transaction((txn) async {
        // Delete existing timetable for this class
        await txn.delete('Timetable', where: 'schoolId = ? AND className = ?', whereArgs: [schoolId, className]);

        // Insert new timetable entries
        timetable.forEach((day, timeSlots) {
          timeSlots.forEach((timeSlot, subject) {
            txn.insert('Timetable', {
              'schoolId': schoolId,
              'className': className,
              'format': format,
              'day': day,
              'timeSlot': timeSlot,
              'subject': subject,
            });
          });
        });

        // Update class timetable flag
        await txn.update('Classes', {'timetable': 1},
            where: 'schoolId = ? AND className = ?', whereArgs: [schoolId, className]);
      });

      print('Timetable added successfully!');
    } catch (e) {
      print('Error adding timetable: $e');
      throw e;
    }
  }

  static Future<void> deleteTimetableByClass(String schoolId, String className) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      await db.transaction((txn) async {
        await txn.delete('Timetable', where: 'schoolId = ? AND className = ?', whereArgs: [schoolId, className]);
        await txn.update('Classes', {'timetable': 0},
            where: 'schoolId = ? AND className = ?', whereArgs: [schoolId, className]);
      });
    } catch (e) {
      print('Error deleting timetable: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchTimetable(String schoolId, String className, String day) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      final result = await db.query(
        'Timetable',
        where: 'schoolId = ? AND className = ? AND day = ?',
        whereArgs: [schoolId, className, day],
      );

      Map<String, String> timetable = {};
      for (var row in result) {
        timetable[row['timeSlot'] as String] = row['subject'] as String;
      }

      return timetable;
    } catch (e) {
      print("Error fetching timetable: $e");
      return {};
    }
  }

  static Future<void> createAnnouncement(
    String schoolID,
    String studentID,
    String announcementDescription,
    String announcementBy,
    bool adminAnnouncement, {
    DateTime? deadline,
    String? timeline,
  }) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      await db.insert('Announcements', {
        'schoolId': schoolID,
        'studentId': studentID.isEmpty ? null : studentID,
        'teacherName': announcementBy,
        'announcementDescription': announcementDescription,
        'timestamp': DateTime.now().toIso8601String(),
        'isGeneral': adminAnnouncement ? 1 : 0,
        'deadline': deadline?.toIso8601String(),
        'timeline': timeline,
      });

      print('Announcement saved successfully');
    } catch (e) {
      print('Error saving announcement: $e');
    }
  }

  static Future<void> updateAttendance(String schoolId,
      Map<String, String> studentStatusMap, String day, String subject) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      await db.transaction((txn) async {
        // Update attendance table
        for (var entry in studentStatusMap.entries) {
          await txn.insert(
            'Attendance',
            {
              'schoolId': schoolId,
              'studentId': entry.key,
              'subject': subject,
              'date': day,
              'status': entry.value,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // Update attendance in Students table
        for (var entry in studentStatusMap.entries) {
          final studentResult = await txn.query(
            'Students',
            where: 'studentId = ? AND schoolId = ?',
            whereArgs: [entry.key, schoolId],
          );

          if (studentResult.isNotEmpty) {
            Map<String, Map<String, String>> attendance = Database_Service()._jsonToNestedMap(studentResult.first['attendance'] as String?);
            if (!attendance.containsKey(subject)) {
              attendance[subject] = {};
            }
            attendance[subject]![day] = entry.value;

            await txn.update(
              'Students',
              {'attendance': Database_Service()._nestedMapToJson(attendance)},
              where: 'studentId = ? AND schoolId = ?',
              whereArgs: [entry.key, schoolId],
            );
          }
        }
      });

      Get.back();
      Get.snackbar('Attendance submitted', 'Date: $day, Subject: $subject');
      print('Attendance updated successfully for all students');
    } catch (e) {
      print('Error updating attendance in bulk: $e');
    }
  }

  static Future<List<Announcement>?> fetchAdminAnnouncements(String schoolID) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      DateTime sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      
      final result = await db.query(
        'Announcements',
        where: 'schoolId = ? AND isGeneral = ? AND timestamp >= ?',
        whereArgs: [schoolID, 1, sevenDaysAgo.toIso8601String()],
        orderBy: 'timestamp DESC',
      );

      List<Announcement> announcements = result.map((row) {
        return Announcement(
          announcementBy: 'Admin',
          announcementDate: row['timestamp'] != null
              ? DateTime.tryParse(row['timestamp'] as String)
              : null,
          announcementDescription: row['announcementDescription'] as String?,
          studentID: row['studentId'] as String?,
          adminAnnouncement: (row['isGeneral'] as int) == 1,
          deadline: row['deadline'] != null
              ? DateTime.tryParse(row['deadline'] as String)
              : null,
          timeline: row['timeline'] as String?,
        );
      }).toList();

      return announcements;
    } catch (e) {
      print('Error fetching announcements: $e');
      return null;
    }
  }

  static Future<List<Announcement>?> fetchStudentAnnouncements(String schoolID, String studentID) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      DateTime sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      
      final result = await db.query(
        'Announcements',
        where: 'schoolId = ? AND studentId = ? AND timestamp >= ?',
        whereArgs: [schoolID, studentID, sevenDaysAgo.toIso8601String()],
        orderBy: 'timestamp DESC',
      );

      List<Announcement> announcements = result.map((row) {
        final teacherName = row['teacherName'] as String?;
        final isGeneral = (row['isGeneral'] as int) == 1;
        
        return Announcement(
          announcementBy: teacherName != null && teacherName.isNotEmpty
              ? teacherName
              : (isGeneral ? 'Admin' : 'Teacher'),
          announcementDate: row['timestamp'] != null
              ? DateTime.tryParse(row['timestamp'] as String)
              : null,
          announcementDescription: row['announcementDescription'] as String?,
          studentID: row['studentId'] as String?,
          adminAnnouncement: isGeneral,
          deadline: row['deadline'] != null
              ? DateTime.tryParse(row['deadline'] as String)
              : null,
          timeline: row['timeline'] as String?,
        );
      }).toList();

      return announcements;
    } catch (e) {
      print('Error fetching announcements: $e');
      return null;
    }
  }

  Future<List<String>> fetchUniqueSubjects(String schoolId, String employeeId, String className) async {
    final db = await _dbHelper.database;
    try {
      final teacherResult = await db.query(
        'Teachers',
        where: 'schoolId = ? AND employeeId = ?',
        whereArgs: [schoolId, employeeId],
      );

      if (teacherResult.isEmpty) {
        return [];
      }

      Map<String, dynamic> subjectsJson = _jsonToMap(teacherResult.first['subjects'] as String?);
      if (subjectsJson.containsKey(className)) {
        List<String> subjects = _jsonToList(subjectsJson[className]);
        subjects.sort();
        return subjects;
      }

      return [];
    } catch (e) {
      print('Error fetching subjects: $e');
      return [];
    }
  }

  Future<Map<String, String>> fetchWeightage(String schoolId, String classSection) async {
    final db = await _dbHelper.database;
    try {
      final result = await db.query(
        'ExamStructure',
        where: 'schoolId = ? AND className = ?',
        whereArgs: [schoolId, classSection],
      );

      Map<String, String> weightage = {};
      for (var row in result) {
        if (row['weightage'] != null) {
          weightage[row['examType'] as String] = row['weightage'].toString();
        }
      }

      return weightage;
    } catch (e) {
      print('Error fetching weightage: $e');
      return {};
    }
  }

  // Payment methods
  static Future<Map<String, double>> getStudentPaymentInfo(String schoolId, String studentId) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      final result = await db.query(
        'Students',
        columns: ['paidAmount', 'balanceAmount', 'feePerTerm'],
        where: 'studentId = ? AND schoolId = ?',
        whereArgs: [studentId, schoolId],
      );

      if (result.isEmpty) {
        return {'paidAmount': 0.0, 'balanceAmount': 40000.0, 'feePerTerm': 40000.0};
      }

      final row = result.first;
      return {
        'paidAmount': (row['paidAmount'] as num?)?.toDouble() ?? 0.0,
        'balanceAmount': (row['balanceAmount'] as num?)?.toDouble() ?? 40000.0,
        'feePerTerm': (row['feePerTerm'] as num?)?.toDouble() ?? 40000.0,
      };
    } catch (e) {
      print('Error getting payment info: $e');
      return {'paidAmount': 0.0, 'balanceAmount': 40000.0, 'feePerTerm': 40000.0};
    }
  }

  static Future<List<Payment>> getPaymentHistory(String schoolId, String studentId) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      final result = await db.query(
        'Payments',
        where: 'studentId = ? AND schoolId = ?',
        whereArgs: [studentId, schoolId],
        orderBy: 'paymentDate DESC',
      );

      return result.map((row) {
        return Payment(
          id: row['id'] as int?,
          studentId: row['studentId'] as String,
          schoolId: row['schoolId'] as String,
          amount: (row['amount'] as num).toDouble(),
          paymentMethod: row['paymentMethod'] as String,
          transactionId: row['transactionId'] as String?,
          mpesaReceiptNumber: row['mpesaReceiptNumber'] as String?,
          paymentDate: row['paymentDate'] as String,
          term: row['term'] as String?,
          status: row['status'] as String,
        );
      }).toList();
    } catch (e) {
      print('Error getting payment history: $e');
      return [];
    }
  }

  static Future<void> processPayment({
    required String schoolId,
    required String studentId,
    required double amount,
    required String paymentMethod,
    String? mpesaReceiptNumber,
    String? transactionId,
    String? term,
  }) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    
    try {
      await db.transaction((txn) async {
        // Insert payment record
        await txn.insert('Payments', {
          'studentId': studentId,
          'schoolId': schoolId,
          'amount': amount,
          'paymentMethod': paymentMethod,
          'mpesaReceiptNumber': mpesaReceiptNumber,
          'transactionId': transactionId,
          'paymentDate': DateTime.now().toIso8601String(),
          'term': term ?? 'Term 1',
          'status': 'completed',
        });

        // Update student payment info
        final currentInfo = await txn.query(
          'Students',
          columns: ['paidAmount', 'balanceAmount', 'feePerTerm'],
          where: 'studentId = ? AND schoolId = ?',
          whereArgs: [studentId, schoolId],
        );

        if (currentInfo.isNotEmpty) {
          final row = currentInfo.first;
          final currentPaid = (row['paidAmount'] as num?)?.toDouble() ?? 0.0;
          final currentBalance = (row['balanceAmount'] as num?)?.toDouble() ?? 40000.0;
          
          final newPaid = currentPaid + amount;
          final newBalance = (currentBalance - amount).clamp(0.0, double.infinity);

          await txn.update(
            'Students',
            {
              'paidAmount': newPaid,
              'balanceAmount': newBalance,
              'feeStatus': newBalance <= 0 ? 'paid' : 'pending',
            },
            where: 'studentId = ? AND schoolId = ?',
            whereArgs: [studentId, schoolId],
          );
        }
      });

      print('Payment processed successfully');
    } catch (e) {
      print('Error processing payment: $e');
      rethrow;
    }
  }

  // Chat Methods

  // Get or create a chat between teacher and parent for a specific student
  static Future<String> getOrCreateChat(
    String schoolId,
    String teacherId,
    String teacherName,
    String parentId,
    String parentName,
    String studentId,
    String studentName,
  ) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      // Check if chat already exists
      final existingChat = await db.query(
        'Chats',
        where: 'schoolId = ? AND teacherId = ? AND parentId = ? AND studentId = ?',
        whereArgs: [schoolId, teacherId, parentId, studentId],
      );

      if (existingChat.isNotEmpty) {
        return existingChat.first['chatId'] as String;
      }

      // Create new chat
      final chatId = 'chat_${schoolId}_${teacherId}_${parentId}_${studentId}_${DateTime.now().millisecondsSinceEpoch}';
      await db.insert('Chats', {
        'chatId': chatId,
        'schoolId': schoolId,
        'teacherId': teacherId,
        'teacherName': teacherName,
        'parentId': parentId,
        'parentName': parentName,
        'studentId': studentId,
        'studentName': studentName,
        'lastMessage': null,
        'lastMessageTime': null,
        'unreadCount': 0,
      });

      return chatId;
    } catch (e) {
      print('Error getting or creating chat: $e');
      rethrow;
    }
  }

  // Send a message
  static Future<void> sendMessage(
    String chatId,
    String senderId,
    String senderType,
    String senderName,
    String message,
  ) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      final messageId = 'msg_${DateTime.now().millisecondsSinceEpoch}_${senderId}';
      final timestamp = DateTime.now().toIso8601String();

      // Insert message
      await db.insert('Messages', {
        'messageId': messageId,
        'chatId': chatId,
        'senderId': senderId,
        'senderType': senderType,
        'senderName': senderName,
        'message': message,
        'timestamp': timestamp,
        'isRead': 0,
      });

      // Update chat last message
      await db.update(
        'Chats',
        {
          'lastMessage': message,
          'lastMessageTime': timestamp,
        },
        where: 'chatId = ?',
        whereArgs: [chatId],
      );

      // Update unread count for the other party
      final chat = await db.query('Chats', where: 'chatId = ?', whereArgs: [chatId]);
      if (chat.isNotEmpty) {
        final chatData = chat.first;
        if (senderType == 'teacher') {
          // Parent should see unread count
          await db.rawUpdate(
            'UPDATE Chats SET unreadCount = unreadCount + 1 WHERE chatId = ?',
            [chatId],
          );
        } else {
          // Teacher should see unread count
          await db.rawUpdate(
            'UPDATE Chats SET unreadCount = unreadCount + 1 WHERE chatId = ?',
            [chatId],
          );
        }
      }
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Get messages for a chat
  static Future<List<Message>> getMessages(String chatId) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      final result = await db.query(
        'Messages',
        where: 'chatId = ?',
        whereArgs: [chatId],
        orderBy: 'timestamp ASC',
      );

      return result.map((row) => Message.fromMap(row)).toList();
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }

  // Get chats for a teacher
  static Future<List<Chat>> getTeacherChats(String schoolId, String teacherId) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      final result = await db.query(
        'Chats',
        where: 'schoolId = ? AND teacherId = ?',
        whereArgs: [schoolId, teacherId],
        orderBy: 'lastMessageTime DESC',
      );

      return result.map((row) => Chat.fromMap(row)).toList();
    } catch (e) {
      print('Error getting teacher chats: $e');
      return [];
    }
  }

  // Get chats for a parent (by student ID or admission number)
  static Future<List<Chat>> getParentChats(String schoolId, String studentId) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      // Get student by ID to find by admission number as well
      final student = await db.query(
        'Students',
        where: 'studentId = ? AND schoolId = ?',
        whereArgs: [studentId, schoolId],
      );
      
      if (student.isEmpty) return [];
      
      final studentRollNo = student.first['studentRollNo'] as String;
      
      // Find chats where parentId matches studentRollNo or studentId
      final result = await db.query(
        'Chats',
        where: 'schoolId = ? AND (studentId = ? OR parentId = ? OR parentId = ?)',
        whereArgs: [schoolId, studentId, studentId, studentRollNo],
        orderBy: 'lastMessageTime DESC',
      );

      return result.map((row) => Chat.fromMap(row)).toList();
    } catch (e) {
      print('Error getting parent chats: $e');
      return [];
    }
  }

  // Mark messages as read
  static Future<void> markMessagesAsRead(String chatId, String readerType) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      // Mark all messages in the chat as read
      await db.update(
        'Messages',
        {'isRead': 1},
        where: 'chatId = ? AND senderType != ?',
        whereArgs: [chatId, readerType],
      );

      // Reset unread count for the chat
      await db.update(
        'Chats',
        {'unreadCount': 0},
        where: 'chatId = ?',
        whereArgs: [chatId],
      );
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Get students for a teacher to select for chat
  static Future<List<Student>> getTeacherStudents(String schoolId, String teacherId) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      // Get teacher's classes
      final teacherResult = await db.query(
        'Teachers',
        where: 'employeeId = ? AND schoolId = ?',
        whereArgs: [teacherId, schoolId],
      );

      if (teacherResult.isEmpty) return [];

      final teacherData = teacherResult.first;
      final classesJson = teacherData['classes'] as String?;
      if (classesJson == null || classesJson.isEmpty) return [];

      // Parse JSON string to list
      List<String> classes = [];
      try {
        classes = List<String>.from(jsonDecode(classesJson));
      } catch (e) {
        print('Error parsing classes JSON: $e');
        return [];
      }
      
      if (classes.isEmpty) return [];

      // Get all students in those classes
      final students = <Student>[];
      for (final className in classes) {
        final studentsResult = await db.query(
          'Students',
          where: 'schoolId = ? AND classSection = ?',
          whereArgs: [schoolId, className],
        );

        for (final row in studentsResult) {
          // Parse nested maps
          Map<String, Map<String, String>> parseNestedMap(String? jsonStr) {
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

          students.add(Student(
            name: row['name'] as String,
            gender: row['gender'] as String,
            bFormChallanId: row['bFormChallanId'] as String,
            fatherName: row['fatherName'] as String,
            fatherPhoneNo: row['fatherPhoneNo'] as String,
            fatherCNIC: row['fatherCNIC'] as String,
            studentRollNo: row['studentRollNo'] as String,
            studentID: row['studentId'] as String,
            classSection: row['classSection'] as String,
            feeStatus: row['feeStatus'] as String,
            feeStartDate: row['feeStartDate'] as String? ?? '',
            feeEndDate: row['feeEndDate'] as String? ?? '',
            resultMap: parseNestedMap(row['resultMap'] as String?),
            attendance: parseNestedMap(row['attendance'] as String?),
          ));
        }
      }

      return students;
    } catch (e) {
      print('Error getting teacher students: $e');
      return [];
    }
  }

  // ========== GROUP CHAT METHODS ==========

  // Create a group chat for a class and subject
  static Future<String> createGroupChat(
    String schoolId,
    String teacherId,
    String teacherName,
    String className,
    String subjectName,
  ) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      // Check if group chat already exists
      final existingChat = await db.query(
        'GroupChats',
        where: 'schoolId = ? AND teacherId = ? AND className = ? AND subjectName = ?',
        whereArgs: [schoolId, teacherId, className, subjectName],
      );

      if (existingChat.isNotEmpty) {
        return existingChat.first['chatId'] as String;
      }

      // Create new group chat
      final chatId = 'groupchat_${schoolId}_${teacherId}_${className}_${subjectName}_${DateTime.now().millisecondsSinceEpoch}';
      final groupName = '$className - $subjectName';
      final createdAt = DateTime.now().toIso8601String();

      await db.insert('GroupChats', {
        'chatId': chatId,
        'schoolId': schoolId,
        'teacherId': teacherId,
        'teacherName': teacherName,
        'className': className,
        'subjectName': subjectName,
        'groupName': groupName,
        'createdAt': createdAt,
      });

      // Add teacher as participant
      await db.insert('GroupChatParticipants', {
        'chatId': chatId,
        'participantId': teacherId,
        'participantType': 'teacher',
        'participantName': teacherName,
        'unreadCount': 0,
        'joinedAt': createdAt,
      });

      // Get all students in the class
      final students = await getStudentsOfASpecificClass(schoolId, className);
      
      // Add all students and their parents as participants
      for (final student in students) {
        // Add student
        await db.insert('GroupChatParticipants', {
          'chatId': chatId,
          'participantId': student.studentID,
          'participantType': 'student',
          'participantName': student.name,
          'unreadCount': 0,
          'joinedAt': createdAt,
        });

        // Add parent (using studentRollNo as parent identifier)
        await db.insert('GroupChatParticipants', {
          'chatId': chatId,
          'participantId': student.studentRollNo,
          'participantType': 'parent',
          'participantName': student.fatherName.isNotEmpty ? student.fatherName : 'Parent of ${student.name}',
          'unreadCount': 0,
          'joinedAt': createdAt,
        });
      }

      return chatId;
    } catch (e) {
      print('Error creating group chat: $e');
      rethrow;
    }
  }

  // Get group chats for a teacher
  static Future<List<GroupChat>> getTeacherGroupChats(String schoolId, String teacherId) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      final result = await db.query(
        'GroupChats',
        where: 'schoolId = ? AND teacherId = ?',
        whereArgs: [schoolId, teacherId],
        orderBy: 'lastMessageTime DESC, createdAt DESC',
      );

      // Wait for all futures
      final groupChats = await Future.wait(result.map((row) async {
        final participants = await db.query(
          'GroupChatParticipants',
          where: 'chatId = ? AND participantId = ? AND participantType = ?',
          whereArgs: [row['chatId'], teacherId, 'teacher'],
        );
        final unreadCount = participants.isNotEmpty ? (participants.first['unreadCount'] as int? ?? 0) : 0;
        return GroupChat.fromMap({
          ...row,
          'unreadCount': unreadCount,
        });
      }));

      return groupChats;
    } catch (e) {
      print('Error getting teacher group chats: $e');
      return [];
    }
  }

  // Get group chats for a student
  static Future<List<GroupChat>> getStudentGroupChats(String schoolId, String studentId) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      // Get all group chats where student is a participant
      final participants = await db.query(
        'GroupChatParticipants',
        where: 'participantId = ? AND participantType = ?',
        whereArgs: [studentId, 'student'],
      );

      if (participants.isEmpty) return [];

      final chatIds = participants.map((p) => p['chatId'] as String).toList();
      
      // Get group chats
      final placeholders = chatIds.map((_) => '?').join(',');
      final result = await db.rawQuery(
        'SELECT * FROM GroupChats WHERE chatId IN ($placeholders) AND schoolId = ? ORDER BY lastMessageTime DESC, createdAt DESC',
        [...chatIds, schoolId],
      );

      // Get unread counts for each chat
      final groupChats = await Future.wait(result.map((row) async {
        final participant = await db.query(
          'GroupChatParticipants',
          where: 'chatId = ? AND participantId = ? AND participantType = ?',
          whereArgs: [row['chatId'], studentId, 'student'],
        );
        final unreadCount = participant.isNotEmpty ? (participant.first['unreadCount'] as int? ?? 0) : 0;
        return GroupChat.fromMap({
          ...row,
          'unreadCount': unreadCount,
        });
      }));

      return groupChats;
    } catch (e) {
      print('Error getting student group chats: $e');
      return [];
    }
  }

  // Get group chats for a parent (by student admission number)
  static Future<List<GroupChat>> getParentGroupChats(String schoolId, String studentRollNo) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      // Get all group chats where parent is a participant
      final participants = await db.query(
        'GroupChatParticipants',
        where: 'participantId = ? AND participantType = ?',
        whereArgs: [studentRollNo, 'parent'],
      );

      if (participants.isEmpty) return [];

      final chatIds = participants.map((p) => p['chatId'] as String).toList();
      
      // Get group chats
      final placeholders = chatIds.map((_) => '?').join(',');
      final result = await db.rawQuery(
        'SELECT * FROM GroupChats WHERE chatId IN ($placeholders) AND schoolId = ? ORDER BY lastMessageTime DESC, createdAt DESC',
        [...chatIds, schoolId],
      );

      // Get unread counts for each chat
      final groupChats = await Future.wait(result.map((row) async {
        final participant = await db.query(
          'GroupChatParticipants',
          where: 'chatId = ? AND participantId = ? AND participantType = ?',
          whereArgs: [row['chatId'], studentRollNo, 'parent'],
        );
        final unreadCount = participant.isNotEmpty ? (participant.first['unreadCount'] as int? ?? 0) : 0;
        return GroupChat.fromMap({
          ...row,
          'unreadCount': unreadCount,
        });
      }));

      return groupChats;
    } catch (e) {
      print('Error getting parent group chats: $e');
      return [];
    }
  }

  // Send message to group chat
  static Future<void> sendGroupChatMessage(
    String chatId,
    String senderId,
    String senderType,
    String senderName,
    String message,
  ) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      final messageId = 'msg_${DateTime.now().millisecondsSinceEpoch}_${senderId}';
      final timestamp = DateTime.now().toIso8601String();

      // Insert message
      await db.insert('Messages', {
        'messageId': messageId,
        'chatId': chatId,
        'senderId': senderId,
        'senderType': senderType,
        'senderName': senderName,
        'message': message,
        'timestamp': timestamp,
        'isRead': 0,
      });

      // Update group chat last message
      await db.update(
        'GroupChats',
        {
          'lastMessage': message,
          'lastMessageTime': timestamp,
        },
        where: 'chatId = ?',
        whereArgs: [chatId],
      );

      // Increment unread count for all participants except sender
      await db.rawUpdate(
        'UPDATE GroupChatParticipants SET unreadCount = unreadCount + 1 WHERE chatId = ? AND NOT (participantId = ? AND participantType = ?)',
        [chatId, senderId, senderType],
      );
    } catch (e) {
      print('Error sending group chat message: $e');
      rethrow;
    }
  }

  // Mark group chat messages as read for a participant
  static Future<void> markGroupChatMessagesAsRead(String chatId, String participantId, String participantType) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      // Mark all messages in the chat as read for this participant
      await db.update(
        'Messages',
        {'isRead': 1},
        where: 'chatId = ? AND NOT (senderId = ? AND senderType = ?)',
        whereArgs: [chatId, participantId, participantType],
      );

      // Reset unread count for the participant
      await db.update(
        'GroupChatParticipants',
        {'unreadCount': 0},
        where: 'chatId = ? AND participantId = ? AND participantType = ?',
        whereArgs: [chatId, participantId, participantType],
      );
    } catch (e) {
      print('Error marking group chat messages as read: $e');
    }
  }

  // Get participants for a group chat
  static Future<List<GroupChatParticipant>> getGroupChatParticipants(String chatId) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      final result = await db.query(
        'GroupChatParticipants',
        where: 'chatId = ?',
        whereArgs: [chatId],
        orderBy: 'participantType, participantName',
      );

      return result.map((row) => GroupChatParticipant.fromMap(row)).toList();
    } catch (e) {
      print('Error getting group chat participants: $e');
      return [];
    }
  }

  // Assignment methods
  static Future<void> createAssignment(Assignment assignment) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      // Check if Assignments table exists
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='Assignments'"
      );
      if (tables.isEmpty) {
        throw Exception('Assignments table does not exist. Please restart the app to create it.');
      }
      
      // Build the map manually to ensure proper data types
      final assignmentMap = <String, dynamic>{
        'id': assignment.id,
        'schoolId': assignment.schoolId,
        'teacherId': assignment.teacherId,
        'teacherName': assignment.teacherName,
        'className': assignment.className,
        'subject': assignment.subject,
        'title': assignment.title,
        'description': assignment.description ?? '',
        'dueDate': assignment.dueDate?.toIso8601String() ?? '',
        'postedDate': assignment.postedDate?.toIso8601String() ?? '',
        'attachmentUrl': assignment.attachmentUrl,
        'documentPath': assignment.documentPath,
        'imagePath': assignment.imagePath,
        'assignedClasses': assignment.assignedClasses != null
            ? jsonEncode(assignment.assignedClasses)
            : null,
      };
      
      // Only remove null values for optional fields, keep required ones
      if (assignmentMap['description'] == null) assignmentMap['description'] = '';
      if (assignmentMap['attachmentUrl'] == null) assignmentMap.remove('attachmentUrl');
      if (assignmentMap['documentPath'] == null) assignmentMap.remove('documentPath');
      if (assignmentMap['imagePath'] == null) assignmentMap.remove('imagePath');
      if (assignmentMap['assignedClasses'] == null) assignmentMap.remove('assignedClasses');
      
      print('Inserting assignment: ${assignmentMap['id']}');
      print('Assignment title: ${assignmentMap['title']}');
      print('Assignment class: ${assignmentMap['className']}');
      
      await db.insert('Assignments', assignmentMap, conflictAlgorithm: ConflictAlgorithm.replace);
      print('Assignment saved successfully with ID: ${assignment.id}');
      
      // Verify the assignment was saved
      final verify = await db.query(
        'Assignments',
        where: 'id = ?',
        whereArgs: [assignment.id],
      );
      if (verify.isEmpty) {
        throw Exception('Assignment was not saved - verification failed');
      }
      print('Assignment verified in database');
    } catch (e) {
      print('Error saving assignment: $e');
      print('Assignment that failed: ${assignment.toMap()}');
      rethrow;
    }
  }

  static Future<List<Assignment>> fetchTeacherAssignments(String schoolId, String teacherId) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      print('Fetching assignments for teacher: $teacherId in school: $schoolId');
      final result = await db.query(
        'Assignments',
        where: 'schoolId = ? AND teacherId = ?',
        whereArgs: [schoolId, teacherId],
        orderBy: 'postedDate DESC',
      );

      print('Found ${result.length} assignments in database');
      
      final service = Database_Service();
      final assignments = result.map((row) {
        try {
          final assignment = Assignment.fromMap(Map<String, dynamic>.from(row));
          if (row['assignedClasses'] != null && row['assignedClasses'] is String) {
            assignment.assignedClasses = service._jsonToList(row['assignedClasses'] as String?);
          }
          print('Parsed assignment: ${assignment.id} - ${assignment.title}');
          return assignment;
        } catch (e) {
          print('Error parsing assignment row: $e');
          print('Row data: $row');
          return null;
        }
      }).where((a) => a != null).cast<Assignment>().toList();
      
      print('Successfully parsed ${assignments.length} assignments');
      return assignments;
    } catch (e) {
      print('Error fetching teacher assignments: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  static Future<List<Assignment>> fetchStudentAssignments(String schoolId, String className) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      print('Fetching assignments for class: $className in school: $schoolId');
      // Fetch assignments where className matches or assignedClasses contains the class
      final result = await db.rawQuery('''
        SELECT * FROM Assignments 
        WHERE schoolId = ? 
        AND (className = ? OR assignedClasses LIKE ?)
        ORDER BY postedDate DESC
      ''', [schoolId, className, '%$className%']);

      print('Found ${result.length} potential assignments in database');

      final service = Database_Service();
      List<Assignment> assignments = [];
      for (var row in result) {
        try {
          final assignment = Assignment.fromMap(Map<String, dynamic>.from(row));
          if (row['assignedClasses'] != null && row['assignedClasses'] is String) {
            assignment.assignedClasses = service._jsonToList(row['assignedClasses'] as String?);
          }
          // Filter to ensure the class is actually in assignedClasses if it's a multi-class assignment
          if (assignment.className == className || 
              (assignment.assignedClasses != null && assignment.assignedClasses!.contains(className))) {
            print('Adding assignment: ${assignment.id} - ${assignment.title}');
            assignments.add(assignment);
          } else {
            print('Skipping assignment ${assignment.id} - class mismatch');
          }
        } catch (e) {
          print('Error parsing assignment row: $e');
          print('Row data: $row');
        }
      }

      print('Returning ${assignments.length} assignments for class: $className');
      return assignments;
    } catch (e) {
      print('Error fetching student assignments: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  static Future<List<Assignment>> fetchParentAssignments(String schoolId, String studentClassName) async {
    // Same as student assignments - parent sees assignments for their child's class
    return fetchStudentAssignments(schoolId, studentClassName);
  }

  static Future<bool> deleteAssignment(String assignmentId) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      final deleted = await db.delete(
        'Assignments',
        where: 'id = ?',
        whereArgs: [assignmentId],
      );
      return deleted > 0;
    } catch (e) {
      print('Error deleting assignment: $e');
      return false;
    }
  }

  // Assignment Submission methods
  static Future<void> submitAssignment(AssignmentSubmission submission) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      await db.insert(
        'AssignmentSubmissions',
        submission.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('Assignment submission saved successfully');
    } catch (e) {
      print('Error saving assignment submission: $e');
      rethrow;
    }
  }

  static Future<AssignmentSubmission?> getStudentSubmission(String assignmentId, String studentId) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      final result = await db.query(
        'AssignmentSubmissions',
        where: 'assignmentId = ? AND studentId = ?',
        whereArgs: [assignmentId, studentId],
        limit: 1,
      );

      if (result.isEmpty) return null;

      return AssignmentSubmission.fromMap(Map<String, dynamic>.from(result.first));
    } catch (e) {
      print('Error fetching student submission: $e');
      return null;
    }
  }

  static Future<List<AssignmentSubmission>> getAssignmentSubmissions(String assignmentId) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    try {
      final result = await db.query(
        'AssignmentSubmissions',
        where: 'assignmentId = ?',
        whereArgs: [assignmentId],
        orderBy: 'submittedDate DESC',
      );

      return result.map((row) => AssignmentSubmission.fromMap(Map<String, dynamic>.from(row))).toList();
    } catch (e) {
      print('Error fetching assignment submissions: $e');
      return [];
    }
  }
}

