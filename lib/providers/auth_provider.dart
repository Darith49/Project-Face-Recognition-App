import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/activity_log_model.dart';
import 'package:uuid/uuid.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final DatabaseService _db = DatabaseService();
  final Uuid _uuid = const Uuid();

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;
  UserModel? get currentUser => _authService.currentUser;
  bool get isLoggedIn => _authService.isLoggedIn;
  bool get isAdmin => _authService.isAdmin;
  bool get isTeacher => _authService.isTeacher;
  bool get isStudent => _authService.isStudent;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await _authService.init();

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.login(email, password);
      if (user != null) {
        await _logActivity('login', 'User logged in');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Invalid email or password';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Login failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _logActivity('logout', 'User logged out');
    await _authService.logout();
    notifyListeners();
  }

  Future<void> refreshUser() async {
    await _authService.refreshCurrentUser();
    notifyListeners();
  }

  bool hasPermission(String permission) {
    return _authService.hasPermission(permission);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _logActivity(String action, String description) async {
    if (_authService.currentUser == null) return;
    final log = ActivityLogModel(
      id: _uuid.v4(),
      userId: _authService.currentUser!.id,
      userName: _authService.currentUser!.name,
      action: action,
      description: description,
      createdAt: DateTime.now(),
    );
    await _db.insert('activity_logs', log.toMap());
  }
}
