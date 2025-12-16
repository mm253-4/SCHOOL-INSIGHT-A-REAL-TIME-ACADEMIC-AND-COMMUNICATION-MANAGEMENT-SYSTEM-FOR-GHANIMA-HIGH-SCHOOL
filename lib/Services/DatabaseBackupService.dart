import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'DatabaseHelper.dart';

class DatabaseBackupService {
  // Get the database file path
  static Future<String> getDatabasePath() async {
    String path = join(await getDatabasesPath(), 'classinsight.db');
    return path;
  }

  // Export database to a file that can be shared
  static Future<String?> exportDatabase() async {
    try {
      final sourcePath = await getDatabasePath();
      final sourceFile = File(sourcePath);
      
      if (!await sourceFile.exists()) {
        Get.snackbar('Error', 'Database file not found');
        return null;
      }
      
      // Use app documents directory for backup
      final appDir = await getApplicationDocumentsDirectory();
      final backupPath = join(appDir.path, 'classinsight_backup_${DateTime.now().millisecondsSinceEpoch}.db');
      await sourceFile.copy(backupPath);
      
      return backupPath;
    } catch (e) {
      print('Error exporting database: $e');
      Get.snackbar('Error', 'Failed to export database: ${e.toString()}');
      return null;
    }
  }

  // Import database from a file path
  static Future<bool> importDatabase(String sourceFilePath) async {
    try {
      final sourceFile = File(sourceFilePath);
      if (!await sourceFile.exists()) {
        Get.snackbar('Error', 'Backup file not found');
        return false;
      }
      
      // Close database connection if open
      try {
        final dbHelper = DatabaseHelper();
        await dbHelper.closeDatabase();
      } catch (e) {
        print('Error closing database: $e');
      }
      
      final targetPath = await getDatabasePath();
      final targetFile = File(targetPath);
      
      // Backup current database first
      if (await targetFile.exists()) {
        final backupPath = '${targetPath}.backup_${DateTime.now().millisecondsSinceEpoch}';
        await targetFile.copy(backupPath);
      }
      
      // Copy imported database
      await sourceFile.copy(targetPath);
      
      // Wait a moment before showing success message
      await Future.delayed(Duration(milliseconds: 500));
      
      Get.snackbar(
        'Success', 
        'Database imported successfully!\nPlease close and restart the app completely.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 5),
      );
      return true;
    } catch (e) {
      print('Error importing database: $e');
      Get.snackbar('Error', 'Failed to import database: ${e.toString()}',
          backgroundColor: Colors.red, colorText: Colors.white);
      // Try to reopen database if it was closed
      try {
        await DatabaseHelper().database;
      } catch (_) {}
      return false;
    }
  }

  // Get database file size for display
  static Future<String> getDatabaseSize() async {
    try {
      final dbPath = await getDatabasePath();
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        final size = await dbFile.length();
        if (size < 1024) {
          return '${size}B';
        } else if (size < 1024 * 1024) {
          return '${(size / 1024).toStringAsFixed(2)} KB';
        } else {
          return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
        }
      }
      return '0 B';
    } catch (e) {
      return 'Unknown';
    }
  }
}

