import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/activity_log_model.dart';
import '../services/database_service.dart';
import 'package:uuid/uuid.dart';

class UserProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final Uuid _uuid = const Uuid();

  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _error;

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<UserModel> get students => _users.where((u) => u.role == 'student').toList();
  List<UserModel> get teachers => _users.where((u) => u.role == 'teacher').toList();
  List<UserModel> get employees => _users.where((u) => u.role == 'employee').toList();

  List<String> get allClasses => _users
      .where((u) => u.className != null)
      .map((u) => u.className!)
      .toSet()
      .toList()
    ..sort();

  List<String> get allDepartments => _users
      .where((u) => u.department != null)
      .map((u) => u.department!)
      .toSet()
      .toList()
    ..sort();

  List<String> get allGroups => _users
      .where((u) => u.group != null)
      .map((u) => u.group!)
      .toSet()
      .toList()
    ..sort();

  Future<void> loadUsers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await _db.query('users', orderBy: 'name ASC');
      _users = results.map((m) => UserModel.fromMap(m)).toList();
      _error = null;
    } catch (e) {
      _error = 'Failed to load users: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<UserModel?> getUserById(String id) async {
    final results = await _db.query('users', where: 'id = ?', whereArgs: [id]);
    if (results.isNotEmpty) {
      return UserModel.fromMap(results.first);
    }
    return null;
  }

  Future<bool> createUser(UserModel user, {String? createdBy}) async {
    try {
      await _db.insert('users', user.toMap());
      await loadUsers();

      if (createdBy != null) {
        await _logActivity(createdBy, 'user_created', 'Created user: ${user.name}', user.id, 'user');
      }
      return true;
    } catch (e) {
      _error = 'Failed to create user: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUser(UserModel user, {String? updatedBy}) async {
    try {
      await _db.update(
        'users',
        user.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
      );
      await loadUsers();

      if (updatedBy != null) {
        await _logActivity(updatedBy, 'profile_updated', 'Updated user: ${user.name}', user.id, 'user');
      }
      return true;
    } catch (e) {
      _error = 'Failed to update user: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(String userId, {String? deletedBy, String? deletedByName}) async {
    try {
      final user = await getUserById(userId);
      await _db.delete('users', where: 'id = ?', whereArgs: [userId]);
      await loadUsers();

      if (deletedBy != null) {
        await _logActivity(deletedBy, 'user_deleted', 'Deleted user: ${user?.name ?? userId}', userId, 'user');
      }
      return true;
    } catch (e) {
      _error = 'Failed to delete user: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateFaceData(String userId, List<String> faceData, {String? updatedBy}) async {
    try {
      final user = await getUserById(userId);
      if (user == null) return false;

      final updatedUser = user.copyWith(
        faceData: faceData,
        updatedAt: DateTime.now(),
      );
      await _db.update(
        'users',
        updatedUser.toMap(),
        where: 'id = ?',
        whereArgs: [userId],
      );
      await loadUsers();

      if (updatedBy != null) {
        await _logActivity(updatedBy, 'face_registered', 'Updated face data for: ${user.name}', userId, 'user');
      }
      return true;
    } catch (e) {
      _error = 'Failed to update face data: $e';
      notifyListeners();
      return false;
    }
  }

  List<UserModel> searchUsers(String query) {
    if (query.isEmpty) return _users;
    final lower = query.toLowerCase();
    return _users.where((u) {
      return u.name.toLowerCase().contains(lower) ||
          u.userId.toLowerCase().contains(lower) ||
          u.email.toLowerCase().contains(lower) ||
          (u.className?.toLowerCase().contains(lower) ?? false) ||
          (u.department?.toLowerCase().contains(lower) ?? false);
    }).toList();
  }

  List<UserModel> filterUsers({String? role, String? className, String? department, String? group}) {
    return _users.where((u) {
      if (role != null && u.role != role) return false;
      if (className != null && u.className != className) return false;
      if (department != null && u.department != department) return false;
      if (group != null && u.group != group) return false;
      return true;
    }).toList();
  }

  Future<void> _logActivity(String userId, String action, String description, String? targetId, String? targetType) async {
    final user = await getUserById(userId);
    final log = ActivityLogModel(
      id: _uuid.v4(),
      userId: userId,
      userName: user?.name ?? 'Unknown',
      action: action,
      description: description,
      targetId: targetId,
      targetType: targetType,
      createdAt: DateTime.now(),
    );
    await _db.insert('activity_logs', log.toMap());
  }
}
