// App-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'FaceAttend';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Smart Attendance System';

  // Database
  static const String dbName = 'face_attendance.db';
  static const int dbVersion = 1;

  // Face Recognition
  static const double faceMatchThreshold = 0.75;
  static const int maxFaceImages = 5;
  static const double minFaceSize = 0.15;

  // Attendance
  static const int lateThresholdMinutes = 15;
  static const int absentThresholdMinutes = 60;

  // GPS
  static const double gpsRadiusMeters = 200.0;

  // Date Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm:ss';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'dd MMM yyyy';
  static const String displayTimeFormat = 'hh:mm a';

  // Attendance Status
  static const String statusPresent = 'Present';
  static const String statusLate = 'Late';
  static const String statusAbsent = 'Absent';
  static const String statusLeave = 'Leave';
  static const String statusCheckIn = 'Check-in';
  static const String statusCheckOut = 'Check-out';

  // Roles
  static const String roleAdmin = 'admin';
  static const String roleTeacher = 'teacher';
  static const String roleStudent = 'student';
  static const String roleEmployee = 'employee';

  // Gender
  static const String genderMale = 'Male';
  static const String genderFemale = 'Female';
  static const String genderOther = 'Other';
}
