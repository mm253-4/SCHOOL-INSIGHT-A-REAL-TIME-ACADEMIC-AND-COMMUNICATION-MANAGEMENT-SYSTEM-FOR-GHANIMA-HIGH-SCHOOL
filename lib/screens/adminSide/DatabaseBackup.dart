import 'dart:io';
import 'package:classinsight/Services/DatabaseBackupService.dart';
import 'package:classinsight/utils/AppColors.dart';
import 'package:classinsight/utils/fontStyles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseBackupController extends GetxController {
  RxBool isExporting = false.obs;
  RxBool isImporting = false.obs;
  RxString databaseSize = 'Calculating...'.obs;
  
  @override
  void onInit() {
    super.onInit();
    loadDatabaseSize();
  }
  
  Future<void> loadDatabaseSize() async {
    final size = await DatabaseBackupService.getDatabaseSize();
    databaseSize.value = size;
  }
  
  Future<void> exportDatabase() async {
    isExporting.value = true;
    try {
      final backupPath = await DatabaseBackupService.exportDatabase();
      if (backupPath != null) {
        final file = File(backupPath);
        if (await file.exists()) {
          // Share the file
          await Share.shareXFiles(
            [XFile(backupPath)],
            text: 'ClassInsight Database Backup',
            subject: 'Database Backup - ${DateTime.now().toString().split(' ')[0]}',
          );
          Get.snackbar(
            'Success',
            'Database exported successfully! You can share it to transfer to another device.',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: Duration(seconds: 3),
          );
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to export database: ${e.toString()}',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isExporting.value = false;
      await loadDatabaseSize();
    }
  }
  
  Future<void> importDatabase() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
        dialogTitle: 'Select Database Backup File',
      );
      
      if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
        isImporting.value = true;
        
        // Show confirmation dialog
        final confirm = await Get.dialog<bool>(
          AlertDialog(
            title: Text('Import Database'),
            content: Text(
              'This will replace your current database with the backup file. '
              'All current data will be lost. Are you sure you want to continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                child: Text('Import', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        
        if (confirm == true) {
          final success = await DatabaseBackupService.importDatabase(result.files.single.path!);
          if (success) {
            Get.snackbar(
              'Success',
              'Database imported successfully! Please restart the app.',
              backgroundColor: Colors.green,
              colorText: Colors.white,
              duration: Duration(seconds: 5),
            );
            await loadDatabaseSize();
          }
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to import database: ${e.toString()}',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isImporting.value = false;
    }
  }
}

class DatabaseBackupScreen extends StatelessWidget {
  DatabaseBackupScreen({Key? key}) : super(key: key);
  
  final DatabaseBackupController controller = Get.put(DatabaseBackupController());
  
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: AppColors.appLightBlue,
      appBar: AppBar(
        backgroundColor: AppColors.appLightBlue,
        title: Text('Database Backup & Restore', style: Font_Styles.labelHeadingLight(context)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 10),
              
              // Info Card
              Container(
                padding: EdgeInsets.all(15),
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
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.appDarkBlue),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Database Information',
                            style: Font_Styles.mediumHeadingBold(context),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Obx(() => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Database Size:',
                            style: Font_Styles.labelHeadingRegular(context),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            controller.databaseSize.value,
                            style: TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    )),
                    SizedBox(height: 8),
                    Text(
                      'Use this feature to backup your database from the emulator and restore it on your physical device, or vice versa.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 15),
              
              // Export Button
              Obx(() => Container(
                padding: EdgeInsets.all(15),
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
                    Row(
                      children: [
                        Icon(Icons.upload_file, color: Colors.green, size: 30),
                        SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Export Database',
                                style: Font_Styles.mediumHeadingBold(context),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Create a backup of your current database',
                                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.isExporting.value ? null : controller.exportDatabase,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: controller.isExporting.value
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      'Exporting...',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.file_download),
                                  SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      'Export Database',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              )),
              
              SizedBox(height: 15),
              
              // Import Button
              Obx(() => Container(
                padding: EdgeInsets.all(15),
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
                    Row(
                      children: [
                        Icon(Icons.download, color: Colors.blue, size: 30),
                        SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Import Database',
                                style: Font_Styles.mediumHeadingBold(context),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Restore database from a backup file',
                                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.isImporting.value ? null : controller.importDatabase,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: controller.isImporting.value
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      'Importing...',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.file_upload),
                                  SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      'Import Database',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              )),
              
              SizedBox(height: 15),
              
              // Instructions
              Container(
                margin: EdgeInsets.only(bottom: 10),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.help_outline, color: Colors.blue[700]),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'How to Transfer Data',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. On your emulator: Tap "Export Database" and share/save the file\n'
                      '2. Transfer the file to your physical device (via email, USB, etc.)\n'
                      '3. On your physical device: Tap "Import Database" and select the backup file\n'
                      '4. Restart the app after importing',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

