import 'package:classinsight/Services/Database_Service.dart';
import 'package:classinsight/models/StudentModel.dart';
import 'package:classinsight/models/TeacherModel.dart';
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
  runApp(MaterialApp(debugShowCheckedModeBanner: false, home: MarksScreen()));
}

class MarksScreenController extends GetxController {
  var marksTypeList = <String>[].obs;
  var studentsList = <Student>[].obs;
  final totalMarksController = TextEditingController();
  var subjectsListTeachers = <String>[].obs;
  List<dynamic>? arguments;
  String? schoolId;
  late String className;
  late Teacher teacher;

  var selectedSubject = ''.obs;
  var selectedMarksType = ''.obs;
  var selectedTerm = ''.obs;
  var availableTerms = <String>[].obs;

  var totalMarksValid = true.obs;
  var isLoading = true.obs;

  Database_Service databaseService = Database_Service();

  // Define a map to store TextEditingControllers for obtained marks
  var obtainedMarksControllers = <String, TextEditingController>{}.obs;

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
      isLoading.value = false;
      return;
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

  Future<void> fetchSubjects() async {
    subjectsListTeachers.clear();
    print(schoolId);
    print(teacher.empID);

    var subjectsList = await databaseService.fetchUniqueSubjects(
        schoolId!, teacher.empID, className);

    Set<String> uniqueSubjects = {};

    uniqueSubjects.addAll(subjectsList);

    subjectsListTeachers.addAll(uniqueSubjects.toList());
    if (subjectsListTeachers.isNotEmpty && selectedSubject.value.isEmpty) {
      selectedSubject.value = subjectsListTeachers.first;
    }
  }

  void fetchInitialData() async {
    isLoading.value = true;
    try {
      if (schoolId != null && schoolId!.isNotEmpty) {
        print('Fetching data for schoolId: $schoolId, className: $className');
        
        // Fetch all data with timeout
        final results = await Future.wait([
          databaseService.fetchUniqueSubjects(schoolId!, teacher.empID, className),
          Database_Service.getStudentsOfASpecificClass(schoolId!, className),
          databaseService.fetchExamStructure(schoolId!, className),
        ]).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('Timeout fetching initial data');
            return [[], <Student>[], <String>[]];
          },
        );

        subjectsListTeachers.value = results[0] as List<String>;
        studentsList.value = results[1] as List<Student>;
        marksTypeList.value = results[2] as List<String>;

        print('Subjects: ${subjectsListTeachers.length}');
        print('Students: ${studentsList.length}');
        print('Exam Types: ${marksTypeList.length}');

        // Set default subject if available
        if (subjectsListTeachers.isNotEmpty && selectedSubject.value.isEmpty) {
          selectedSubject.value = subjectsListTeachers.first;
        }

        // Set default exam type if available
        if (marksTypeList.isNotEmpty && selectedMarksType.value.isEmpty) {
          selectedMarksType.value = marksTypeList.first;
        }

        // Initialize controllers for each student
        for (var student in studentsList) {
          obtainedMarksControllers[student.studentID] = TextEditingController();
        }
      } else {
        print('Error: schoolId is null or empty');
      }
    } catch (e) {
      print('Error in fetchInitialData: $e');
      // Ensure lists are empty on error to show appropriate message
      subjectsListTeachers.clear();
      studentsList.clear();
      marksTypeList.clear();
    } finally {
      isLoading.value = false;
      print('Finished fetching initial data');
    }
  }

  Future<Map<String, String>> fetchStudentResults(String studentID) async {
    Map<String, Map<String, String>>? studentResult =
        await databaseService.fetchStudentResultMap(schoolId!, studentID, term: selectedTerm.value);
    return studentResult[selectedSubject.value] ?? {};
  }

  void updateData() async {
    subjectsListTeachers.value = await databaseService.fetchUniqueSubjects(
        schoolId!, teacher.empID, className);
    studentsList.value = await Database_Service.getStudentsOfASpecificClass(
        schoolId!, className);
    marksTypeList.value =
        await databaseService.fetchExamStructure(schoolId!, className);
  }

  void updateStudentResults() async {
    studentsList.refresh();
  }

  String getTotalMarks() {
    return totalMarksController.text.isEmpty ? "-" : totalMarksController.text;
  }
  
  void moveToNextExamOrTerm() {
    if (marksTypeList.isEmpty || selectedMarksType.value.isEmpty) {
      return;
    }
    
    try {
      // Find current exam type index
      final currentExamIndex = marksTypeList.indexOf(selectedMarksType.value);
      
      // Check if there's a next exam type
      if (currentExamIndex >= 0 && currentExamIndex < marksTypeList.length - 1) {
        // Move to next exam type in current term
        selectedMarksType.value = marksTypeList[currentExamIndex + 1];
        
        // Clear input fields for fresh entry
        totalMarksController.clear();
        for (var controller in obtainedMarksControllers.values) {
          controller.clear();
        }
        
        // Refresh student results to show new exam type's data
        updateStudentResults();
      } else {
        // We're at the last exam type, move to next term
        moveToNextTerm();
      }
    } catch (e) {
      print('Error moving to next exam or term: $e');
    }
  }
  
  void moveToNextTerm() {
    if (availableTerms.isEmpty || selectedTerm.value.isEmpty) {
      return;
    }
    
    try {
      // Find current term index
      final currentIndex = availableTerms.indexOf(selectedTerm.value);
      
      String? nextTermKey;
      
      if (currentIndex == -1) {
        // Current term not found in list, try to determine next term from current term
        final match = RegExp(r'^(\d{4})_([^_]+)_(Term\s*\d+|term\s*\d+)', caseSensitive: false).firstMatch(selectedTerm.value);
        
        if (match != null) {
          final termMatch = RegExp(r'(\d+)', caseSensitive: false).firstMatch(match.group(3)!);
          if (termMatch != null) {
            final currentTermNum = int.tryParse(termMatch.group(1)!);
            
            if (currentTermNum != null && currentTermNum < 3) {
              // Move to next term in current year (Term 1 → Term 2, Term 2 → Term 3)
              final nextTermNum = currentTermNum + 1;
              nextTermKey = '${match.group(1)!}_${match.group(2)!}_Term $nextTermNum';
            } else if (currentTermNum == 3) {
              // We're at Term 3, move to next year's Term 1
              final currentYearInt = int.tryParse(match.group(1)!);
              if (currentYearInt != null) {
                final nextYear = (currentYearInt + 1).toString();
                nextTermKey = '${nextYear}_${match.group(2)!}_Term 1';
              }
            }
          }
        }
      } else if (currentIndex < availableTerms.length - 1) {
        // Move to next term in the list
        nextTermKey = availableTerms[currentIndex + 1];
      } else {
        // We're at the last term in list, check if we need to create next term
        final match = RegExp(r'^(\d{4})_([^_]+)_(Term\s*\d+|term\s*\d+)', caseSensitive: false).firstMatch(selectedTerm.value);
        
        if (match != null) {
          final termMatch = RegExp(r'(\d+)', caseSensitive: false).firstMatch(match.group(3)!);
          if (termMatch != null) {
            final currentTermNum = int.tryParse(termMatch.group(1)!);
            
            if (currentTermNum != null && currentTermNum < 3) {
              // Move to next term in current year (Term 1 → Term 2, Term 2 → Term 3)
              final nextTermNum = currentTermNum + 1;
              nextTermKey = '${match.group(1)!}_${match.group(2)!}_Term $nextTermNum';
            } else if (currentTermNum == 3) {
              // We're at Term 3, move to next year's Term 1
              final currentYearInt = int.tryParse(match.group(1)!);
              if (currentYearInt != null) {
                final nextYear = (currentYearInt + 1).toString();
                nextTermKey = '${nextYear}_${match.group(2)!}_Term 1';
              }
            }
          }
        }
      }
      
      // Update to next term if found
      if (nextTermKey != null) {
        // Add to available terms if not already there
        if (!availableTerms.contains(nextTermKey)) {
          availableTerms.add(nextTermKey);
        }
        selectedTerm.value = nextTermKey;
        
        // Reset to first exam type for the new term
        if (marksTypeList.isNotEmpty) {
          selectedMarksType.value = marksTypeList.first;
        }
        
        // Clear input fields for fresh entry
        totalMarksController.clear();
        for (var controller in obtainedMarksControllers.values) {
          controller.clear();
        }
        
        // Refresh student results to show new term's data
        updateStudentResults();
      }
    } catch (e) {
      print('Error moving to next term: $e');
    }
  }
}

class MarksScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MarksScreenController());
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
                      Container(
                        width: 48.0,
                      ),
                      TextButton(
                        onPressed: () async {
                          String? schoolId =
                              controller.schoolId; // Nullable schoolId
                          if (schoolId == null) {
                            Get.snackbar(
                              'Error',
                              'School ID is missing.',
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                            return; // Exit the method if schoolId is null
                          }

                          String subject = controller.selectedSubject.value;
                          String examType = controller.selectedMarksType.value;
                          String totalMarks = controller.getTotalMarks();

                          // Validate if totalMarks is a number
                          if (totalMarks.isEmpty ||
                              !RegExp(r'^[0-9]+$').hasMatch(totalMarks)) {
                            // Show error message and exit if totalMarks is invalid
                            Get.snackbar(
                              'Error',
                              'Total Marks must be a valid number.',
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                            return; // Exit the method
                          }

                          bool allValid =
                              true; // Flag to check if all obtained marks are valid

                          // Convert totalMarks to an integer for comparison
                          int totalMarksInt = int.tryParse(totalMarks) ?? 0;

                          for (var student in controller.studentsList) {
                            String studentRollNo = student.studentRollNo;
                            String studentName = student.name;
                            String obtainedMarks = controller
                                    .obtainedMarksControllers[student.studentID]
                                    ?.text ??
                                '';

                            // Validate if obtainedMarks is a number and within range
                            if (obtainedMarks.isNotEmpty) {
                              if (!RegExp(r'^[0-9]+$')
                                  .hasMatch(obtainedMarks)) {
                                obtainedMarks =
                                    '-'; // Set to '-' if obtainedMarks is not numeric
                                allValid =
                                    false; // Mark as invalid if obtainedMarks is incorrect
                              } else if ((int.tryParse(obtainedMarks) ?? -1) <
                                      0 ||
                                  (int.tryParse(obtainedMarks) ?? 0) >
                                      totalMarksInt) {
                                obtainedMarks =
                                    '-'; // Set to '-' if obtainedMarks is out of range
                                allValid =
                                    false; // Mark as invalid if obtainedMarks is out of range
                              }
                            } else {
                              obtainedMarks =
                                  '-'; // Set to '-' if obtainedMarks is empty
                            }

                            // Print the values (for debugging or logging purposes)
                            print(
                                'Roll No.: $studentRollNo, Name: $studentName, Obtained Marks: $obtainedMarks, Total Marks: $totalMarks, Subject: $subject, Exam Type: $examType');

                            // Format the marks
                            String formattedMarks =
                                '$obtainedMarks/$totalMarks';

                            // Update or add marks to the database
                            Database_Service database_service =
                                Database_Service();
                            await database_service.updateOrAddMarks(
                              schoolId,
                              student.studentID,
                              subject,
                              examType,
                              formattedMarks,
                              term: controller.selectedTerm.value,
                              className: controller.className,
                              year: DateTime.now().year.toString(),
                            );
                          }

                          // Show success or error message based on validity
                          if (allValid) {
                            // Refresh student results to show updated marks immediately
                            controller.updateStudentResults();
                            
                            // Automatically move to next exam type or next term
                            controller.moveToNextExamOrTerm();
                            
                            Get.snackbar(
                              'Success',
                              'Marks have been updated successfully.',
                              backgroundColor: Colors.green,
                              colorText: Colors.white,
                            );
                          } else {
                            Get.snackbar(
                              'Error',
                              'Please enter valid marks for all students.',
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                          }
                        },
                        child: Text(
                          "Save",
                          style: Font_Styles.labelHeadingLight(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(30, 10, 30, 10),
                          child: Obx(() {
                            if (controller.isLoading.value) {
                              return Center(child: CircularProgressIndicator());
                            }
                            var subjectsList = controller.subjectsListTeachers;
                    if (subjectsList.isEmpty) {
                      return Center(child: Text('No subjects found'));
                    } else {
                      if (!subjectsList
                          .contains(controller.selectedSubject.value)) {
                        controller.selectedSubject.value =
                            subjectsList.isNotEmpty ? subjectsList[0] : '';
                      }

                      return DropdownButtonFormField<String>(
                        initialValue: controller.selectedSubject.value.isEmpty
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
                        items:
                            controller.subjectsListTeachers.map((String value) {
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
                SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.fromLTRB(30, 0, 30, 10),
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return Center(child: CircularProgressIndicator());
                    }
                    var marksTypeList = controller.marksTypeList;
                    if (marksTypeList.isEmpty) {
                      return Center(child: Text('No exam types found. Please add exam structure from admin panel.'));
                    } else {
                      if (!marksTypeList
                          .contains(controller.selectedMarksType.value)) {
                        controller.selectedMarksType.value =
                            marksTypeList.isNotEmpty ? marksTypeList[0] : '';
                      }

                      return DropdownButtonFormField<String>(
                        initialValue: controller.selectedMarksType.value.isEmpty
                            ? null
                            : controller.selectedMarksType.value,
                        decoration: InputDecoration(
                          labelText: "Marks Type",
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
                        items: marksTypeList.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            controller.selectedMarksType.value = newValue;
                          }
                        },
                      );
                    }
                  }),
                ),
                SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.fromLTRB(30, 0, 30, 10),
                  child: Obx(() => DropdownButtonFormField<String>(
                    value: controller.selectedTerm.value.isEmpty ? null : controller.selectedTerm.value,
                    decoration: InputDecoration(
                      labelText: "Term",
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
                    items: controller.availableTerms.map((String value) {
                      final displayText = Database_Service.formatTermDisplay(value);
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(displayText),
                      );
                    }).toList(),
                    selectedItemBuilder: (BuildContext context) {
                      return controller.availableTerms.map((String value) {
                        final displayText = Database_Service.formatTermDisplay(value);
                        return Text(displayText, overflow: TextOverflow.ellipsis);
                      }).toList();
                    },
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        controller.selectedTerm.value = newValue;
                      }
                    },
                  )),
                ),
                SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.fromLTRB(30, 0, 30, 10),
                  child: TextFormField(
                    controller: controller.totalMarksController,
                    autofocus: false,
                    style: TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Enter total marks',
                      labelText: 'Total Marks',
                      labelStyle: TextStyle(color: Colors.black),
                      floatingLabelStyle: TextStyle(color: Colors.black),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        borderSide: BorderSide(
                          color: controller.totalMarksValid.value
                              ? Colors.black
                              : Colors.red,
                          width: 1.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        borderSide: BorderSide(
                          color: AppColors.appOrange,
                          width: 2.0,
                        ),
                      ),
                    ),
                  ),
                ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return Center(child: CircularProgressIndicator());
                    }
                    var marksTypeList = controller.marksTypeList;
                    if (marksTypeList.isEmpty) {
                      return Container(
                        width: screenWidth,
                        height: 20,
                        padding: EdgeInsets.only(left: 30),
                        child: Center(
                          child: Text(
                            'No exams found for this Class. Please add exam structure from admin panel.',
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
                            var totalMarks = controller.getTotalMarks();
                            return DataTable(
                              columns: [
                                DataColumn(
                                  label: Text(
                                    'Roll No.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Student Name',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Obtained Marks',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Total Marks',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              rows: students.map((student) {
                                return DataRow(
                                  color:
                                      WidgetStateProperty.resolveWith<Color?>(
                                    (Set<WidgetState> states) {
                                      return AppColors.appOrange;
                                    },
                                  ),
                                  cells: [
                                    DataCell(Text(student.studentRollNo)),
                                    DataCell(Text(student.name)),
                                    DataCell(
                                      Obx(() {
                                        // Get the instance of MarksScreenController
                                        final marksController =
                                            Get.find<MarksScreenController>();

                                        // Get the TextEditingController for the current student
                                        TextEditingController controller =
                                            marksController
                                                        .obtainedMarksControllers[
                                                    student.studentID] ??
                                                TextEditingController();

                                        return TextFormField(
                                          controller: controller,
                                          decoration: InputDecoration(
                                            hintText: 'Enter',
                                            hintStyle: TextStyle(
                                              color: const Color.fromARGB(
                                                  255,
                                                  162,
                                                  159,
                                                  159), // Light gray hint text
                                              fontWeight: FontWeight
                                                  .normal, // Ensure hint text is not bold
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical:
                                                  4, // Adjust padding if needed
                                            ),
                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide
                                                  .none, // Remove the bottom border
                                            ),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide
                                                  .none, // Remove the bottom border when focused
                                            ),
                                            errorBorder: UnderlineInputBorder(
                                              borderSide: BorderSide
                                                  .none, // Remove the bottom border on error
                                            ),
                                            focusedErrorBorder:
                                                UnderlineInputBorder(
                                              borderSide: BorderSide
                                                  .none, // Remove the bottom border on error focus
                                            ),
                                          ),
                                          style: TextStyle(
                                            color: Colors
                                                .black, // Style input text
                                            fontWeight: FontWeight
                                                .normal, // Ensure input text is not bold
                                          ),
                                          onChanged: (value) {
                                            // Optional: Handle obtained marks input if needed
                                          },
                                        );
                                      }),
                                    ),
                                    DataCell(
                                      Text(totalMarks),
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
