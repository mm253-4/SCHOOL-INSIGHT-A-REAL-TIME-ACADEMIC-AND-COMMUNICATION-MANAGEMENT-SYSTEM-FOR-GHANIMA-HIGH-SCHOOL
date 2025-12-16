import 'package:classinsight/utils/fontStyles.dart';
import 'package:get/get.dart';
import 'package:classinsight/Services/Database_Service.dart';
import 'package:classinsight/Services/PerformanceAnalysisService.dart';
import 'package:classinsight/models/StudentModel.dart';
import 'package:classinsight/utils/AppColors.dart';
import 'package:flutter/material.dart';

// Helper function to group suggestions by term
Map<String, List<ImprovementSuggestion>> _groupSuggestionsByTerm(List<ImprovementSuggestion> suggestions) {
  final Map<String, List<ImprovementSuggestion>> grouped = {};
  for (var suggestion in suggestions) {
    if (!grouped.containsKey(suggestion.term)) {
      grouped[suggestion.term] = [];
    }
    grouped[suggestion.term]!.add(suggestion);
  }
  return grouped;
}

class ResultController extends GetxController {
  var student = Student(
    name: '',
    gender: '',
    bFormChallanId: '',
    fatherName: '',
    fatherPhoneNo: '',
    fatherCNIC: '',
    studentID: '',
    classSection: '',
    feeStatus: '',
    feeStartDate: '',
    feeEndDate: '',
    studentRollNo: '',
  ).obs;
  var examsList = <String>[].obs;
  var subjectsList = <String>[].obs;
  var resultMap = <String, Map<String, String>>{}.obs;
  var weightageMap = <String, String>{}.obs;
  var isLoading = true.obs;
  var availableTerms = <String>[].obs;
  var selectedTerm = ''.obs;
  var improvementSuggestions = <ImprovementSuggestion>[].obs;
  var performanceSummary = Rx<Map<String, Map<String, dynamic>>>({}); // Map<term, summary>
  final String schoolId;

  ResultController(this.schoolId);

  @override
  void onInit() {
    super.onInit();
    loadTerms();
  }

  Future<void> loadTerms() async {
    try {
      final terms = await Database_Service.getStudentTerms(schoolId, student.value.studentID);
      final currentYear = DateTime.now().year.toString();
      final currentClass = student.value.classSection;
      
      // Always ensure all 3 terms for current year are available
      final currentYearTerms = [
        '${currentYear}_${currentClass}_Term 1',
        '${currentYear}_${currentClass}_Term 2',
        '${currentYear}_${currentClass}_Term 3'
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
          
          final aTermNum = RegExp(r'\d+').firstMatch(aMatch.group(3)!);
          final bTermNum = RegExp(r'\d+').firstMatch(bMatch.group(3)!);
          if (aTermNum != null && bTermNum != null) {
            return int.parse(bTermNum.group(0)!).compareTo(int.parse(aTermNum.group(0)!));
          }
        }
        return b.compareTo(a);
      });
      
      availableTerms.value = sortedTerms;
      if (selectedTerm.value.isEmpty) {
        // Default to current year Term 1
        final currentTermKey = '${currentYear}_${currentClass}_Term 1';
        selectedTerm.value = currentTermKey;
      }
      fetchData();
    } catch (e) {
      print('Error loading terms: $e');
      final currentYear = DateTime.now().year.toString();
      final currentClass = student.value.classSection;
      availableTerms.value = [
        '${currentYear}_${currentClass}_Term 1',
        '${currentYear}_${currentClass}_Term 2',
        '${currentYear}_${currentClass}_Term 3'
      ];
      selectedTerm.value = '${currentYear}_${currentClass}_Term 1';
    fetchData();
    }
  }

  void setStudent(Student newStudent) {
    student.value = newStudent;
    loadTerms();
  }

  Future<void> fetchData() async {
    try {
      isLoading.value = true;
      List<String> exams = await Database_Service()
          .fetchExamStructure(schoolId, student.value.classSection);
      
      // Sort exams in the order: CAT, Mid, Final, then others
      exams.sort((a, b) {
        int getOrder(String exam) {
          String examLower = exam.toLowerCase();
          if (examLower == 'cat') return 1;
          if (examLower == 'mid') return 2;
          if (examLower == 'final') return 3;
          return 4; // Other exams come last
        }
        return getOrder(a).compareTo(getOrder(b));
      });
      
      examsList.value = exams;
      subjectsList.value = await Database_Service.fetchSubjects(
          schoolId, student.value.classSection);
      resultMap.value = await Database_Service()
          .fetchStudentResultMap(schoolId, student.value.studentID, term: selectedTerm.value);
          // Fetch weightage for the class
      weightageMap.value = await Database_Service()
          .fetchWeightage(schoolId, student.value.classSection);
      
      // Generate improvement suggestions
      generateImprovementSuggestions();
    } catch (e) {
      print('Error fetching data: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> generateImprovementSuggestions() async {
    try {
      final currentYear = DateTime.now().year.toString();
      final currentClass = student.value.classSection;
      
      // Generate suggestions for all 3 terms of current year
      final currentYearTerms = [
        '${currentYear}_${currentClass}_Term 1',
        '${currentYear}_${currentClass}_Term 2',
        '${currentYear}_${currentClass}_Term 3'
      ];
      
      List<ImprovementSuggestion> allSuggestions = [];
      Map<String, Map<String, dynamic>> allSummaries = {};
      
      for (var term in currentYearTerms) {
        try {
          // Fetch result map for this term
          final termResultMap = await Database_Service()
              .fetchStudentResultMap(schoolId, student.value.studentID, term: term);
          
          // Generate suggestions for this term
          final termSuggestions = PerformanceAnalysisService.analyzePerformance(
            termResultMap,
            subjectsList,
            examsList,
            term,
          );
          allSuggestions.addAll(termSuggestions);
          
          // Generate summary for this term
          final termSummary = PerformanceAnalysisService.getPerformanceSummary(
            termResultMap,
            subjectsList,
            examsList,
            term,
          );
          allSummaries[term] = termSummary;
        } catch (e) {
          print('Error generating suggestions for term $term: $e');
        }
      }
      
      // Generate term-level overall encouragement for each term
      for (var term in currentYearTerms) {
        try {
          final termResultMap = await Database_Service()
              .fetchStudentResultMap(schoolId, student.value.studentID, term: term);
          
          final termOverall = PerformanceAnalysisService.generateTermOverallEncouragement(
            termResultMap,
            subjectsList,
            examsList,
            term,
          );
          
          if (termOverall != null) {
            allSuggestions.add(termOverall);
          }
        } catch (e) {
          print('Error generating term overall encouragement for term $term: $e');
        }
      }
      
      // Sort suggestions by priority and then by term
      allSuggestions.sort((a, b) {
        final priorityOrder = {'High': 0, 'Medium': 1, 'Low': 2};
        final priorityCompare = priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);
        if (priorityCompare != 0) return priorityCompare;
        return a.term.compareTo(b.term);
      });
      
      improvementSuggestions.value = allSuggestions;
      performanceSummary.value = allSummaries;
    } catch (e) {
      print('Error generating suggestions: $e');
    }
  }
  
  void onTermChanged(String? newTerm) {
    if (newTerm != null && newTerm != selectedTerm.value) {
      selectedTerm.value = newTerm;
      fetchData();
    }
  }

  Map<String, String> calculateGrades() {
    Map<String, String> grades = {};

    for (var subject in subjectsList) {
      double subjectPercentage = 0.0;
      var subjectResults = resultMap[subject] ?? {};
      double totalWeightage = 0.0;
      bool allExamsEntered = true;

      for (var exam in examsList) {
        var score = subjectResults[exam];
        var weightage = weightageMap[exam];

        if (score == null || weightage == null || score == '-') {
          allExamsEntered = false; // Missing exam data
          break; // No need to continue if any exam data is missing
        }

        var parts = score.split('/');
        if (parts.length == 2) {
          // Ensure there are exactly two parts
          double obtainedMarks = double.tryParse(parts[0]) ?? 0.0;
          double totalMarks = double.tryParse(parts[1]) ?? 0.0;

          if (totalMarks > 0) {
            double examPercentage = (obtainedMarks / totalMarks) * 100;
            double examWeightage = double.tryParse(weightage) ?? 0.0;
            subjectPercentage += (examPercentage * examWeightage) / 100;
            totalWeightage += examWeightage;
          }
        }
      }

      if (allExamsEntered) {
        if (totalWeightage > 0) {
          subjectPercentage = (subjectPercentage / totalWeightage) * 100;
          grades[subject] = _mapPercentageToGrade(subjectPercentage);
        } else {
          grades[subject] = '-'; // If no weightage, return '-'
        }
      } else {
        grades[subject] = '-'; // Return '-' if not all exams are entered
      }
    }

    return grades;
  }

  String _mapPercentageToGrade(double percentage) {
    if (percentage >= 70) return 'A';
    if (percentage >= 60) return 'B';
    if (percentage >= 50) return 'C';
    if (percentage >= 40) return 'D';
    return 'F';
  }

  // Future<String> fetchTotalObtainedMarks(
  //     String studentID, String subject) async {
  //   try {
  //     DocumentSnapshot studentDoc = await FirebaseFirestore.instance
  //         .collection('Schools')
  //         .doc(schoolId)
  //         .collection('Students')
  //         .doc(studentID)
  //         .get();

  //     if (studentDoc.exists) {
  //       Map<String, dynamic> resultMap = studentDoc['resultMap'];
  //       int totalSum = 0;

  //       var subjectResults = resultMap[subject] ?? {};

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

  // Future<String> fetchStudentTotalMarksSum(
  //     String studentID, String subject) async {
  //   try {
  //     DocumentSnapshot studentDoc = await FirebaseFirestore.instance
  //         .collection('Schools')
  //         .doc(schoolId)
  //         .collection('Students')
  //         .doc(studentID)
  //         .get();

  //     if (studentDoc.exists) {
  //       Map<String, dynamic> resultMap = studentDoc['resultMap'];
  //       int totalSum = 0;

  //       var subjectResults = resultMap[subject] ?? {};

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
}

// Removed Firebase initialization - using SQLite instead

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: Result(),
    );
  }
}

class Result extends StatelessWidget {
  // Helper function to get grade from percentage
  String _getGrade(double percentage) {
    if (percentage >= 70) return 'A';
    if (percentage >= 60) return 'B';
    if (percentage >= 50) return 'C';
    if (percentage >= 40) return 'D';
    return 'F';
  }

  // Helper function to get assessment text based on grade
  String _getAssessment(String grade) {
    switch (grade) {
      case 'A':
        return 'Excellent';
      case 'B':
        return 'Very Good';
      case 'C':
        return 'Good';
      case 'D':
        return 'Needs Improvement';
      case 'F':
        return 'Needs Immediate Attention';
      default:
        return '';
    }
  }

  // Helper function to get color based on grade
  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.blue;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.deepOrange;
      case 'F':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final arguments = Get.arguments as Map<String, dynamic>;
    final Student student = arguments['student'];
    final String schoolId = arguments['schoolId'];

    final ResultController controller = Get.put(ResultController(schoolId));
    controller.setStudent(student);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("Result", style: Font_Styles.labelHeadingRegular(context)),
        centerTitle: true,
        actions: [
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
        ],
      ),
      backgroundColor: Colors.white,
      body: Obx(() {
        double screenHeight = MediaQuery.of(context).size.height;
        double screenWidth = MediaQuery.of(context).size.width;
        Map<String, String> subjectGrades = controller.calculateGrades();

        double resultFontSize = screenWidth < 350
            ? (screenWidth < 300 ? (screenWidth < 250 ? 11 : 14) : 14)
            : 16;
        double headingFontSize = screenWidth < 350
            ? (screenWidth < 300 ? (screenWidth < 250 ? 20 : 23) : 25)
            : 33;

        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.appOrange),
            ),
          );
        } else {
          // Debug prints to check data consistency
          print('Exams List: ${controller.examsList}');
          print('Subjects List: ${controller.subjectsList}');
          print('Result Map: ${controller.resultMap}');
          print('Weightage Map: ${controller.weightageMap}');

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  height: 0.05 * screenHeight,
                  width: screenWidth,
                  margin: EdgeInsets.only(bottom: 10.0),
                  padding: EdgeInsets.only(left: 30),
                  child: Text(
                    controller.student.value.name,
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: headingFontSize,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Obx(() {
                    List<String> exams = controller.examsList;
                    List<String> subjects = controller.subjectsList;
                    Map<String, Map<String, String>> resultMap =
                        controller.resultMap;

                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        columns: [
                          DataColumn(
                            label: Text(
                              'Subjects',
                              style: TextStyle(
                                fontSize: resultFontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          ...exams.map((exam) => DataColumn(
                                label: Text(
                                  exam,
                                  style: TextStyle(
                                    fontSize: resultFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              )),
                          DataColumn(
                            label: Text(
                              'Grade',
                              style: TextStyle(
                                fontSize: resultFontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                        rows: subjects.asMap().entries.map((entry) {
                          int index = entry.key;
                          String subject = entry.value;
                          // Alternate row colors for better visibility
                          bool isEven = index % 2 == 0;
                          
                          // Ensure that subjectResults is always initialized
                          var subjectResults = resultMap[subject] ?? {};
                          var subjectGradesCells = exams.map((exam) {
                            return DataCell(Text(
                              subjectResults[exam] ?? '-',
                              style: TextStyle(
                                fontSize: resultFontSize,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ));
                          }).toList();

                          // Calculate the grade for this subject
                          String grade = subjectGrades[subject] ?? '-';

                          // Add the grade cell to the end of the row
                          return DataRow(
                            color: WidgetStateColor.resolveWith(
                                (states) => isEven ? AppColors.appLightBlue : Colors.white),
                            cells: [
                              DataCell(Text(
                                subject,
                                style: TextStyle(
                                  fontSize: resultFontSize,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              )),
                              ...subjectGradesCells,
                              DataCell(Text(
                                grade,
                                style: TextStyle(
                                  fontSize: resultFontSize,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              )),
                            ],
                          );
                        }).toList(),
                      ),
                    );
                  }),
                ),
                // Improvement Suggestions Section
                Obx(() {
                  // Filter suggestions for selected term only
                  final selectedTermSuggestions = controller.improvementSuggestions
                      .where((s) => s.term == controller.selectedTerm.value)
                      .toList();
                  
                  if (selectedTermSuggestions.isEmpty || controller.selectedTerm.value.isEmpty) {
                    return SizedBox.shrink();
                  }
                  
                  return Container(
                    margin: EdgeInsets.all(20),
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: AppColors.appDarkBlue, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_outline, color: AppColors.appDarkBlue, size: 28),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Areas of Improvement',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                  if (controller.selectedTerm.value.isNotEmpty)
                                    Text(
                                      Database_Service.formatTermDisplay(controller.selectedTerm.value),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 15),
                        // Display performance summary for selected term only
                        Builder(
                          builder: (context) {
                            if (controller.selectedTerm.value.isNotEmpty && 
                                controller.performanceSummary.value.containsKey(controller.selectedTerm.value)) {
                              final summary = controller.performanceSummary.value[controller.selectedTerm.value]!;
                              return Container(
                                margin: EdgeInsets.only(bottom: 15),
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.appDarkBlue.withOpacity(0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      Database_Service.formatTermDisplay(controller.selectedTerm.value),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        Column(
                                          children: [
                                            Text(
                                              'Overall Average',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              '${(summary['overallAverage'] ?? 0.0).toStringAsFixed(1)}%',
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primaryColor,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            // Calculate and display grade
                                            Builder(
                                              builder: (context) {
                                                final average = summary['overallAverage'] ?? 0.0;
                                                final grade = _getGrade(average);
                                                final assessment = _getAssessment(grade);
                                                return Column(
                                                  children: [
                                                    Text(
                                                      'Grade $grade',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: _getGradeColor(grade),
                                                      ),
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      assessment,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w600,
                                                        color: _getGradeColor(grade),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                        Container(width: 1, height: 40, color: Colors.grey.shade300),
                                        Column(
                                          children: [
                                            Text(
                                              'Pass Rate',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              '${(summary['passRate'] ?? 0.0).toStringAsFixed(1)}%',
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.accentColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }
                            return SizedBox.shrink();
                          },
                        ),
                        SizedBox(height: 15),
                        // Show suggestions for selected term only
                        Builder(
                          builder: (context) {
                            if (controller.selectedTerm.value.isEmpty) {
                              return SizedBox.shrink();
                            }
                            
                            final selectedTermSuggestions = controller.improvementSuggestions
                                .where((s) => s.term == controller.selectedTerm.value)
                                .toList();
                            
                            if (selectedTermSuggestions.isEmpty) {
                              return SizedBox.shrink();
                            }
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(bottom: 10, top: 5),
                                  child: Text(
                                    Database_Service.formatTermDisplay(controller.selectedTerm.value),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                ),
                                ...selectedTermSuggestions.map((suggestion) {
                          Color priorityColor;
                          IconData priorityIcon;
                          if (suggestion.priority == 'High') {
                            priorityColor = Colors.red;
                            priorityIcon = Icons.priority_high;
                          } else if (suggestion.priority == 'Medium') {
                            priorityColor = Colors.orange;
                            priorityIcon = Icons.warning_amber;
                          } else {
                            priorityColor = Colors.blue;
                            priorityIcon = Icons.info_outline;
                          }
                          
                          return Container(
                            margin: EdgeInsets.only(bottom: 12),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border(
                                left: BorderSide(
                                  width: 4,
                                  color: priorityColor,
                                ),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: priorityColor.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(priorityIcon, color: priorityColor, size: 20),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            '${suggestion.priority} Priority',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: priorityColor,
                                            ),
                                          ),
                                          Spacer(),
                                          Text(
                                            '${suggestion.currentScore.toStringAsFixed(1)}%',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        suggestion.suggestion,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                                }).toList(),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      }
    }),
  );
  }

  // String calculateGrade(Map<String, String> subjectResults) {
  //   int totalMarks = 0;
  //   int obtainedMarks = 0;

  //   subjectResults.forEach((exam, marks) {
  //     if (marks.contains('/')) {
  //       var parts = marks.split('/');
  //       if (parts.length == 2) {
  //         obtainedMarks += int.tryParse(parts[0]) ?? 0;
  //         totalMarks += int.tryParse(parts[1]) ?? 0;
  //       }
  //     }
  //   });

  //   if (totalMarks == 0) {
  //     return '-';
  //   }

  //   double percentage = (obtainedMarks / totalMarks) * 100;
  //   if (percentage >= 90) {
  //     return 'A+';
  //   } else if (percentage >= 80) {
  //     return 'A';
  //   } else if (percentage >= 70) {
  //     return 'B';
  //   } else if (percentage >= 60) {
  //     return 'C';
  //   } else if (percentage >= 50) {
  //     return 'D';
  //   } else {
  //     return 'F';
  //   }
  // }
}
