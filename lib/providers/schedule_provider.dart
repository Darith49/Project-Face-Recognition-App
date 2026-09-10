import 'package:flutter/material.dart';
import '../models/schedule_model.dart';
import '../models/activity_log_model.dart';
import '../services/database_service.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class ScheduleProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final Uuid _uuid = const Uuid();

  List<ScheduleModel> _schedules = [];
  bool _isLoading = false;
  String? _error;

  List<ScheduleModel> get schedules => _schedules;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<ScheduleModel> get todaySchedules {
    final today = DateFormat('EEEE').format(DateTime.now());
    return _schedules.where((s) => s.dayOfWeek == today && s.isActive).toList();
  }

  Future<void> loadSchedules() async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await _db.query('schedules', orderBy: 'dayOfWeek ASC, startTime ASC');
      _schedules = results.map((m) => ScheduleModel.fromMap(m)).toList();
      _error = null;
    } catch (e) {
      _error = 'Failed to load schedules: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createSchedule(ScheduleModel schedule, {String? createdBy}) async {
    try {
      await _db.insert('schedules', schedule.toMap());
      await loadSchedules();

      if (createdBy != null) {
        final log = ActivityLogModel(
          id: _uuid.v4(),
          userId: createdBy,
          userName: 'System',
          action: 'schedule_created',
          description: 'Created schedule: ${schedule.name}',
          targetId: schedule.id,
          targetType: 'schedule',
          createdAt: DateTime.now(),
        );
        await _db.insert('activity_logs', log.toMap());
      }
      return true;
    } catch (e) {
      _error = 'Failed to create schedule: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSchedule(ScheduleModel schedule) async {
    try {
      await _db.update(
        'schedules',
        schedule.toMap(),
        where: 'id = ?',
        whereArgs: [schedule.id],
      );
      await loadSchedules();
      return true;
    } catch (e) {
      _error = 'Failed to update schedule: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSchedule(String id) async {
    try {
      await _db.delete('schedules', where: 'id = ?', whereArgs: [id]);
      await loadSchedules();
      return true;
    } catch (e) {
      _error = 'Failed to delete schedule: $e';
      notifyListeners();
      return false;
    }
  }

  List<ScheduleModel> getSchedulesByDay(String dayOfWeek) {
    return _schedules.where((s) => s.dayOfWeek == dayOfWeek && s.isActive).toList();
  }

  List<ScheduleModel> getSchedulesByClass(String className) {
    return _schedules.where((s) => s.className == className && s.isActive).toList();
  }

  ScheduleModel? getCurrentSchedule() {
    final now = DateTime.now();
    final today = DateFormat('EEEE').format(now);
    final currentTime = DateFormat('HH:mm').format(now);

    for (final schedule in _schedules) {
      if (schedule.dayOfWeek == today &&
          schedule.isActive &&
          schedule.startTime.compareTo(currentTime) <= 0 &&
          schedule.endTime.compareTo(currentTime) >= 0) {
        return schedule;
      }
    }
    return null;
  }

  ScheduleModel? getNextSchedule() {
    final now = DateTime.now();
    final today = DateFormat('EEEE').format(now);
    final currentTime = DateFormat('HH:mm').format(now);

    final todaySchedules = _schedules
        .where((s) => s.dayOfWeek == today && s.isActive && s.startTime.compareTo(currentTime) > 0)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return todaySchedules.isNotEmpty ? todaySchedules.first : null;
  }
}
