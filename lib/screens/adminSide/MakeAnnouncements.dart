import 'package:classinsight/Services/Database_Service.dart';
import 'package:classinsight/screens/adminSide/AdminHome.dart';
import 'package:classinsight/utils/AppColors.dart';
import 'package:classinsight/utils/fontStyles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MakeAnnouncementsController extends GetxController {
  TextEditingController announcementController = TextEditingController();
  TextEditingController timelineController = TextEditingController();
  AdminHomeController school = Get.put(AdminHomeController());

  var announcementValid = true.obs;
  var addStdFontSize = 16.0;
  var headingFontSize = 33.0;
  Rx<DateTime?> deadline = Rx<DateTime?>(null);

  @override
  void onClose() {
    announcementController.dispose();
    timelineController.dispose();
    super.onClose();
  }

  Future<void> selectDeadline(BuildContext context) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: deadline.value ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(deadline.value ?? now),
      );

      if (pickedTime != null) {
        deadline.value = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      }
    }
  }
}

class MakeAnnouncements extends StatelessWidget {
  MakeAnnouncements({Key? key}) : super(key: key);

  final MakeAnnouncementsController controller =
      Get.put(MakeAnnouncementsController());

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 350) {
      controller.addStdFontSize = 14.0;
      controller.headingFontSize = 27.0;
    }
    if (screenWidth < 300) {
      controller.addStdFontSize = 14.0;
      controller.headingFontSize = 24.0;
    }
    if (screenWidth < 250) {
      controller.addStdFontSize = 11.0;
      controller.headingFontSize = 20.0;
    }
    if (screenWidth < 230) {
      controller.addStdFontSize = 8.0;
      controller.headingFontSize = 15.0;
    }

    return Scaffold(
      backgroundColor: AppColors.appLightBlue,
      body: SingleChildScrollView(
        child: Container(
          height: screenHeight,
          width: screenWidth,
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: screenHeight * 0.10,
                  width: screenWidth,
                  child: AppBar(
                    backgroundColor: AppColors.appLightBlue,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        Get.back();
                      },
                    ),
                    actions: <Widget>[
                      Container(
                        width: 48.0,
                      ),
                      //  controller.announcementController.text.isNotEmpty? 
                       TextButton(
                        onPressed: () {
                          // Save the changes to the database

                          // Navigate back or show a success message
                          if (controller.announcementController.text.isEmpty) {
                            Get.snackbar(
                              'Empty Announcement',
                              'Please write an announcement before sending it.',
                            );
                            return;
                          }

                          if (controller.deadline.value == null) {
                            Get.snackbar(
                              'Missing Deadline',
                              'Please select a deadline for the announcement.',
                            );
                            return;
                          }

                          if (controller.timelineController.text.trim().isEmpty) {
                            Get.snackbar(
                              'Missing Timeline',
                              'Please provide a timeline for the announcement.',
                            );
                            return;
                          } else {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.appLightBlue),
                                  ),
                                );
                              },
                            );

                            Get.snackbar(
                              'Announcement Sent',
                              'The announement has been successfully sent to all the school.',
                            );

                            Database_Service.createAnnouncement(
                                controller.school.schoolId.value,
                                '',
                                controller.announcementController.text,
                                'Admin',
                                true,
                                deadline: controller.deadline.value,
                                timeline: controller.timelineController.text.trim(),
                              );

                            controller.announcementController.clear();
                            controller.timelineController.clear();
                            controller.deadline.value = null;

                            Navigator.of(context).pop();
                          }
                        },
                        child: Text(
                          "Send",
                          style: Font_Styles.labelHeadingLight(context,color: Colors.black),
                        ),
                      )
                      // : Container()
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, screenHeight * 0.18, 20, 0),
                  child: Center(
                    child: Text(
                      "Make Announcement",
                      style: Font_Styles.largeHeadingBold(context),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      screenWidth * 0.05, screenHeight * 0.03, screenWidth * 0.05, 0),
                  child: Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Deadline *',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 10),
                        Obx(
                          () => InkWell(
                            onTap: () => controller.selectDeadline(context),
                            child: Container(
                              padding: EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      color: AppColors.appDarkBlue),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      controller.deadline.value != null
                                          ? '${controller.deadline.value!.day}/${controller.deadline.value!.month}/${controller.deadline.value!.year} ${controller.deadline.value!.hour.toString().padLeft(2, '0')}:${controller.deadline.value!.minute.toString().padLeft(2, '0')}'
                                          : 'Select deadline date and time',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight:
                                            controller.deadline.value != null
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                        color: controller.deadline.value != null
                                            ? AppColors.textPrimary
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      screenWidth * 0.05, screenHeight * 0.03, screenWidth * 0.05, 0),
                  child: Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Timeline *',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: controller.timelineController,
                          decoration: InputDecoration(
                            hintText: 'e.g., Whole School Assembly • 9:00 AM - 10:00 AM',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: EdgeInsets.all(15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(screenWidth * 0.05,
                        screenHeight * 0.05, screenWidth * 0.05, 0),
                    child: Container(
                      // height: screenHeight * 0.3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              Colors.white, // Set the background color to white
                          borderRadius:
                              BorderRadius.circular(10), // Rounded corners
                        ),
                        child: TextField(
                          maxLength: 100,
                          maxLines: null,
                          minLines: 1,
                          controller: controller.announcementController,
                          decoration: InputDecoration(
                            hintText: 'Type your announcement here......',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none, // No visible border
                            ),
                            // contentPadding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                          ),
                          style: Font_Styles.dataTableRows(context,
                              MediaQuery.of(context).size.width * 0.05),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
