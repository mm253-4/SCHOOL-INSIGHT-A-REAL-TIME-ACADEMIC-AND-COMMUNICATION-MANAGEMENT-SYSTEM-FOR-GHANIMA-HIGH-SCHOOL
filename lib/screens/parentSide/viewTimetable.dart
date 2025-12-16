// ignore_for_file: invalid_use_of_protected_member
import 'package:classinsight/Services/Database_Service.dart';
import 'package:classinsight/models/StudentModel.dart';
import 'package:classinsight/utils/AppColors.dart';
import 'package:classinsight/utils/fontStyles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ViewTimetableController extends GetxController {
  late Student student;
  var timetable = <String, dynamic>{}.obs;
  var selectedDay = 'Monday'.obs;
  var schoolId;
  RxList<String> days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"].obs;


  @override
  void onInit() {
    super.onInit();
    final arguments = Get.arguments as List<dynamic>?;
    if (arguments == null || arguments.length < 2) {
      Get.snackbar('Error', 'Missing required arguments');
      return;
    }
    schoolId = arguments[0] as String;
    student = arguments[1] as Student;
    refreshData();
  }


  void fetchTimetable() async {
    try {
        Map<String, dynamic> fetchedTimetable =
          await Database_Service.fetchTimetable(schoolId, student.classSection, selectedDay.value);
      timetable.value = fetchedTimetable;
    } catch (e) {
      print("Error fetching timetable: $e");
      Get.snackbar("Error", "Failed to fetch timetable. Please try again later.");
    }
  }

  Future<void> refreshData() async {
    fetchTimetable();
  }
}



class ViewTimetable extends StatelessWidget {
  final ViewTimetableController controller = Get.put(ViewTimetableController());

  @override
  Widget build(BuildContext context) {
    controller.refreshData();

    return RefreshIndicator(
      onRefresh: controller.refreshData,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text("Manage Timetable", style: Font_Styles.labelHeadingLight(context)),
          backgroundColor: Colors.white,
          elevation: 0,
          // leading: IconButton(
          //   icon: const Icon(Icons.arrow_back),
          //   onPressed: () {
          //     Get.back();
          //   },
          // ),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(30, 10, 30, 20),
                child: Obx(() {
                  if (controller.days.isEmpty) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.appOrange,
                        ),
                      ),
                    );
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: controller.selectedDay.value,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.appOrange, width: 2.0),
                      ),
                    ),
                    items: controller.days.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        controller.selectedDay.value = newValue;
                        controller.fetchTimetable();
                      }
                    },
                  );
                }),
              ),
              Obx(() {
                if (controller.timetable.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                    child: Center(
                      child: Text(
                        'No timetable found for the selected class and day',
                        style: Font_Styles.labelHeadingRegular(context),
                      ),
                    ),
                  );
                }
      
                var timetableForClass = controller.timetable.value;
        
                var sortedEntries = timetableForClass.entries.toList()
                    ..sort((a, b) {
                      try {
                        var startTimeA = _extractStartTime(a.value);
                        var startTimeB = _extractStartTime(b.value);
                        return startTimeA.compareTo(startTimeB);
                      } catch (e) {
                        print('Error sorting timetable entries: $e');
                        return 0; // Keep original order if sorting fails
                      }
                    });
      
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 80,
                    showCheckboxColumn: false,
                    showBottomBorder: true,
                    columns: <DataColumn>[
                      DataColumn(
                        label: Text(
                          'Subject',
                          style: Font_Styles.labelHeadingRegular(context),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Start Time',
                          style: Font_Styles.labelHeadingRegular(context),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'End Time',
                          style: Font_Styles.labelHeadingRegular(context),
                        ),
                      ),
                    ],
                    rows: sortedEntries.asMap().entries.map((entryMap) {
                      int index = entryMap.key;
                      var entry = entryMap.value;
                      try {
                        var subjectDetails = entry.value.split('-');
                        // Alternate row colors for better visibility
                        bool isEven = index % 2 == 0;
        
                        String startTimeDisplay = '';
                        try {
                          startTimeDisplay = _formatTime(_extractStartTime(subjectDetails[0]));
                        } catch (e) {
                          // If formatting fails, just show the raw time
                          startTimeDisplay = subjectDetails.isNotEmpty ? subjectDetails[0].trim() : '';
                        }
        
                        String endTimeDisplay = '';
                        try {
                          endTimeDisplay = subjectDetails.length > 1 ? subjectDetails[1].trim() : '';
                        } catch (e) {
                          endTimeDisplay = '';
                        }
        
                        return DataRow(
                          color: WidgetStateColor.resolveWith(
                              (states) => isEven ? AppColors.appLightBlue : Colors.white),
                          cells: [
                            DataCell(Text(
                              entry.key,
                              style: TextStyle(color: Colors.black),
                            )),
                            DataCell(Text(
                              startTimeDisplay,
                              style: TextStyle(color: Colors.black),
                            )),
                            DataCell(Text(
                              endTimeDisplay,
                              style: TextStyle(color: Colors.black),
                            )),
                          ],
                        );
                      } catch (e) {
                        print('Error rendering timetable row: $e');
                        // Return a safe row even if there's an error
                        return DataRow(
                          cells: [
                            DataCell(Text(entry.key, style: TextStyle(color: Colors.black))),
                            DataCell(Text('Error', style: TextStyle(color: Colors.red))),
                            DataCell(Text('Error', style: TextStyle(color: Colors.red))),
                          ],
                        );
                      }
                    }).toList(),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  DateTime _extractStartTime(String subjectDetail) {
    try {
      var startTime = subjectDetail.split(' - ')[0].trim(); 
      return _convertTimeToDateTime(startTime); 
    } catch (e) {
      print('Error extracting start time from: $subjectDetail - $e');
      // Return a default time if parsing fails
      return DateTime(2000, 1, 1, 0, 0);
    }
  }

  String _formatTime(DateTime dateTime) {
    final format = DateFormat('h:mm a');
    return format.format(dateTime); 
  }

  DateTime _convertTimeToDateTime(String timeString) {
    try {
      // Try 24-hour format first (HH:mm)
      try {
        final format24 = DateFormat('HH:mm');
        return format24.parse(timeString);
      } catch (e) {
        // If 24-hour fails, try 12-hour format with AM/PM (h:mm a)
        try {
          final format12 = DateFormat('h:mm a');
          return format12.parse(timeString);
        } catch (e2) {
          // If both fail, try 12-hour format without AM/PM (h:mm)
          try {
            final format12NoAmPm = DateFormat('h:mm');
            return format12NoAmPm.parse(timeString);
          } catch (e3) {
            // Last resort: try to parse as simple time format
            final parts = timeString.split(':');
            if (parts.length == 2) {
              final hour = int.tryParse(parts[0]) ?? 0;
              final minute = int.tryParse(parts[1]) ?? 0;
              return DateTime(2000, 1, 1, hour, minute);
            }
            throw FormatException('Unable to parse time: $timeString');
          }
        }
      }
    } catch (e) {
      print('Error converting time string "$timeString": $e');
      // Return a default time if all parsing fails
      return DateTime(2000, 1, 1, 0, 0);
    }
  }
}
