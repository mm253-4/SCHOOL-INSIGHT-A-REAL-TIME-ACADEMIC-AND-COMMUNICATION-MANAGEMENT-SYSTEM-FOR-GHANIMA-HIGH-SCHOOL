import 'package:classinsight/bindings.dart';
import 'package:classinsight/routes/mainRoutes.dart';
import 'package:classinsight/Services/DatabaseHelper.dart';
import 'package:classinsight/Services/Database_Service.dart';
import 'package:classinsight/utils/AppColors.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'Services/NotificationService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize critical services
  try {
    await GetStorage.init();
  } catch (e) {
    print('Error initializing GetStorage: $e');
  }
  
  // Firebase (optional, works after you add google-services files)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Firebase init skipped/failed (add google-services.json/GoogleService-Info.plist to enable): $e');
  }
  // Notifications
  try {
    await NotificationService.initialize();
    await NotificationService.requestPermissions();
    NotificationService.bindFirebaseMessagingHandlers();
    // Example: subscribe general announcements
    await NotificationService.subscribeToRoleTopic('general');
  } catch (e) {
    print('Notification setup error: $e');
  }
  
  // Initialize database in background (non-blocking)
  DatabaseHelper().database.then((_) async {
    print('Database initialized successfully');
    
      // Remove duplicate schools first
      try {
        await Database_Service.removeDuplicateSchools();
      } catch (e) {
        print('Error removing duplicates: $e');
      }
    
      // Ensure default school exists and has correct name
      try {
        final dbHelper = DatabaseHelper();
        final db = await dbHelper.database;
        final schools = await db.query('Schools', where: 'schoolId = ?', whereArgs: ['ghanima_girls_high_001']);
        
        if (schools.isEmpty) {
          await db.insert(
            'Schools',
            {
              'schoolId': 'ghanima_girls_high_001',
              'schoolName': 'Ghanima Girls High School',
              'adminEmail': 'admin@ghanimagirls.ac.ke',
              'adminPassword': 'admin123',
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          print('Default school added: Ghanima Girls High School');
        } else {
          // Update school name if it has the old name
          final existingSchool = schools.first;
          if (existingSchool['schoolName'] != 'Ghanima Girls High School') {
            await db.update(
              'Schools',
              {'schoolName': 'Ghanima Girls High School'},
              where: 'schoolId = ?',
              whereArgs: ['ghanima_girls_high_001'],
            );
            print('School name updated to: Ghanima Girls High School');
          }
        }
    } catch (e) {
      print('Error checking/adding default school: $e');
    }
  }).catchError((e) {
    print('Error initializing database: $e');
  });
  
  // Load .env file (non-blocking, optional)
  dotenv.load(fileName: ".env").catchError((e) {
    print('Note: .env file not found. Email functionality may not work.');
  });
  
  InitialBinding().dependencies();
  
  // Run app immediately - don't wait for database
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isTeacherLogged = false;
  bool isParentLogged = false;
  bool isAdminLogged = false;

  @override
  void initState() {
    super.initState();
    final storage = GetStorage();
    isTeacherLogged = storage.read('isTeacherLogged') ?? false;
    isParentLogged = storage.read('isParentLogged') ?? false;
    isAdminLogged = storage.read('isAdminLogged') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      initialBinding: InitialBinding(),
      title: 'Ghanima Girls High School',
      color: Colors.white,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.backgroundLight,
        canvasColor: Colors.white,
        brightness: Brightness.light,
        primaryColor: AppColors.primaryColor,
        colorScheme: ColorScheme.light(
          primary: AppColors.primaryColor,
          secondary: AppColors.secondaryColor,
          surface: Colors.white,
          error: AppColors.errorColor,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: AppColors.textPrimary,
        ),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme).copyWith(
          displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          displayMedium: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          displaySmall: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          headlineMedium: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          bodyLarge: GoogleFonts.inter(fontSize: 16, color: AppColors.textPrimary),
          bodyMedium: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
        ),
        appBarTheme: AppBarTheme(
          scrolledUnderElevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.borderRadiusLarge),
            side: BorderSide(color: AppColors.borderColor, width: 1),
          ),
          color: Colors.white,
          shadowColor: Colors.black.withOpacity(0.05),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppColors.borderRadiusMedium),
            borderSide: const BorderSide(color: AppColors.borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppColors.borderRadiusMedium),
            borderSide: BorderSide(color: AppColors.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppColors.borderRadiusMedium),
            borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppColors.borderRadiusMedium),
            borderSide: BorderSide(color: AppColors.errorColor),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppColors.borderRadiusMedium),
            borderSide: BorderSide(color: AppColors.errorColor, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: AppColors.spacingMD, vertical: AppColors.spacingMD),
        ),
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
        useMaterial3: true,
      ),
      initialRoute: _getInitialLocation(),
      getPages: MainRoutes.routes,
    );
  }

  String _getInitialLocation() {
    // Always start with splash screen for professional welcoming experience
    // The splash screen will handle navigation based on login status
    return '/splash';
  }
}
