import 'package:classinsight/Services/Database_Service.dart';
import 'package:classinsight/screens/adminSide/AdminHome.dart';
import 'package:classinsight/utils/AppColors.dart';
import 'package:classinsight/utils/fontStyles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AddTimetableController extends GetxController {
  RxList<String> formats = ["Fixed Schedule", "Changed everyday"].obs;
  RxList<String> classes = <String>[].obs;
  RxList<String> subjects = <String>[].obs;
  RxString selectedFormat = "".obs;
  RxString selectedClass = "".obs;
  RxBool isSaturdayOn = false.obs;

  RxMap<String, RxMap<String, String>> startTimes = RxMap();
  RxMap<String, RxMap<String, String>> endTimes = RxMap();

  RxBool get isSaveEnabled => RxBool(
        startTimes.isNotEmpty &&
        endTimes.isNotEmpty &&
        startTimes.values.every((dayMap) => dayMap.isNotEmpty) &&
        endTimes.values.every((dayMap) => dayMap.isNotEmpty),
      );

  AdminHomeController school = Get.put(AdminHomeController());

  @override
  void onInit() {
    super.onInit();
    fetchClasses();
  }

  void fetchClasses() async {
    classes.value = await Database_Service.fetchAllClassesbyTimetable(school.schoolId.value,false);
    update();
  }

  Future<void> fetchSubjects(String selectedClass) async {
    subjects.value = await Database_Service.fetchSubjects(school.schoolId.value, selectedClass);
    subjects.add("Break Time"); 
  }
}

class AddTimetable extends StatelessWidget {
  final AddTimetableController controller = Get.put(AddTimetableController());

  Future<void> saveTimetable() async {
    Map<String, Map<String, String>> timetableData = {};

    controller.subjects.forEach((subject) {
      controller.startTimes.forEach((dayLabel, startTimesMap) {
        if (dayLabel == "Monday - Thursday") {

          List<String> days = ["Monday", "Tuesday", "Wednesday", "Thursday"];

          for (String day in days) {
            String startTime = startTimesMap[subject] ?? '';
            String endTime = controller.endTimes[dayLabel]?[subject] ?? '';

            if (startTime.isNotEmpty && endTime.isNotEmpty) {
              if (!timetableData.containsKey(day)) {
                timetableData[day] = {};
              }
              timetableData[day]![subject] = '$startTime - $endTime';
            }
          }
        } else {
          String startTime = startTimesMap[subject] ?? '';
          String endTime = controller.endTimes[dayLabel]?[subject] ?? '';

          if (startTime.isNotEmpty && endTime.isNotEmpty) {
            if (!timetableData.containsKey(dayLabel)) {
              timetableData[dayLabel] = {};
            }
            timetableData[dayLabel]![subject] = '$startTime - $endTime';
          }
        }
      });
    });

    await Database_Service.addTimetablebyClass(
      controller.school.schoolId.value,
      controller.selectedClass.value,
      controller.selectedFormat.value,
      timetableData,
    );

    Get.back(result: 'updated');

    controller.startTimes.clear();
    controller.endTimes.clear();

  }

  // Convert time string to minutes since midnight for comparison
  int _timeToMinutes(String timeString) {
    try {
      // Handle formats like "7:30 AM", "8:10 PM", etc.
      final format = DateFormat('h:mm a');
      final dateTime = format.parse(timeString);
      return dateTime.hour * 60 + dateTime.minute;
    } catch (e) {
      // Try 24-hour format
      try {
        final parts = timeString.split(':');
        if (parts.length >= 2) {
          int hours = int.tryParse(parts[0]) ?? 0;
          int minutes = int.tryParse(parts[1].split(' ')[0]) ?? 0;
          return hours * 60 + minutes;
        }
      } catch (e2) {
        print('Error parsing time: $timeString');
      }
      return 0;
    }
  }

  // Get sorted subjects for a day based on their start times
  List<String> _getSortedSubjectsForDay(String dayLabel) {
    RxMap<String, String>? startTimesMap = controller.startTimes[dayLabel];
    if (startTimesMap == null || startTimesMap.isEmpty) {
      return List.from(controller.subjects);
    }

    // Create a list of subjects with their times
    List<MapEntry<String, int>> subjectsWithTimes = [];
    
    for (String subject in controller.subjects) {
      String? startTime = startTimesMap[subject];
      if (startTime != null && startTime.isNotEmpty && startTime != 'Start Time') {
        int minutes = _timeToMinutes(startTime);
        subjectsWithTimes.add(MapEntry(subject, minutes));
      } else {
        // Subjects without times go to the end
        subjectsWithTimes.add(MapEntry(subject, 9999));
      }
    }

    // Sort by time
    subjectsWithTimes.sort((a, b) => a.value.compareTo(b.value));

    return subjectsWithTimes.map((e) => e.key).toList();
  }

  // Check if a time is already in use by another subject
  // Note: A time used as an end time can be reused as a start time (and vice versa) - this is normal
  bool _isTimeAlreadyUsed(String dayLabel, String formattedTime, String currentSubject, bool isStartTime) {
    RxMap<String, String>? startTimesMap = controller.startTimes[dayLabel];
    RxMap<String, String>? endTimesMap = controller.endTimes[dayLabel];
    
    if (startTimesMap == null && endTimesMap == null) {
      return false;
    }
    
    int selectedMinutes = _timeToMinutes(formattedTime);
    
    // If setting a START time: check if that time is already used as a START time by another subject
    if (isStartTime && startTimesMap != null) {
      for (String subject in startTimesMap.keys) {
        if (subject != currentSubject) {
          String? startTime = startTimesMap[subject];
          if (startTime != null && startTime.isNotEmpty && startTime != 'Start Time') {
            int startMinutes = _timeToMinutes(startTime);
            if (startMinutes == selectedMinutes) {
              return true; // This start time is already used by another subject
            }
          }
        }
      }
    }
    
    // If setting an END time: check if that time is already used as an END time by another subject
    if (!isStartTime && endTimesMap != null) {
      for (String subject in endTimesMap.keys) {
        if (subject != currentSubject) {
          String? endTime = endTimesMap[subject];
          if (endTime != null && endTime.isNotEmpty && endTime != 'End Time') {
            int endMinutes = _timeToMinutes(endTime);
            if (endMinutes == selectedMinutes) {
              return true; // This end time is already used by another subject
            }
          }
        }
      }
    }
    
    // Check for overlapping time ranges (but allow exact matches at boundaries)
    if (startTimesMap != null && endTimesMap != null) {
      for (String otherSubject in startTimesMap.keys) {
        if (otherSubject != currentSubject) {
          String? otherStartTime = startTimesMap[otherSubject];
          String? otherEndTime = endTimesMap[otherSubject];
          
          if (otherStartTime != null && otherStartTime.isNotEmpty && otherStartTime != 'Start Time' &&
              otherEndTime != null && otherEndTime.isNotEmpty && otherEndTime != 'End Time') {
            int otherStartMinutes = _timeToMinutes(otherStartTime);
            int otherEndMinutes = _timeToMinutes(otherEndTime);
            
            // Check if selected time falls within another subject's time range
            // But allow exact matches at boundaries (start time can match end time)
            if (isStartTime) {
              // For start time: allow if it matches the end time of another subject, but not if it's inside the range
              if (selectedMinutes > otherStartMinutes && selectedMinutes < otherEndMinutes) {
                return true; // Time overlaps with another subject's range
              }
            } else {
              // For end time: allow if it matches the start time of another subject, but not if it's inside the range
              if (selectedMinutes > otherStartMinutes && selectedMinutes < otherEndMinutes) {
                return true; // Time overlaps with another subject's range
              }
            }
          }
        }
      }
    }
    
    return false;
  }

  Future<void> _selectTime(BuildContext context, RxMap<String, String> timeMap, String subject, bool isStartTime, String dayLabel) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      String formattedTime = picked.format(context);
      
      // Check if this time is already used by another subject
      if (_isTimeAlreadyUsed(dayLabel, formattedTime, subject, isStartTime)) {
        Get.snackbar(
          'Time Already Used',
          'This time is already set for another subject. Please choose a different time.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: Duration(seconds: 3),
        );
        return; // Don't set the time if it's already used
      }
      
      // Simply set the time - no automatic setting
      timeMap[subject] = formattedTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Add timetable",
          style: Font_Styles.labelHeadingRegular(context),
        ),
        actions: [
          Obx(
            () => TextButton(
              onPressed: controller.isSaveEnabled.value
                  ? ()async {
                      await saveTimetable();
                      
                      
                    }
                  : null,
              child: Text(
                "Save",
                style: Font_Styles.labelHeadingRegular(context),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.1),
          child: Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                    Container(
                      width: screenWidth * 0.7,
                      padding: EdgeInsets.only(right: screenWidth * 0.1),
                      child: Obx(
                        () => DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            hintText: "Select the class",
                            labelText: "Class",
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(
                                color: AppColors.appOrange,
                                width: 1.0,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(
                                color: Colors.black,
                                width: 1.0,
                              ),
                            ),
                          ),
                          initialValue: controller.selectedClass.value.isEmpty ? null : controller.selectedClass.value,
                          onChanged: (newValue) async {
                            controller.selectedClass.value = newValue!;
                            await controller.fetchSubjects(newValue); // Fetch subjects for selected class
                          },
                          items: controller.classes.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    SizedBox(height: 20,),
                    Container(
                      width: screenWidth * 0.7,
                      child: Obx(
                        () => DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            hintText: "Select the format",
                            labelText: "Format",
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(
                                color: AppColors.appOrange,
                                width: 2.0,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(
                                color: Colors.black,
                                width: 1.0,
                              ),
                            ),
                          ),
                          initialValue: controller.selectedFormat.value.isEmpty ? null : controller.selectedFormat.value,
                          onChanged: (newValue) {
                            controller.selectedFormat.value = newValue!;
                          },
                          items: controller.formats.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Saturday On/Off"),
                    Obx(() => Switch.adaptive(
                      value: controller.isSaturdayOn.value,
                      onChanged: (value) {
                        controller.isSaturdayOn.value = value;
                      },
                    )),
                  ],
                ),

                if (controller.selectedFormat.value == "Fixed Schedule")
                  Obx(()=>
                     Column(
                      children: [
                        _buildDayTable("Monday - Thursday", context),
                        _buildDayTable("Friday", context),
                        controller.isSaturdayOn.value ? _buildDayTable("Saturday", context) : Container()
                      ],
                    ),
                  ),
                if (controller.selectedFormat.value == "Changed everyday")
                  Obx(()=>
                     Column(
                      children: [
                        _buildDayTable("Monday", context),
                        _buildDayTable("Tuesday", context),
                        _buildDayTable("Wednesday", context),
                        _buildDayTable("Thursday", context),
                        _buildDayTable("Friday", context),
                        controller.isSaturdayOn.value ? _buildDayTable("Saturday", context) : Container()
                    
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayTable(String dayLabel, BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dayLabel, style: Font_Styles.mediumHeadingBold(context)),
          Obx(() {
            // Get sorted subjects based on their start times for this day
            List<String> sortedSubjects = _getSortedSubjectsForDay(dayLabel);
            
            return DataTable(
              columns: [
                DataColumn(
                  label: Text(
                    'Sr No.',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: MediaQuery.of(context).size.width * 0.03,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Subject/Break Time',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: MediaQuery.of(context).size.width * 0.03,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Time',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: MediaQuery.of(context).size.width * 0.03,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              rows: List.generate(sortedSubjects.length, (index) {
                String subject = sortedSubjects[index];
                return DataRow(
                  cells: [
                    DataCell(Text((index + 1).toString(), style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.03))),
                    DataCell(
                      Text(
                        subject,
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.03,
                          color: subject == "Break Time" ? AppColors.appOrange : Colors.black, // Special color for "Break Time"
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () async {
                                await _selectTime(context, controller.startTimes.putIfAbsent(dayLabel, () => RxMap()), subject, true, dayLabel);
                              },
                              child: Obx(
                                () => Text(
                                  controller.startTimes[dayLabel]?[subject] ?? 'Start Time',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextButton(
                              onPressed: () async {
                                await _selectTime(context, controller.endTimes.putIfAbsent(dayLabel, () => RxMap()), subject, false, dayLabel);
                              },
                              child: Obx(
                                () => Text(
                                  controller.endTimes[dayLabel]?[subject] ?? 'End Time',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            );
          }),
        ],
      ),
    );
  }
}
