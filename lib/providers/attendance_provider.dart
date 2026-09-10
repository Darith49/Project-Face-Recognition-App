import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../models/activity_log_model.dart';
import '../services/database_service.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class AttendanceProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final Uuid _uuid = const Uuid();

  List<AttendanceModel> _attendanceRecords = [];
  List<AttendanceModel> _todayRecords = [];
  bool _isLoading = false;
  String? _error;

  List<AttendanceModel> get attendanceRecords => _attendanceRecords;
  List<AttendanceModel> get todayRecords => _todayRecords;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Dashboard stats
  int get todayPresent => _todayRecords
      .where((a) => a.type == 'Check-in' && a.status == 'Present')
      .map((a) => a.odlUserId)
      .toSet()
      .length;

  int get todayLate => _todayRecords
      .where((a) => a.type == 'Check-in' && a.status == 'Late')
      .map((a) => a.odlUserId)
      .toSet()
      .length;

  int get todayCheckIns => _todayRecords
      .where((a) => a.type == 'Check-in')
      .length;

  int get todayCheckOuts => _todayRecords
      .where((a) => a.type == 'Check-out')
      .length;

  Future<void> loadTodayAttendance() async {
    _isLoading = true;
    notifyListeners();

    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final results = await _db.query(
        'attendance',
        where: 'date = ?',
        whereArgs: [today],
        orderBy: 'dateTime DESC',
      );
      _todayRecords = results.map((m) => AttendanceModel.fromMap(m)).toList();
      _error = null;
    } catch (e) {
      _error = 'Failed to load attendance: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAttendanceByDate(String date) async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await _db.query(
        'attendance',
        where: 'date = ?',
        whereArgs: [date],
        orderBy: 'dateTime DESC',
      );
      _attendanceRecords = results.map((m) => AttendanceModel.fromMap(m)).toList();
      _error = null;
    } catch (e) {
      _error = 'Failed to load attendance: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAllAttendance() async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await _db.query(
        'attendance',
        orderBy: 'dateTime DESC',
        limit: 500,
      );
      _attendanceRecords = results.map((m) => AttendanceModel.fromMap(m)).toList();
      _error = null;
    } catch (e) {
      _error = 'Failed to load attendance: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<List<AttendanceModel>> getAttendanceByUser(String odlUserId, {String? startDate, String? endDate}) async {
    String where = 'odlUserId = ?';
    List<dynamic> whereArgs = [odlUserId];

    if (startDate != null) {
      where += ' AND date >= ?';
      whereArgs.add(startDate);
    }
    if (endDate != null) {
      where += ' AND date <= ?';
      whereArgs.add(endDate);
    }

    final results = await _db.query(
      'attendance',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'dateTime DESC',
    );
    return results.map((m) => AttendanceModel.fromMap(m)).toList();
  }

  Future<bool> recordAttendance(AttendanceModel attendance, {String? recordedBy}) async {
    try {
      await _db.insert('attendance', attendance.toMap());
      await loadTodayAttendance();

      if (recordedBy != null) {
        final log = ActivityLogModel(
          id: _uuid.v4(),
          userId: recordedBy,
          userName: attendance.userName,
          action: attendance.type == 'Check-in' ? 'attendance_check_in' : 'attendance_check_out',
          description: '${attendance.type} recorded for ${attendance.userName} - ${attendance.status}',
          targetId: attendance.id,
          targetType: 'attendance',
          createdAt: DateTime.now(),
        );
        await _db.insert('activity_logs', log.toMap());
      }
      return true;
    } catch (e) {
      _error = 'Failed to record attendance: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAttendance(AttendanceModel attendance, {String? updatedBy}) async {
    try {
      await _db.update(
        'attendance',
        attendance.toMap(),
        where: 'id = ?',
        whereArgs: [attendance.id],
      );
      await loadTodayAttendance();
      await loadAllAttendance();

      if (updatedBy != null) {
        final log = ActivityLogModel(
          id: _uuid.v4(),
          userId: updatedBy,
          userName: 'System',
          action: 'attendance_modified',
          description: 'Attendance record modified for ${attendance.userName}',
          targetId: attendance.id,
          targetType: 'attendance',
          createdAt: DateTime.now(),
        );
        await _db.insert('activity_logs', log.toMap());
      }
      return true;
    } catch (e) {
      _error = 'Failed to update attendance: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAttendance(String id, {String? deletedBy}) async {
    try {
      await _db.delete('attendance', where: 'id = ?', whereArgs: [id]);
      await loadTodayAttendance();
      await loadAllAttendance();
      return true;
    } catch (e) {
      _error = 'Failed to delete attendance: $e';
      notifyListeners();
      return false;
    }
  }

  // Statistics methods
  Future<Map<String, int>> getWeeklyStats() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final stats = <String, int>{};

    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final dayName = DateFormat('EEE').format(date);

      final results = await _db.query(
        'attendance',
        where: 'date = ? AND type = ?',
        whereArgs: [dateStr, 'Check-in'],
      );
      stats[dayName] = results.length;
    }

    return stats;
  }

  Future<Map<String, int>> getMonthlyStats() async {
    final now = DateTime.now();
    final stats = <String, int>{};

    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final dayStr = DateFormat('dd').format(date);

      final results = await _db.query(
        'attendance',
        where: 'date = ? AND type = ?',
        whereArgs: [dateStr, 'Check-in'],
      );
      stats[dayStr] = results.length;
    }

    return stats;
  }

  Future<Map<String, int>> getStatusDistribution({String? date}) async {
    final targetDate = date ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    final distribution = <String, int>{
      'Present': 0,
      'Late': 0,
      'Absent': 0,
      'Leave': 0,
    };

    final results = await _db.query(
      'attendance',
      where: 'date = ? AND type = ?',
      whereArgs: [targetDate, 'Check-in'],
    );

    for (final record in results) {
      final status = record['status'] as String;
      distribution[status] = (distribution[status] ?? 0) + 1;
    }

    return distribution;
  }

  Future<double> getAttendanceRate({String? startDate, String? endDate, String? className}) async {
    String where = "type = 'Check-in'";
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      where += ' AND date >= ?';
      whereArgs.add(startDate);
    }
    if (endDate != null) {
      where += ' AND date <= ?';
      whereArgs.add(endDate);
    }

    final results = await _db.query(
      'attendance',
      where: where,
      whereArgs: whereArgs,
    );

    if (results.isEmpty) return 0.0;

    final presentCount = results.where((r) => r['status'] == 'Present' || r['status'] == 'Late').length;
    return (presentCount / results.length) * 100;
  }

  List<AttendanceModel> filterAttendance({
    String? userId,
    String? status,
    String? type,
    String? startDate,
    String? endDate,
  }) {
    return _attendanceRecords.where((a) {
      if (userId != null && a.odlUserId != userId) return false;
      if (status != null && a.status != status) return false;
      if (type != null && a.type != type) return false;
      if (startDate != null && a.date.compareTo(startDate) < 0) return false;
      if (endDate != null && a.date.compareTo(endDate) > 0) return false;
      return true;
    }).toList();
  }
}
