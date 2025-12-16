import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Close database connection (for backup/restore operations)
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<Database> _initDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'classinsight.db');
      return await openDatabase(
        path,
        version: 11, // Increment version to trigger onUpgrade
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      print('Error in _initDatabase: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      // Schools table
    await db.execute('''
      CREATE TABLE Schools (
        schoolId TEXT PRIMARY KEY,
        schoolName TEXT NOT NULL,
        adminName TEXT,
        adminId TEXT,
        adminEmail TEXT NOT NULL,
        adminPassword TEXT NOT NULL
      )
    ''');

    // Teachers table
    await db.execute('''
      CREATE TABLE Teachers (
        employeeId TEXT PRIMARY KEY,
        schoolId TEXT NOT NULL,
        name TEXT NOT NULL,
        gender TEXT NOT NULL,
        email TEXT NOT NULL,
        password TEXT NOT NULL,
        cnic TEXT NOT NULL,
        phoneNo TEXT NOT NULL,
        fatherName TEXT NOT NULL,
        classes TEXT NOT NULL,
        subjects TEXT NOT NULL,
        classTeacher TEXT NOT NULL,
        FOREIGN KEY (schoolId) REFERENCES Schools (schoolId)
      )
    ''');

    // Students table
    await db.execute('''
      CREATE TABLE Students (
        studentId TEXT PRIMARY KEY,
        schoolId TEXT NOT NULL,
        name TEXT NOT NULL,
        gender TEXT NOT NULL,
        bFormChallanId TEXT NOT NULL UNIQUE,
        fatherName TEXT NOT NULL,
        fatherPhoneNo TEXT NOT NULL,
        fatherCNIC TEXT NOT NULL,
        studentRollNo TEXT NOT NULL,
        classSection TEXT NOT NULL,
        feeStatus TEXT NOT NULL,
        feeStartDate TEXT,
        feeEndDate TEXT,
        resultMap TEXT,
        attendance TEXT,
        email TEXT,
        password TEXT,
        paidAmount REAL DEFAULT 0.0,
        balanceAmount REAL DEFAULT 40000.0,
        feePerTerm REAL DEFAULT 40000.0,
        FOREIGN KEY (schoolId) REFERENCES Schools (schoolId)
      )
    ''');

    // Payments table to track payment history
    await db.execute('''
      CREATE TABLE Payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId TEXT NOT NULL,
        schoolId TEXT NOT NULL,
        amount REAL NOT NULL,
        paymentMethod TEXT NOT NULL,
        transactionId TEXT,
        mpesaReceiptNumber TEXT,
        paymentDate TEXT NOT NULL,
        term TEXT,
        status TEXT NOT NULL,
        FOREIGN KEY (studentId) REFERENCES Students (studentId),
        FOREIGN KEY (schoolId) REFERENCES Schools (schoolId)
      )
    ''');

    // Add email and password columns if they don't exist (for existing databases)
    try {
      await db.execute('ALTER TABLE Students ADD COLUMN email TEXT');
    } catch (e) {
      // Column already exists, ignore
    }
    try {
      await db.execute('ALTER TABLE Students ADD COLUMN password TEXT');
    } catch (e) {
      // Column already exists, ignore
    }

    // Classes table
    await db.execute('''
      CREATE TABLE Classes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        schoolId TEXT NOT NULL,
        className TEXT NOT NULL,
        timetable INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (schoolId) REFERENCES Schools (schoolId),
        UNIQUE(schoolId, className)
      )
    ''');

    // Subjects table
    await db.execute('''
      CREATE TABLE Subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        schoolId TEXT NOT NULL,
        className TEXT NOT NULL,
        subjectName TEXT NOT NULL,
        FOREIGN KEY (schoolId) REFERENCES Schools (schoolId),
        UNIQUE(schoolId, className, subjectName)
      )
    ''');

    // ExamStructure table
    await db.execute('''
      CREATE TABLE ExamStructure (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        schoolId TEXT NOT NULL,
        className TEXT NOT NULL,
        examType TEXT NOT NULL,
        weightage REAL,
        FOREIGN KEY (schoolId) REFERENCES Schools (schoolId),
        UNIQUE(schoolId, className, examType)
      )
    ''');

    // Timetable table
    await db.execute('''
      CREATE TABLE Timetable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        schoolId TEXT NOT NULL,
        className TEXT NOT NULL,
        format TEXT NOT NULL,
        day TEXT NOT NULL,
        timeSlot TEXT NOT NULL,
        subject TEXT NOT NULL,
        FOREIGN KEY (schoolId) REFERENCES Schools (schoolId),
        UNIQUE(schoolId, className, day, timeSlot)
      )
    ''');

    // Announcements table
    await db.execute('''
      CREATE TABLE Announcements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        schoolId TEXT NOT NULL,
        studentId TEXT,
        teacherName TEXT,
        announcementDescription TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        isGeneral INTEGER NOT NULL DEFAULT 1,
        deadline TEXT,
        timeline TEXT,
        FOREIGN KEY (schoolId) REFERENCES Schools (schoolId),
        FOREIGN KEY (studentId) REFERENCES Students (studentId)
      )
    ''');

    // Marks table
    await db.execute('''
      CREATE TABLE Marks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        schoolId TEXT NOT NULL,
        studentId TEXT NOT NULL,
        subject TEXT NOT NULL,
        examType TEXT NOT NULL,
        marks TEXT NOT NULL,
        term TEXT,
        FOREIGN KEY (schoolId) REFERENCES Schools (schoolId),
        FOREIGN KEY (studentId) REFERENCES Students (studentId),
        UNIQUE(schoolId, studentId, subject, examType, term)
      )
    ''');

    // Attendance table
    await db.execute('''
      CREATE TABLE Attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        schoolId TEXT NOT NULL,
        studentId TEXT NOT NULL,
        subject TEXT NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        FOREIGN KEY (schoolId) REFERENCES Schools (schoolId),
        FOREIGN KEY (studentId) REFERENCES Students (studentId),
        UNIQUE(schoolId, studentId, subject, date)
      )
    ''');

    // Chats table
    await db.execute('''
      CREATE TABLE Chats (
        chatId TEXT PRIMARY KEY,
        schoolId TEXT NOT NULL,
        teacherId TEXT NOT NULL,
        teacherName TEXT NOT NULL,
        parentId TEXT NOT NULL,
        parentName TEXT NOT NULL,
        studentId TEXT NOT NULL,
        studentName TEXT NOT NULL,
        lastMessage TEXT,
        lastMessageTime TEXT,
        unreadCount INTEGER DEFAULT 0,
        FOREIGN KEY (schoolId) REFERENCES Schools (schoolId),
        FOREIGN KEY (teacherId) REFERENCES Teachers (employeeId),
        FOREIGN KEY (studentId) REFERENCES Students (studentId),
        UNIQUE(schoolId, teacherId, parentId, studentId)
      )
    ''');

    // Messages table
    await db.execute('''
      CREATE TABLE Messages (
        messageId TEXT PRIMARY KEY,
        chatId TEXT NOT NULL,
        senderId TEXT NOT NULL,
        senderType TEXT NOT NULL,
        senderName TEXT NOT NULL,
        message TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        isRead INTEGER DEFAULT 0,
        FOREIGN KEY (chatId) REFERENCES Chats (chatId)
      )
    ''');

    // Create index for faster message queries
    await db.execute('CREATE INDEX idx_messages_chatId ON Messages(chatId)');
    await db.execute('CREATE INDEX idx_messages_timestamp ON Messages(timestamp)');

    // GroupChats table
    await db.execute('''
      CREATE TABLE GroupChats (
        chatId TEXT PRIMARY KEY,
        schoolId TEXT NOT NULL,
        teacherId TEXT NOT NULL,
        teacherName TEXT NOT NULL,
        className TEXT NOT NULL,
        subjectName TEXT NOT NULL,
        groupName TEXT NOT NULL,
        lastMessage TEXT,
        lastMessageTime TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (schoolId) REFERENCES Schools (schoolId),
        FOREIGN KEY (teacherId) REFERENCES Teachers (employeeId),
        UNIQUE(schoolId, teacherId, className, subjectName)
      )
    ''');

    // GroupChatParticipants table
    await db.execute('''
      CREATE TABLE GroupChatParticipants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chatId TEXT NOT NULL,
        participantId TEXT NOT NULL,
        participantType TEXT NOT NULL,
        participantName TEXT NOT NULL,
        unreadCount INTEGER DEFAULT 0,
        joinedAt TEXT NOT NULL,
        FOREIGN KEY (chatId) REFERENCES GroupChats (chatId) ON DELETE CASCADE,
        UNIQUE(chatId, participantId, participantType)
      )
    ''');

    // Create indexes for group chats
    await db.execute('CREATE INDEX idx_groupchats_schoolId ON GroupChats(schoolId)');
    await db.execute('CREATE INDEX idx_groupchats_teacherId ON GroupChats(teacherId)');
    await db.execute('CREATE INDEX idx_groupchatparticipants_chatId ON GroupChatParticipants(chatId)');
    await db.execute('CREATE INDEX idx_groupchatparticipants_participant ON GroupChatParticipants(participantId, participantType)');

    // Assignments table
    await db.execute('''
      CREATE TABLE Assignments (
        id TEXT PRIMARY KEY,
        schoolId TEXT NOT NULL,
        teacherId TEXT NOT NULL,
        teacherName TEXT NOT NULL,
        className TEXT NOT NULL,
        subject TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        dueDate TEXT NOT NULL,
        postedDate TEXT NOT NULL,
        attachmentUrl TEXT,
        documentPath TEXT,
        imagePath TEXT,
        assignedClasses TEXT,
        FOREIGN KEY (schoolId) REFERENCES Schools (schoolId),
        FOREIGN KEY (teacherId) REFERENCES Teachers (employeeId)
      )
    ''');

    // Create indexes for assignments
    await db.execute('CREATE INDEX idx_assignments_schoolId ON Assignments(schoolId)');
    await db.execute('CREATE INDEX idx_assignments_teacherId ON Assignments(teacherId)');
    await db.execute('CREATE INDEX idx_assignments_className ON Assignments(className)');

    // AssignmentSubmissions table
    await db.execute('''
      CREATE TABLE AssignmentSubmissions (
        id TEXT PRIMARY KEY,
        assignmentId TEXT NOT NULL,
        schoolId TEXT NOT NULL,
        studentId TEXT NOT NULL,
        studentName TEXT NOT NULL,
        submissionText TEXT,
        imagePath TEXT,
        documentPath TEXT,
        submittedDate TEXT NOT NULL,
        status TEXT DEFAULT 'submitted',
        grade TEXT,
        feedback TEXT,
        FOREIGN KEY (assignmentId) REFERENCES Assignments (id),
        FOREIGN KEY (schoolId) REFERENCES Schools (schoolId),
        FOREIGN KEY (studentId) REFERENCES Students (studentId),
        UNIQUE(assignmentId, studentId)
      )
    ''');

    // Create indexes for submissions
    await db.execute('CREATE INDEX idx_submissions_assignmentId ON AssignmentSubmissions(assignmentId)');
    await db.execute('CREATE INDEX idx_submissions_studentId ON AssignmentSubmissions(studentId)');
    
    // Insert default school: Ghanima Girls High School
    try {
      await db.insert(
        'Schools',
        {
          'schoolId': 'ghanima_girls_high_001',
          'schoolName': 'Ghanima Girls High School',
          'adminEmail': 'admin@ghanimagirls.ac.ke',
          'adminPassword': 'admin123', // Default password - should be changed on first login
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('Default school inserted: Ghanima Girls High School');
    } catch (e) {
      print('Error inserting default school: $e');
      // Don't rethrow - allow database creation to complete even if default school fails
    }
    
    } catch (e) {
      print('Error creating database tables: $e');
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from version $oldVersion to $newVersion');
    
    try {
      // Add email column if it doesn't exist
      try {
        await db.execute('ALTER TABLE Students ADD COLUMN email TEXT');
        print('Added email column to Students table');
      } catch (e) {
        print('Email column may already exist: $e');
      }
      
      // Add password column if it doesn't exist
      try {
        await db.execute('ALTER TABLE Students ADD COLUMN password TEXT');
        print('Added password column to Students table');
        
        // Set default password for existing students without password
        await db.update(
          'Students',
          {'password': '1234567'},
          where: 'password IS NULL OR password = ""',
        );
        print('Set default password for existing students');
      } catch (e) {
        print('Password column may already exist: $e');
      }
      
      // Add payment columns if they don't exist (for version 2+ upgrade)
      if (oldVersion < 3) {
        try {
          await db.execute('ALTER TABLE Students ADD COLUMN paidAmount REAL DEFAULT 0.0');
          print('Added paidAmount column');
        } catch (e) {
          print('paidAmount column may already exist: $e');
        }
        
        try {
          await db.execute('ALTER TABLE Students ADD COLUMN balanceAmount REAL DEFAULT 40000.0');
          print('Added balanceAmount column');
        } catch (e) {
          print('balanceAmount column may already exist: $e');
        }
        
        try {
          await db.execute('ALTER TABLE Students ADD COLUMN feePerTerm REAL DEFAULT 40000.0');
          print('Added feePerTerm column');
        } catch (e) {
          print('feePerTerm column may already exist: $e');
        }
        
        // Initialize payment amounts for existing students
        try {
          await db.update(
            'Students',
            {
              'paidAmount': 0.0,
              'balanceAmount': 40000.0,
              'feePerTerm': 40000.0,
            },
            where: 'paidAmount IS NULL OR balanceAmount IS NULL',
          );
          print('Initialized payment amounts for existing students');
        } catch (e) {
          print('Error initializing payment amounts: $e');
        }
        
        // Create Payments table if it doesn't exist
        try {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS Payments (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              studentId TEXT NOT NULL,
              schoolId TEXT NOT NULL,
              amount REAL NOT NULL,
              paymentMethod TEXT NOT NULL,
              transactionId TEXT,
              mpesaReceiptNumber TEXT,
              paymentDate TEXT NOT NULL,
              term TEXT,
              status TEXT NOT NULL,
              FOREIGN KEY (studentId) REFERENCES Students (studentId),
              FOREIGN KEY (schoolId) REFERENCES Schools (schoolId)
            )
          ''');
          print('Created Payments table');
        } catch (e) {
          print('Payments table may already exist: $e');
        }
      }

      // Add adminName and adminId columns to Schools table (for version 5+ upgrade)
      if (oldVersion < 5) {
        try {
          await db.execute('ALTER TABLE Schools ADD COLUMN adminName TEXT');
          print('Added adminName column to Schools table');
        } catch (e) {
          print('adminName column may already exist: $e');
        }
        try {
          await db.execute('ALTER TABLE Schools ADD COLUMN adminId TEXT');
          print('Added adminId column to Schools table');
        } catch (e) {
          print('adminId column may already exist: $e');
        }
      }

      // Add chat tables if they don't exist (for version 4+ upgrade)
      if (oldVersion < 4) {
        try {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS Chats (
              chatId TEXT PRIMARY KEY,
              schoolId TEXT NOT NULL,
              teacherId TEXT NOT NULL,
              teacherName TEXT NOT NULL,
              parentId TEXT NOT NULL,
              parentName TEXT NOT NULL,
              studentId TEXT NOT NULL,
              studentName TEXT NOT NULL,
              lastMessage TEXT,
              lastMessageTime TEXT,
              unreadCount INTEGER DEFAULT 0,
              FOREIGN KEY (schoolId) REFERENCES Schools (schoolId),
              FOREIGN KEY (teacherId) REFERENCES Teachers (employeeId),
              FOREIGN KEY (studentId) REFERENCES Students (studentId),
              UNIQUE(schoolId, teacherId, parentId, studentId)
            )
          ''');
          print('Created Chats table');
        } catch (e) {
          print('Chats table may already exist: $e');
        }

        try {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS Messages (
              messageId TEXT PRIMARY KEY,
              chatId TEXT NOT NULL,
              senderId TEXT NOT NULL,
              senderType TEXT NOT NULL,
              senderName TEXT NOT NULL,
              message TEXT NOT NULL,
              timestamp TEXT NOT NULL,
              isRead INTEGER DEFAULT 0,
              FOREIGN KEY (chatId) REFERENCES Chats (chatId)
            )
          ''');
          print('Created Messages table');
        } catch (e) {
          print('Messages table may already exist: $e');
        }

        try {
          await db.execute('CREATE INDEX IF NOT EXISTS idx_messages_chatId ON Messages(chatId)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_messages_timestamp ON Messages(timestamp)');
          print('Created message indexes');
        } catch (e) {
          print('Message indexes may already exist: $e');
        }
      }

      // Add term column to Marks table (for version 7+ upgrade)
      if (oldVersion < 7) {
        try {
          await db.execute('ALTER TABLE Marks ADD COLUMN term TEXT');
          print('Added term column to Marks table');
        } catch (e) {
          print('Term column may already exist: $e');
        }
      }

      // Add deadline and timeline columns to Announcements table (for version 11+ upgrade)
      if (oldVersion < 11) {
        try {
          await db.execute('ALTER TABLE Announcements ADD COLUMN deadline TEXT');
          print('Added deadline column to Announcements table');
        } catch (e) {
          print('Deadline column may already exist: $e');
        }
        try {
          await db.execute('ALTER TABLE Announcements ADD COLUMN timeline TEXT');
          print('Added timeline column to Announcements table');
        } catch (e) {
          print('Timeline column may already exist: $e');
        }
      }

      // Add group chat tables if they don't exist (for version 6+ upgrade)
      if (oldVersion < 6) {
        try {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS GroupChats (
              chatId TEXT PRIMARY KEY,
              schoolId TEXT NOT NULL,
              teacherId TEXT NOT NULL,
              teacherName TEXT NOT NULL,
              className TEXT NOT NULL,
              subjectName TEXT NOT NULL,
              groupName TEXT NOT NULL,
              lastMessage TEXT,
              lastMessageTime TEXT,
              createdAt TEXT NOT NULL,
              FOREIGN KEY (schoolId) REFERENCES Schools (schoolId),
              FOREIGN KEY (teacherId) REFERENCES Teachers (employeeId),
              UNIQUE(schoolId, teacherId, className, subjectName)
            )
          ''');
          print('Created GroupChats table');
        } catch (e) {
          print('GroupChats table may already exist: $e');
        }

        try {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS GroupChatParticipants (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              chatId TEXT NOT NULL,
              participantId TEXT NOT NULL,
              participantType TEXT NOT NULL,
              participantName TEXT NOT NULL,
              unreadCount INTEGER DEFAULT 0,
              joinedAt TEXT NOT NULL,
              FOREIGN KEY (chatId) REFERENCES GroupChats (chatId) ON DELETE CASCADE,
              UNIQUE(chatId, participantId, participantType)
            )
          ''');
          print('Created GroupChatParticipants table');
        } catch (e) {
          print('GroupChatParticipants table may already exist: $e');
        }

        try {
          await db.execute('CREATE INDEX IF NOT EXISTS idx_groupchats_schoolId ON GroupChats(schoolId)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_groupchats_teacherId ON GroupChats(teacherId)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_groupchatparticipants_chatId ON GroupChatParticipants(chatId)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_groupchatparticipants_participant ON GroupChatParticipants(participantId, participantType)');
          print('Created group chat indexes');
        } catch (e) {
          print('Group chat indexes may already exist: $e');
        }
      }

      // Add Assignments table (for version 8+ upgrade)
      if (oldVersion < 8) {
        try {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS Assignments (
              id TEXT PRIMARY KEY,
              schoolId TEXT NOT NULL,
              teacherId TEXT NOT NULL,
              teacherName TEXT NOT NULL,
              className TEXT NOT NULL,
              subject TEXT NOT NULL,
              title TEXT NOT NULL,
              description TEXT,
              dueDate TEXT NOT NULL,
              postedDate TEXT NOT NULL,
              attachmentUrl TEXT,
              documentPath TEXT,
              imagePath TEXT,
              assignedClasses TEXT,
              FOREIGN KEY (schoolId) REFERENCES Schools (schoolId),
              FOREIGN KEY (teacherId) REFERENCES Teachers (employeeId)
            )
          ''');
          print('Created Assignments table');
          
          await db.execute('CREATE INDEX IF NOT EXISTS idx_assignments_schoolId ON Assignments(schoolId)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_assignments_teacherId ON Assignments(teacherId)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_assignments_className ON Assignments(className)');
          print('Created assignment indexes');
        } catch (e) {
          print('Assignments table may already exist: $e');
        }
      }

      // Add AssignmentSubmissions table (for version 9+ upgrade)
      if (oldVersion < 9) {
        try {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS AssignmentSubmissions (
              id TEXT PRIMARY KEY,
              assignmentId TEXT NOT NULL,
              schoolId TEXT NOT NULL,
              studentId TEXT NOT NULL,
              studentName TEXT NOT NULL,
              submissionText TEXT,
              imagePath TEXT,
              documentPath TEXT,
              submittedDate TEXT NOT NULL,
              status TEXT DEFAULT 'submitted',
              grade TEXT,
              feedback TEXT,
              FOREIGN KEY (assignmentId) REFERENCES Assignments (id),
              FOREIGN KEY (schoolId) REFERENCES Schools (schoolId),
              FOREIGN KEY (studentId) REFERENCES Students (studentId),
              UNIQUE(assignmentId, studentId)
            )
          ''');
          print('Created AssignmentSubmissions table');
          
          await db.execute('CREATE INDEX IF NOT EXISTS idx_submissions_assignmentId ON AssignmentSubmissions(assignmentId)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_submissions_studentId ON AssignmentSubmissions(studentId)');
          print('Created submission indexes');
        } catch (e) {
          print('AssignmentSubmissions table may already exist: $e');
        }
      }

      // Add documentPath and imagePath columns to Assignments table (for version 10+ upgrade)
      if (oldVersion < 10) {
        try {
          await db.execute('ALTER TABLE Assignments ADD COLUMN documentPath TEXT');
          print('Added documentPath column to Assignments table');
        } catch (e) {
          print('documentPath column may already exist: $e');
        }
        try {
          await db.execute('ALTER TABLE Assignments ADD COLUMN imagePath TEXT');
          print('Added imagePath column to Assignments table');
        } catch (e) {
          print('imagePath column may already exist: $e');
        }
      }

      // Add documentPath column to AssignmentSubmissions table (for version 10+ upgrade)
      if (oldVersion < 10) {
        try {
          await db.execute('ALTER TABLE AssignmentSubmissions ADD COLUMN documentPath TEXT');
          print('Added documentPath column to AssignmentSubmissions table');
        } catch (e) {
          print('documentPath column may already exist in AssignmentSubmissions: $e');
        }
      }
    } catch (e) {
      print('Error upgrading database: $e');
      // Don't rethrow - allow app to continue even if upgrade partially fails
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

