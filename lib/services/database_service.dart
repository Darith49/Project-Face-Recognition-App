import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../core/constants/app_constants.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), AppConstants.dbName);
    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        gender TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'student',
        groupName TEXT,
        className TEXT,
        department TEXT,
        subject TEXT,
        phone TEXT,
        profileImage TEXT,
        faceData TEXT DEFAULT '[]',
        isActive INTEGER DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Attendance table
    await db.execute('''
      CREATE TABLE attendance (
        id TEXT PRIMARY KEY,
        odlUserId TEXT NOT NULL,
        userId TEXT NOT NULL,
        userName TEXT NOT NULL,
        type TEXT NOT NULL,
        status TEXT NOT NULL,
        dateTime TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        scheduleId TEXT,
        scheduleName TEXT,
        latitude REAL,
        longitude REAL,
        locationName TEXT,
        verified INTEGER DEFAULT 0,
        confidenceScore REAL,
        notes TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (odlUserId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Schedules table
    await db.execute('''
      CREATE TABLE schedules (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        subject TEXT,
        className TEXT,
        department TEXT,
        room TEXT,
        teacherId TEXT,
        teacherName TEXT,
        dayOfWeek TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        radiusMeters REAL,
        locationName TEXT,
        isActive INTEGER DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Activity logs table
    await db.execute('''
      CREATE TABLE activity_logs (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        userName TEXT NOT NULL,
        action TEXT NOT NULL,
        description TEXT NOT NULL,
        targetId TEXT,
        targetType TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_attendance_date ON attendance(date)');
    await db.execute('CREATE INDEX idx_attendance_userId ON attendance(odlUserId)');
    await db.execute('CREATE INDEX idx_attendance_status ON attendance(status)');
    await db.execute('CREATE INDEX idx_schedules_day ON schedules(dayOfWeek)');
    await db.execute('CREATE INDEX idx_activity_logs_userId ON activity_logs(userId)');
    await db.execute('CREATE INDEX idx_users_role ON users(role)');
    await db.execute('CREATE INDEX idx_users_email ON users(email)');

    // Insert default admin user
    final now = DateTime.now().toIso8601String();
    await db.insert('users', {
      'id': 'admin-001',
      'userId': 'ADMIN001',
      'name': 'Administrator',
      'email': 'admin@faceattend.com',
      'password': 'admin123',
      'gender': 'Other',
      'role': 'admin',
      'groupName': null,
      'className': null,
      'department': 'Administration',
      'subject': null,
      'phone': null,
      'profileImage': null,
      'faceData': '[]',
      'isActive': 1,
      'createdAt': now,
      'updatedAt': now,
    });

    // Insert sample data
    await _insertSampleData(db);
  }

  Future<void> _insertSampleData(Database db) async {
    final now = DateTime.now();
    final nowStr = now.toIso8601String();

    // Sample students
    final students = [
      {'id': 'std-001', 'userId': 'STD001', 'name': 'Sokha Chan', 'email': 'sokha@student.edu', 'gender': 'Male', 'className': 'CS-Y3', 'department': 'Computer Science', 'group': 'Group A'},
      {'id': 'std-002', 'userId': 'STD002', 'name': 'Dara Keo', 'email': 'dara@student.edu', 'gender': 'Male', 'className': 'CS-Y3', 'department': 'Computer Science', 'group': 'Group A'},
      {'id': 'std-003', 'userId': 'STD003', 'name': 'Sreyleak Phan', 'email': 'sreyleak@student.edu', 'gender': 'Female', 'className': 'CS-Y3', 'department': 'Computer Science', 'group': 'Group B'},
      {'id': 'std-004', 'userId': 'STD004', 'name': 'Vicheka Long', 'email': 'vicheka@student.edu', 'gender': 'Male', 'className': 'IT-Y2', 'department': 'Information Technology', 'group': 'Group A'},
      {'id': 'std-005', 'userId': 'STD005', 'name': 'Bopha Meas', 'email': 'bopha@student.edu', 'gender': 'Female', 'className': 'IT-Y2', 'department': 'Information Technology', 'group': 'Group B'},
      {'id': 'std-006', 'userId': 'STD006', 'name': 'Rithya Yim', 'email': 'rithya@student.edu', 'gender': 'Male', 'className': 'CS-Y3', 'department': 'Computer Science', 'group': 'Group A'},
      {'id': 'std-007', 'userId': 'STD007', 'name': 'Channary Sok', 'email': 'channary@student.edu', 'gender': 'Female', 'className': 'CS-Y3', 'department': 'Computer Science', 'group': 'Group B'},
      {'id': 'std-008', 'userId': 'STD008', 'name': 'Piseth Nhem', 'email': 'piseth@student.edu', 'gender': 'Male', 'className': 'IT-Y2', 'department': 'Information Technology', 'group': 'Group A'},
    ];

    for (var student in students) {
      await db.insert('users', {
        'id': student['id'],
        'userId': student['userId'],
        'name': student['name'],
        'email': student['email'],
        'password': 'student123',
        'gender': student['gender'],
        'role': 'student',
        'groupName': student['group'],
        'className': student['className'],
        'department': student['department'],
        'subject': null,
        'phone': null,
        'profileImage': null,
        'faceData': '[]',
        'isActive': 1,
        'createdAt': nowStr,
        'updatedAt': nowStr,
      });
    }

    // Sample teacher
    await db.insert('users', {
      'id': 'tch-001',
      'userId': 'TCH001',
      'name': 'Prof. Thongheng',
      'email': 'thongheng@teacher.edu',
      'password': 'teacher123',
      'gender': 'Male',
      'role': 'teacher',
      'groupName': null,
      'className': null,
      'department': 'Computer Science',
      'subject': 'Flutter Development',
      'phone': null,
      'profileImage': null,
      'faceData': '[]',
      'isActive': 1,
      'createdAt': nowStr,
      'updatedAt': nowStr,
    });

    // Sample schedules
    final schedules = [
      {'id': 'sch-001', 'name': 'Flutter Development', 'subject': 'Flutter', 'className': 'CS-Y3', 'day': 'Monday', 'start': '08:00', 'end': '10:00', 'room': 'Lab 301'},
      {'id': 'sch-002', 'name': 'Data Structures', 'subject': 'DSA', 'className': 'CS-Y3', 'day': 'Tuesday', 'start': '10:00', 'end': '12:00', 'room': 'Room 205'},
      {'id': 'sch-003', 'name': 'Web Development', 'subject': 'Web Dev', 'className': 'IT-Y2', 'day': 'Wednesday', 'start': '14:00', 'end': '16:00', 'room': 'Lab 302'},
      {'id': 'sch-004', 'name': 'Database Systems', 'subject': 'DBMS', 'className': 'CS-Y3', 'day': 'Thursday', 'start': '08:00', 'end': '10:00', 'room': 'Room 101'},
      {'id': 'sch-005', 'name': 'Mobile App Dev', 'subject': 'Mobile', 'className': 'IT-Y2', 'day': 'Friday', 'start': '10:00', 'end': '12:00', 'room': 'Lab 301'},
    ];

    for (var schedule in schedules) {
      await db.insert('schedules', {
        'id': schedule['id'],
        'name': schedule['name'],
        'subject': schedule['subject'],
        'className': schedule['className'],
        'department': 'Computer Science',
        'room': schedule['room'],
        'teacherId': 'tch-001',
        'teacherName': 'Prof. Thongheng',
        'dayOfWeek': schedule['day'],
        'startTime': schedule['start'],
        'endTime': schedule['end'],
        'latitude': null,
        'longitude': null,
        'radiusMeters': null,
        'locationName': null,
        'isActive': 1,
        'createdAt': nowStr,
        'updatedAt': nowStr,
      });
    }

    // Sample attendance records for last 7 days
    final statuses = ['Present', 'Present', 'Present', 'Late', 'Present', 'Present', 'Absent'];
    for (int dayOffset = 6; dayOffset >= 0; dayOffset--) {
      final date = now.subtract(Duration(days: dayOffset));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      for (int i = 0; i < students.length; i++) {
        final statusIndex = (i + dayOffset) % statuses.length;
        final status = statuses[statusIndex];
        if (status == 'Absent') continue;

        final checkInHour = status == 'Late' ? 8 + (i % 2) : 7 + (i % 2);
        final checkInMinute = status == 'Late' ? 20 + (i * 5) % 40 : (i * 7) % 55;

        // Check-in
        await db.insert('attendance', {
          'id': 'att-in-$dayOffset-$i',
          'odlUserId': students[i]['id'],
          'userId': students[i]['userId'],
          'userName': students[i]['name'],
          'type': 'Check-in',
          'status': status,
          'dateTime': DateTime(date.year, date.month, date.day, checkInHour, checkInMinute).toIso8601String(),
          'date': dateStr,
          'time': '${checkInHour.toString().padLeft(2, '0')}:${checkInMinute.toString().padLeft(2, '0')}:00',
          'scheduleId': null,
          'scheduleName': null,
          'latitude': null,
          'longitude': null,
          'locationName': null,
          'verified': 1,
          'confidenceScore': 0.85 + (i * 0.02),
          'notes': null,
          'createdAt': nowStr,
        });

        // Check-out
        await db.insert('attendance', {
          'id': 'att-out-$dayOffset-$i',
          'odlUserId': students[i]['id'],
          'userId': students[i]['userId'],
          'userName': students[i]['name'],
          'type': 'Check-out',
          'status': status,
          'dateTime': DateTime(date.year, date.month, date.day, 16 + (i % 2), (i * 11) % 55).toIso8601String(),
          'date': dateStr,
          'time': '${(16 + (i % 2)).toString().padLeft(2, '0')}:${((i * 11) % 55).toString().padLeft(2, '0')}:00',
          'scheduleId': null,
          'scheduleName': null,
          'latitude': null,
          'longitude': null,
          'locationName': null,
          'verified': 1,
          'confidenceScore': 0.88 + (i * 0.01),
          'notes': null,
          'createdAt': nowStr,
        });
      }
    }
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // Handle future database migrations
  }

  // Generic CRUD Operations
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  Future<int> rawInsert(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawInsert(sql, arguments);
  }
}
