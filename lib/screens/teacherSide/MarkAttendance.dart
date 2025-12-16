import 'package:classinsight/Services/Database_Service.dart';
import 'package:classinsight/models/StudentModel.dart';
import 'package:classinsight/models/TeacherModel.dart';
import 'package:classinsight/utils/AppColors.dart';
import 'package:classinsight/utils/fontStyles.dart';
import 'package:classinsight/utils/name_utils.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

class AttendanceController extends GetxController {
  TextEditingController datepicker = TextEditingController();
  TextEditingController remarkscontroller = TextEditingController();
  RxList<Student> studentsList = RxList<Student>();
  RxString selectedHeaderValue = ''.obs;
  List<dynamic>? arguments;
  RxString schoolId = ''.obs;
  RxString selectedClass = ''.obs;
  RxString teacherName = ''.obs;
  RxString teacherGender = ''.obs;
  RxString subject = ''.obs;
  var selectedSubject = ''.obs;
  var subjectsList = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    arguments = Get.arguments as List<dynamic>?;
    if (arguments == null || arguments!.length < 4) {
      Get.snackbar('Error', 'Missing required arguments');
      return;
    }
    datepicker.text = "${DateTime.now().toLocal()}".split(' ')[0];
    schoolId.value = arguments![0] as String;
    selectedClass.value = arguments![1] as String;
    final teacher = arguments![2] as Teacher;
    teacherName.value = teacher.name;
    teacherGender.value = teacher.gender;
    subjectsList.value = List<String>.from(arguments![3] as List);
    if (subjectsList.isNotEmpty) {
      selectedSubject.value = subjectsList.first;
      subject.value = subjectsList.first;
    }
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    studentsList.value = await Database_Service.getStudentsOfASpecificClass(
        schoolId.value, selectedClass.value);
    print(studentsList);
    _initializeAttendanceForDate();
  }

  void _initializeAttendanceForDate() {
    for (var student in studentsList) {
      if (!student.attendance.containsKey(subject.value)) {
        student.attendance[subject.value] = {};
      }
      if (!student.attendance[subject.value]!.containsKey(datepicker.text)) {
        student.attendance[subject.value]![datepicker.text] = '';
      }
    }
    studentsList.refresh();
    _updateHeaderValue();
  }

  void updateRowSelection(int index, String? value) {
    studentsList[index].attendance[subject.value]![datepicker.text] =
        value ?? '';
    studentsList.refresh();
    _updateHeaderValue();
  }

  void updateColumnSelection(String? value) {
    for (var student in studentsList) {
      student.attendance[subject.value]![datepicker.text] = value ?? '';
    }
    studentsList.refresh();
    selectedHeaderValue.value = value ?? '';
  }

  void _updateHeaderValue() {
    var values = studentsList
        .map((student) => student.attendance[subject.value]?[datepicker.text])
        .toSet();
    if (values.length == 1) {
      selectedHeaderValue.value = values.first ?? '';
    } else {
      selectedHeaderValue.value = '';
    }
  }

  Map<String, String> getStudentStatusMap() {
    Map<String, String> studentStatusMap = {};
    for (var student in studentsList) {
      studentStatusMap[student.studentID] =
          student.attendance[subject.value]?[datepicker.text] ?? '';
    }
    return studentStatusMap;
  }
}

class MarkAttendance extends StatelessWidget {
  MarkAttendance({super.key});
  final AttendanceController controller = Get.put(AttendanceController());

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title:
            Text('Attendance', style: Font_Styles.labelHeadingRegular(context)),
        actions: [
          TextButton(
            onPressed: () async {
              showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text("Attendance"),
                      content: Text(
                          'Are you sure you want to submit the attendance for ${controller.selectedClass} Subject: ${controller.subject.value}?'),
                      actions: [
                        TextButton(
                            onPressed: () {
                              Get.back();
                            },
                            child: Text('No')),
                        TextButton(
                            onPressed: () async {
                              await Database_Service.updateAttendance(
                                  controller.schoolId.value,
                                  controller.getStudentStatusMap(),
                                  controller.datepicker.text,
                                  controller.subject.value);
                            },
                            child: Text('Yes')),
                      ],
                    );
                  });
            },
            child: Text('Submit',
                style: Font_Styles.labelHeadingRegular(context,
                    color: Colors.black)),
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(30, 0, 10, 5),
            child: Text(
              'Subject',
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
              ),
            ),
          ),
          Obx(
            () => Padding(
              padding: EdgeInsets.fromLTRB(30, 0, 30, 15),
              child: DropdownButtonFormField<String>(
                value: controller.subjectsList
                        .contains(controller.selectedSubject.value)
                    ? controller.selectedSubject.value
                    : null,
                decoration: InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: AppColors.appLightBlue, width: 2.0),
                  ),
                ),
                items: controller.subjectsList.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  controller.selectedSubject.value = newValue ?? '';
                  controller.subject.value = newValue ?? '';
                },
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.05),
            child: Text('Students',
                style: Font_Styles.mediumHeadingBold(context,
                    color: Colors.black)),
          ),
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: TextField(
              controller: controller.datepicker,
              readOnly: true,
              decoration: InputDecoration(
                label: Text('Select Date',
                    style: Font_Styles.labelHeadingRegular(context,
                        color: Colors.black)),
                suffixIcon: Icon(FontAwesomeIcons.calendarDay),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onTap: () {
                _selectDate(context);
              },
            ),
          ),
          SizedBox(height: screenHeight * 0.03),
          Expanded(
            child: Obx(() {
              if (controller.studentsList.isEmpty) {
                return Center(
                    child: Text('No students found',
                        style: Font_Styles.labelHeadingRegular(context)));
              } else {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: DataTable(
                      sortColumnIndex: 1,
                      headingRowColor: WidgetStateColor.resolveWith(
                        (states) => AppColors.primaryColor.withOpacity(0.1),
                      ),
                      columns: [
                        DataColumn(
                          numeric: true,
                          label: Text(
                            "Roll No",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            "Student Name",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Present",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Radio<String?>(
                                value: 'Present',
                                // ignore: deprecated_member_use
                                groupValue:
                                    controller.selectedHeaderValue.value.isEmpty
                                        ? null
                                        : controller.selectedHeaderValue.value,
                                // ignore: deprecated_member_use
                                onChanged: (value) {
                                  if (value != null) {
                                    controller.updateColumnSelection(value);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        DataColumn(
                          label: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Absent",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Radio<String?>(
                                value: 'Absent',
                                // ignore: deprecated_member_use
                                groupValue:
                                    controller.selectedHeaderValue.value.isEmpty
                                        ? null
                                        : controller.selectedHeaderValue.value,
                                // ignore: deprecated_member_use
                                onChanged: (value) {
                                  if (value != null) {
                                    controller.updateColumnSelection(value);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        DataColumn(
                          label: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Leave",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Radio<String?>(
                                value: 'Leave',
                                // ignore: deprecated_member_use
                                groupValue:
                                    controller.selectedHeaderValue.value.isEmpty
                                        ? null
                                        : controller.selectedHeaderValue.value,
                                // ignore: deprecated_member_use
                                onChanged: (value) {
                                  if (value != null) {
                                    controller.updateColumnSelection(value);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Remarks',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        )
                      ],
                      rows: controller.studentsList.asMap().entries.map((entry) {
                        int index = entry.key;
                        Student student = entry.value;

                        bool isEven = index % 2 == 0;

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
                            DataCell(
                              Radio<String?>(
                                value: 'Present',
                                // ignore: deprecated_member_use
                                groupValue:
                                    student.attendance[controller.subject.value]
                                            ?[controller.datepicker.text] ??
                                        '',
                                // ignore: deprecated_member_use
                                onChanged: (value) {
                                  if (value != null) {
                                    controller.updateRowSelection(index, value);
                                  }
                                },
                              ),
                            ),
                            DataCell(
                              Radio<String?>(
                                value: 'Absent',
                                // ignore: deprecated_member_use
                                groupValue:
                                    student.attendance[controller.subject.value]
                                            ?[controller.datepicker.text] ??
                                        '',
                                // ignore: deprecated_member_use
                                onChanged: (value) {
                                  if (value != null) {
                                    controller.updateRowSelection(index, value);
                                  }
                                },
                              ),
                            ),
                            DataCell(
                              Radio<String?>(
                                value: 'Leave',
                                // ignore: deprecated_member_use
                                groupValue:
                                    student.attendance[controller.subject.value]
                                            ?[controller.datepicker.text] ??
                                        '',
                                // ignore: deprecated_member_use
                                onChanged: (value) {
                                  if (value != null) {
                                    controller.updateRowSelection(index, value);
                                  }
                                },
                              ),
                            ),
                            DataCell(IconButton(
                              icon: Icon(
                                FontAwesomeIcons.bell,
                                color: AppColors.appPink,
                              ),
                              onPressed: () async {
                                await showAdaptiveDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text('Remarks'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(student.name,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          SizedBox(height: 16),
                                          TextField(
                                            controller:
                                                controller.remarkscontroller,
                                            maxLines: 3,
                                            decoration: InputDecoration(
                                              labelText: 'Write your remarks',
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Get.back();
                                          },
                                          child: Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            String remarks = controller
                                                .remarkscontroller.text;
                                            if (remarks.isNotEmpty) {
                                              print(
                                                  'Remarks for ${student.name}: $remarks');
                                              await Database_Service
                                                  .createAnnouncement(
                                                      controller.schoolId.value,
                                                      student.studentID,
                                                      remarks,
                                                      formatTeacherTitle(
                                                        controller
                                                            .teacherName.value,
                                                        controller
                                                            .teacherGender.value,
                                                      ),
                                                      false);

                                              Get.back();
                                            } else {
                                              Get.snackbar('Error',
                                                  'Please enter some remarks before submitting.');
                                            }
                                          },
                                          child: Text('Submit'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ))
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              }
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      controller.datepicker.text = "${picked.toLocal()}".split(' ')[0];
      controller.fetchStudents();
    }
  }
}
