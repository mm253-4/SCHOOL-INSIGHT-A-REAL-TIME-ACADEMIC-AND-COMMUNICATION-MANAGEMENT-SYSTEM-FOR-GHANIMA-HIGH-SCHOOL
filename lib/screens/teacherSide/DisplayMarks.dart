import 'package:classinsight/Services/Database_Service.dart';
import 'package:classinsight/models/StudentModel.dart';
import 'package:classinsight/models/TeacherModel.dart';
import 'package:classinsight/screens/teacherSide/MarksScreen.dart';
import 'package:classinsight/utils/AppColors.dart';
import 'package:classinsight/utils/fontStyles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await GetStorage.init();
  } catch (e) {
    print(e.toString());
  }

  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/displayMarks',
      getPages: [
        GetPage(name: '/displayMarks', page: () => DisplayMarks()),
        GetPage(
            name: '/MarksScreen',
            page: () => MarksScreen()), // Add your MarksScreen route
      ],
    ),
  );
}

class DisplayMarksController extends GetxController {
  var studentsList = <Student>[].obs;
  var examsList = <String>[].obs;
  var subjectsListTeachers = <String>[].obs;
  // var obtainedMarks;

  var selectedSubject = ''.obs;
  late String className;
  String? schoolId;
  late Teacher teacher;

  Database_Service databaseService = Database_Service();

  Future<void> fetchSubjects() async {
    subjectsListTeachers.clear();
    print(schoolId);
    print(teacher.empID);

    // Use the fetchUniqueSubjects method to get the subjects taught by the teacher
    var subjectsList = await databaseService.fetchUniqueSubjects(
        schoolId!, teacher.empID, className);

    // Ensure unique subjects (remove duplicates)
    Set<String> uniqueSubjects = Set.from(subjectsList);

    subjectsListTeachers.value = uniqueSubjects.toList();
    if (subjectsListTeachers.isNotEmpty && selectedSubject.value.isEmpty) {
      selectedSubject.value = subjectsListTeachers.first;
    }
  }

  Future<void> fetchInitialData() async {
    if (schoolId != null) {
      await fetchSubjects(); // Correctly await the async method
      studentsList.value = await Database_Service.getStudentsOfASpecificClass(
          schoolId!, className);
      examsList.value =
          await databaseService.fetchExamStructure(schoolId!, className);
    } else {
      print('Error: schoolId is null');
    }
  }

  // Future<String> fetchTotalObtainedMarks(String studentID) async {
  //   try {
  //     DocumentSnapshot studentDoc = await FirebaseFirestore.instance
  //         .collection('Schools')
  //         .doc(schoolId!)
  //         .collection('Students')
  //         .doc(studentID)
  //         .get();

  //     if (studentDoc.exists) {
  //       Map<String, dynamic> resultMap = studentDoc['resultMap'];
  //       int totalSum = 0;

  //       var subjectResults = resultMap[selectedSubject.value] ?? {};

  //       for (var examType in examsList) {
  //         var marks = subjectResults[examType] ?? '-';
  //         if (marks is String) {
  //           RegExp regex = RegExp(r'(\d+)/(\d+)');
  //           Match? match = regex.firstMatch(marks);
  //           if (match != null) {
  //             int obtainedMarks = int.tryParse(match.group(1) ?? '0') ?? 0;
  //             totalSum += obtainedMarks;
  //           }
  //         }
  //       }

  //       return totalSum.toString();
  //     } else {
  //       return '0';
  //     }
  //   } catch (e) {
  //     print('Error fetching resultMap: $e');
  //     return '0';
  //   }
  // }

  // Future<String> fetchStudentTotalMarksSum(String studentID) async {
  //   try {
  //     DocumentSnapshot studentDoc = await FirebaseFirestore.instance
  //         .collection('Schools')
  //         .doc(schoolId!)
  //         .collection('Students')
  //         .doc(studentID)
  //         .get();

  //     if (studentDoc.exists) {
  //       Map<String, dynamic> resultMap = studentDoc['resultMap'];
  //       int totalSum = 0;

  //       // Get the results for the selected subject
  //       var subjectResults = resultMap[selectedSubject.value] ?? {};

  //       for (var examType in examsList) {
  //         var marks = subjectResults[examType] ?? '-';
  //         if (marks is String) {
  //           RegExp regex = RegExp(r'\d+/(\d+)');
  //           Match? match = regex.firstMatch(marks);
  //           if (match != null) {
  //             int totalMarks = int.tryParse(match.group(1) ?? '0') ?? 0;
  //             totalSum += totalMarks;
  //           }
  //         }
  //       }

  //       return totalSum.toString();
  //     } else {
  //       return '0';
  //     }
  //   } catch (e) {
  //     print('Error fetching resultMap: $e');
  //     return '0';
  //   }
  // }

  var selectedTerm = ''.obs;
  var availableTerms = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    final List<dynamic>? arguments = Get.arguments as List<dynamic>?;

    if (arguments != null && arguments.length >= 3) {
      schoolId =
          arguments[0] as String? ?? ''; // Default to empty string if null
      className =
          arguments[1] as String? ?? ''; // Default to empty string if null
      teacher = arguments[2] as Teacher;
    } else {
      print('Error: Arguments are null or insufficient');
    }

    fetchInitialData();
    loadTerms();
    ever(selectedSubject, (_) => updateStudentResults());
    ever(selectedTerm, (_) => updateStudentResults());
  }
  
  Future<void> loadTerms() async {
    try {
      if (schoolId != null && schoolId!.isNotEmpty) {
        final terms = await Database_Service.getClassTerms(schoolId!, className);
        final currentYear = DateTime.now().year.toString();
        
        // Always ensure all 3 terms for current year are available
        final currentYearTerms = [
          '${currentYear}_${className}_Term 1',
          '${currentYear}_${className}_Term 2',
          '${currentYear}_${className}_Term 3'
        ];
        
        // Combine existing terms with current year terms (avoid duplicates)
        final Set<String> allTerms = Set.from(terms);
        allTerms.addAll(currentYearTerms);
        
        // Convert to list and sort
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
              return int.parse(aTermNum.group(0)!).compareTo(int.parse(bTermNum.group(0)!));
            }
          }
          return b.compareTo(a);
        });
        
        availableTerms.value = sortedTerms;
        
        if (selectedTerm.value.isEmpty) {
          // Default to current year Term 1
          selectedTerm.value = '${currentYear}_${className}_Term 1';
        }
      }
    } catch (e) {
      print('Error loading terms: $e');
      final currentYear = DateTime.now().year.toString();
      availableTerms.value = [
        '${currentYear}_${className}_Term 1',
        '${currentYear}_${className}_Term 2',
        '${currentYear}_${className}_Term 3'
      ];
      selectedTerm.value = '${currentYear}_${className}_Term 1';
    }
  }

  Future<Map<String, String>> fetchStudentResults(String studentID) async {
    if (schoolId != null) {
      Map<String, Map<String, String>>? studentResult =
          await databaseService.fetchStudentResultMap(schoolId!, studentID, term: selectedTerm.value);
      return studentResult[selectedSubject.value] ?? {};
    } else {
      print('Error: schoolId is null');
      return {};
    }
  }
  
  void onTermChanged(String? newTerm) {
    if (newTerm != null && newTerm != selectedTerm.value) {
      selectedTerm.value = newTerm;
      updateStudentResults();
    }
  }

  void updateStudentResults() async {
    // Refetch student data to get updated results
    await fetchInitialData();
    // Force refresh of the observable list
    studentsList.refresh();
  }
}

class DisplayMarks extends StatelessWidget {
  final DisplayMarksController controller = Get.put(DisplayMarksController());

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            height: screenHeight * 0.10,
            width: screenWidth,
            child: AppBar(
              backgroundColor: Colors.white,
              title: Text(
                'Marks',
                style: Font_Styles.labelHeadingLight(context),
              ),
              centerTitle: true,
              actions: <Widget>[
                      Obx(() => IconButton(
                        icon: Icon(Icons.calendar_today, size: 20),
                        tooltip: controller.selectedTerm.value.isEmpty 
                            ? 'Select Term' 
                            : Database_Service.formatTermDisplay(controller.selectedTerm.value),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Select Term'),
                                content: Obx(() => SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: controller.availableTerms.map((String term) {
                                      final displayText = Database_Service.formatTermDisplay(term);
                                      return ListTile(
                                        title: Text(displayText),
                                        trailing: controller.selectedTerm.value == term
                                            ? Icon(Icons.check, color: AppColors.appDarkBlue)
                                            : null,
                                        onTap: () {
                                          controller.onTermChanged(term);
                                          Get.back();
                                        },
                                      );
                                    }).toList(),
                                  ),
                                )),
                              );
                            },
                          );
                        },
                      )),
                      TextButton(
                        onPressed: () async {
                          print(controller.className);
                          await Get.toNamed('/MarksScreen', arguments: [
                            controller.schoolId,
                            controller.className,
                            controller.teacher
                          ]);
                          // Refresh results when returning from edit screen
                          controller.updateStudentResults();
                        },
                        child: Text(
                          "Edit",
                          style: Font_Styles.labelHeadingLight(context,
                              color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
          Container(
            height: 0.07 * screenHeight,
            width: screenWidth,
            margin: EdgeInsets.only(bottom: 10.0),
            padding: EdgeInsets.only(left: 30),
            child: Text(
              'Subject Result',
              style: TextStyle(
                fontSize: 31,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(30, 0, 30, 15),
            child: Obx(() {
              var subjectsList = controller.subjectsListTeachers;
              if (subjectsList.isEmpty) {
                return Center(child: CircularProgressIndicator());
              } else {
                if (!subjectsList
                    .contains(controller.selectedSubject.value)) {
                  controller.selectedSubject.value =
                      subjectsList.isNotEmpty ? subjectsList[0] : '';
                }

                // Ensure unique subjects before creating dropdown items
                final uniqueSubjects = controller.subjectsListTeachers.toSet().toList();
                
                return DropdownButtonFormField<String>(
                  value: controller.selectedSubject.value.isEmpty || 
                         !uniqueSubjects.contains(controller.selectedSubject.value)
                      ? null
                      : controller.selectedSubject.value,
                  decoration: InputDecoration(
                    labelText: "Subject",
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: AppColors.appOrange, width: 2.0),
                    ),
                  ),
                  items: uniqueSubjects.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      controller.selectedSubject.value = newValue;
                    }
                  },
                );
              }
            }),
          ),
          Expanded(
            child: Obx(() {
              var examsList = controller.examsList;
              if (examsList.isEmpty) {
                return Container(
                  width: screenWidth,
                  height: 20,
                  padding: EdgeInsets.only(left: 30),
                  child: Center(
                    child: Text(
                      'No exams found for this Class',
                    ),
                  ),
                );
              } else {
                return SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Obx(() {
                      var students = controller.studentsList;
                      return DataTable(
                        headingRowColor: WidgetStateColor.resolveWith(
                          (states) => AppColors.primaryColor.withOpacity(0.1),
                        ),
                        columns: [
                          DataColumn(
                            label: Text(
                              'Roll No.',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Student Name',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          for (var exam in examsList)
                            DataColumn(
                              label: Text(
                                exam,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                        ],
                        rows: students.asMap().entries.map((entry) {
                          final index = entry.key;
                          final student = entry.value;
                          final isEven = index % 2 == 0;
                          return DataRow(
                            color: WidgetStateColor.resolveWith(
                              (states) => isEven
                                  ? Colors.white
                                  : AppColors.appLightBlue.withOpacity(0.6),
                            ),
                            cells: [
                              DataCell(
                                Text(
                                  student.studentRollNo,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  student.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              for (var exam in examsList)
                                DataCell(
                                  FutureBuilder<Map<String, String>>(
                                    future: controller.fetchStudentResults(
                                        student.studentID),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Text(
                                          '',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppColors.textPrimary,
                                          ),
                                        );
                                      } else if (snapshot.hasError) {
                                        return Text(
                                          'Error',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppColors.textPrimary,
                                          ),
                                        );
                                      } else {
                                        final marks =
                                            snapshot.data?[exam] ?? '-';
                                        return Text(
                                          marks,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                            ],
                          );
                        }).toList(),
                      );
                    }),
                  ),
                );
              }
            }),
          ),
        ],
      ),
    );
  }
}
