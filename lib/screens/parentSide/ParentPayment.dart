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

class ParentPaymentController extends GetxController {
  final Student student;
  final School school;
  
  Rx<Map<String, double>> paymentInfo = Rx<Map<String, double>>({
    'paidAmount': 0.0,
    'balanceAmount': 40000.0,
    'feePerTerm': 40000.0,
  });
  
  RxList<Payment> paymentHistory = <Payment>[].obs;
  RxBool isLoading = true.obs;
  
  final TextEditingController amountController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController mpesaReceiptController = TextEditingController();
  var selectedTerm = 'Term 1'.obs;
  
  ParentPaymentController(this.student, this.school);

  @override
  void onInit() {
    super.onInit();
    fetchPaymentInfo();
    // Pre-fill phone with father's phone
    phoneController.text = student.fatherPhoneNo;
  }

  @override
  void onClose() {
    amountController.dispose();
    phoneController.dispose();
    mpesaReceiptController.dispose();
    super.onClose();
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

  Future<void> processMpesaPayment() async {
    if (amountController.text.isEmpty) {
      Get.snackbar('Error', 'Please enter payment amount',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    final amount = double.tryParse(amountController.text);
    if (amount == null || amount <= 0) {
      Get.snackbar('Error', 'Please enter a valid amount',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    if (amount > paymentInfo.value['balanceAmount']!) {
      Get.snackbar('Error', 'Payment amount cannot exceed balance',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    if (phoneController.text.isEmpty) {
      Get.snackbar('Error', 'Please enter M-PESA phone number',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    // Show loading
    Get.dialog(
      Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      await Database_Service.processPayment(
        schoolId: school.schoolId,
        studentId: student.studentID,
        amount: amount,
        paymentMethod: 'M-PESA',
        mpesaReceiptNumber: null,
        term: selectedTerm.value,
      );

      Get.back(); // Close loading dialog
      Get.snackbar('Success', 'Payment processed successfully',
          backgroundColor: Colors.green, colorText: Colors.white);
      
      // Clear fields
      amountController.clear();
      
      // Refresh payment info
      await fetchPaymentInfo();
    } catch (e) {
      Get.back(); // Close loading dialog
      Get.snackbar('Error', 'Failed to process payment: ${e.toString()}',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}

class ParentPaymentScreen extends StatelessWidget {
  final ParentPaymentController controller;

  ParentPaymentScreen({Key? key}) 
      : controller = Get.put(ParentPaymentController(
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
        title: Text('Make Payment', style: Font_Styles.labelHeadingLight(context)),
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
                
                // M-PESA Payment Form
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
                        'Pay via M-PESA',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
                      
                      // Term Selection
                      Text('Select Term:', style: Font_Styles.labelHeadingRegular(context)),
                      SizedBox(height: 8),
                      Obx(() => DropdownButtonFormField<String>(
                        value: controller.selectedTerm.value,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        ),
                        items: ['Term 1', 'Term 2', 'Term 3'].map((term) {
                          return DropdownMenuItem(value: term, child: Text(term));
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            controller.selectedTerm.value = value;
                          }
                        },
                      )),
                      SizedBox(height: 15),
                      
                      // Amount
                      Text('Amount (KES):', style: Font_Styles.labelHeadingRegular(context)),
                      SizedBox(height: 8),
                      TextField(
                        controller: controller.amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Enter amount',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        ),
                      ),
                      SizedBox(height: 15),
                      
                      // Phone Number
                      Text('M-PESA Phone Number:', style: Font_Styles.labelHeadingRegular(context)),
                      SizedBox(height: 8),
                      TextField(
                        controller: controller.phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: '+254 712345678',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        ),
                      ),
                      SizedBox(height: 20),
                      
                      // Pay Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: controller.processMpesaPayment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.appPink,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Pay via M-PESA',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
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

