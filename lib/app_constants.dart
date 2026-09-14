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
  static const double faceMatchThreshold = 0.88;
  static const int maxFaceImages = 5;
  static const double minFaceSize = 0.15;

  // Attendance
  static const int lateThresholdMinutes = 15;
  static const int absentThresholdMinutes = 60;

  // GPS
  static const double gpsRadiusMeters = 200.0;
  // Default coordinates (e.g. Norton University or desired location)
  static const double schoolLatitude = 11.5564;
  static const double schoolLongitude = 104.9282;

}
