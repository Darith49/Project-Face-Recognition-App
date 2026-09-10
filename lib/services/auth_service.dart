import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'database_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final DatabaseService _db = DatabaseService();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'admin';
  bool get isTeacher => _currentUser?.role == 'teacher';
  bool get isStudent => _currentUser?.role == 'student';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('current_user_id');
    if (userId != null) {
      final users = await _db.query(
        'users',
        where: 'id = ? AND isActive = 1',
        whereArgs: [userId],
      );
      if (users.isNotEmpty) {
        _currentUser = UserModel.fromMap(users.first);
      }
    }
  }

  Future<UserModel?> login(String email, String password) async {
    final users = await _db.query(
      'users',
      where: 'email = ? AND password = ? AND isActive = 1',
      whereArgs: [email, password],
    );

    if (users.isNotEmpty) {
      _currentUser = UserModel.fromMap(users.first);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_id', _currentUser!.id);
      return _currentUser;
    }
    return null;
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
  }

  Future<void> refreshCurrentUser() async {
    if (_currentUser != null) {
      final users = await _db.query(
        'users',
        where: 'id = ?',
        whereArgs: [_currentUser!.id],
      );
      if (users.isNotEmpty) {
        _currentUser = UserModel.fromMap(users.first);
      }
    }
  }

  bool hasPermission(String permission) {
    if (_currentUser == null) return false;
    if (_currentUser!.role == 'admin') return true;

    switch (permission) {
      case 'manage_users':
        return _currentUser!.role == 'admin';
      case 'manage_schedules':
        return _currentUser!.role == 'admin' || _currentUser!.role == 'teacher';
      case 'view_all_attendance':
        return _currentUser!.role == 'admin' || _currentUser!.role == 'teacher';
      case 'manage_attendance':
        return _currentUser!.role == 'admin' || _currentUser!.role == 'teacher';
      case 'view_reports':
        return _currentUser!.role == 'admin' || _currentUser!.role == 'teacher';
      case 'view_activity_logs':
        return _currentUser!.role == 'admin';
      case 'check_attendance':
        return true;
      case 'view_own_attendance':
        return true;
      default:
        return false;
    }
  }
}
