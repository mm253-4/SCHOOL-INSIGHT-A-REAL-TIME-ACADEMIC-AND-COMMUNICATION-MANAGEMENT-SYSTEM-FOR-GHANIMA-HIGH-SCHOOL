// ignore_for_file: prefer_const_constructors

import 'package:classinsight/Services/Database_Service.dart';
import 'package:classinsight/models/PaymentModel.dart';
import 'package:classinsight/models/SchoolModel.dart';
import 'package:classinsight/models/StudentModel.dart';
import 'package:classinsight/utils/AppColors.dart';
import 'package:classinsight/utils/fontStyles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class StudentPaymentController extends GetxController {
  final Student student;
  final School school;
  
  Rx<Map<String, double>> paymentInfo = Rx<Map<String, double>>({
    'paidAmount': 0.0,
    'balanceAmount': 40000.0,
    'feePerTerm': 40000.0,
  });
  
  RxList<Payment> paymentHistory = <Payment>[].obs;
  RxBool isLoading = true.obs;
  
  StudentPaymentController(this.student, this.school);

  @override
  void onInit() {
    super.onInit();
    fetchPaymentInfo();
  }

  Future<void> fetchPaymentInfo() async {
    isLoading.value = true;
    try {
      final info = await Database_Service.getStudentPaymentInfo(
        school.schoolId,
        student.studentID,
      );
      paymentInfo.value = info;
      
      final history = await Database_Service.getPaymentHistory(
        school.schoolId,
        student.studentID,
      );
      paymentHistory.assignAll(history);
    } catch (e) {
      print('Error fetching payment info: $e');
    } finally {
      isLoading.value = false;
    }
  }
}

class StudentPaymentScreen extends StatelessWidget {
  final StudentPaymentController controller;

  StudentPaymentScreen({Key? key}) 
      : controller = Get.put(StudentPaymentController(
          Get.arguments[0] as Student,
          Get.arguments[1] as School,
        )),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.appLightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.appLightBlue,
        title: Text('Payment Info', style: Font_Styles.labelHeadingLight(context)),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Payment Summary Card
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fee Summary',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 15),
                      _buildInfoRow('Fee Per Term:', 
                          'KES ${controller.paymentInfo.value['feePerTerm']!.toStringAsFixed(2)}'),
                      SizedBox(height: 10),
                      _buildInfoRow('Paid Amount:', 
                          'KES ${controller.paymentInfo.value['paidAmount']!.toStringAsFixed(2)}',
                          color: Colors.green),
                      SizedBox(height: 10),
                      _buildInfoRow('Balance:', 
                          'KES ${controller.paymentInfo.value['balanceAmount']!.toStringAsFixed(2)}',
                          color: Colors.red),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                
                // Payment History
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment History',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 15),
                      Obx(() {
                        if (controller.paymentHistory.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text('No payment history'),
                            ),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: controller.paymentHistory.length,
                          itemBuilder: (context, index) {
                            final payment = controller.paymentHistory[index];
                            return Card(
                              margin: EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                title: Text('KES ${payment.amount.toStringAsFixed(2)}'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${payment.paymentMethod} - ${payment.term ?? ""}'),
                                    if (payment.mpesaReceiptNumber != null)
                                      Text('Receipt: ${payment.mpesaReceiptNumber}'),
                                    Text(_formatDate(payment.paymentDate)),
                                  ],
                                ),
                                trailing: Chip(
                                  label: Text(payment.status),
                                  backgroundColor: payment.status == 'completed' 
                                      ? Colors.green 
                                      : Colors.orange,
                                ),
                              ),
                            );
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 16)),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black,
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}

