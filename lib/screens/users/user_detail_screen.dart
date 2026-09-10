import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/attendance_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_badge.dart';
import '../face_recognition/face_register_screen.dart';

class UserDetailScreen extends StatefulWidget {
  final UserModel user;

  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  List<AttendanceModel> _userAttendance = [];
  late UserModel _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _loadUserAttendance();
  }

  Future<void> _loadUserAttendance() async {
    final provider = context.read<AttendanceProvider>();
    final records = await provider.getAttendanceByUser(_user.id);
    if (mounted) {
      setState(() => _userAttendance = records);
    }
  }

  Future<void> _refreshUser() async {
    final userProvider = context.read<UserProvider>();
    final updatedUser = await userProvider.getUserById(_user.id);
    if (updatedUser != null && mounted) {
      setState(() => _user = updatedUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildAppBar()),
              SliverToBoxAdapter(child: _buildProfileCard()),
              SliverToBoxAdapter(child: _buildFaceDataSection()),
              SliverToBoxAdapter(child: _buildInfoSection()),
              SliverToBoxAdapter(child: _buildAttendanceStats()),
              SliverToBoxAdapter(child: _buildAttendanceHistory()),
              SliverToBoxAdapter(child: _buildActions()),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'User Profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              if (!auth.hasPermission('manage_users')) return const SizedBox.shrink();
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                color: AppTheme.cardDark,
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit User', style: TextStyle(color: Colors.white))),
                  const PopupMenuItem(value: 'delete', child: Text('Delete User', style: TextStyle(color: AppTheme.errorColor))),
                ],
                onSelected: (value) {
                  if (value == 'delete') _confirmDelete();
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    final roleColors = {
      'admin': AppTheme.errorColor,
      'teacher': AppTheme.warningColor,
      'student': AppTheme.primaryColor,
      'employee': AppTheme.accentColor,
    };
    final color = roleColors[_user.role] ?? AppTheme.primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.6)],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _user.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _user.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _user.userId,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _user.role.toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (_user.hasFaceData)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.face_rounded, color: AppTheme.successColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Face Registered',
                          style: TextStyle(
                            color: AppTheme.successColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaceDataSection() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.face_retouching_natural_rounded,
                    color: AppTheme.primaryColor, size: 22),
                const SizedBox(width: 10),
                const Text(
                  'Face Profile',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_user.hasFaceData)
              Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: AppTheme.successColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${_user.faceData.length} face sample(s) registered',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppTheme.warningColor, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'No face data registered',
                    style: TextStyle(
                      color: AppTheme.warningColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FaceRegisterScreen(user: _user),
                    ),
                  ).then((_) {
                    _refreshUser();
                  });
                },
                icon: const Icon(Icons.camera_alt_rounded, size: 18),
                label: Text(_user.hasFaceData
                    ? 'Update Face Data'
                    : 'Register Face'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            _buildInfoRow(Icons.email_outlined, 'Email', _user.email),
            _buildInfoRow(Icons.wc_outlined, 'Gender', _user.gender),
            if (_user.className != null)
              _buildInfoRow(Icons.class_outlined, 'Class', _user.className!),
            if (_user.department != null)
              _buildInfoRow(Icons.business_outlined, 'Department', _user.department!),
            if (_user.group != null)
              _buildInfoRow(Icons.group_outlined, 'Group', _user.group!),
            if (_user.phone != null)
              _buildInfoRow(Icons.phone_outlined, 'Phone', _user.phone!),
            _buildInfoRow(
              Icons.calendar_today_outlined,
              'Joined',
              DateFormat('dd MMM yyyy').format(_user.createdAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textTertiary, size: 18),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStats() {
    final total = _userAttendance.where((a) => a.type == 'Check-in').length;
    final present = _userAttendance
        .where((a) => a.type == 'Check-in' && a.status == 'Present')
        .length;
    final late = _userAttendance
        .where((a) => a.type == 'Check-in' && a.status == 'Late')
        .length;
    final rate = total > 0 ? ((present + late) / total * 100) : 0.0;

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _buildMiniStat('Total', '$total', AppTheme.primaryColor),
                _buildMiniStat('Present', '$present', AppTheme.successColor),
                _buildMiniStat('Late', '$late', AppTheme.warningColor),
                _buildMiniStat('Rate', '${rate.toStringAsFixed(0)}%', AppTheme.accentColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceHistory() {
    final recentRecords = _userAttendance.take(10).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Attendance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          if (recentRecords.isEmpty)
            GlassCard(
              child: Center(
                child: Text(
                  'No attendance records',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            )
          else
            ...recentRecords.map((record) => GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        record.type == 'Check-in'
                            ? Icons.login_rounded
                            : Icons.logout_rounded,
                        color: record.type == 'Check-in'
                            ? AppTheme.accentColor
                            : AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.type,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${record.date} • ${record.time.substring(0, 5)}',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(status: record.status, fontSize: 11),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.hasPermission('manage_users')) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _confirmDelete,
                  icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor),
                  label: const Text(
                    'Delete User',
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.errorColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Delete User', style: TextStyle(color: Colors.white)),
          content: Text(
            'Are you sure you want to delete ${_user.name}? This action cannot be undone.',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final auth = context.read<AuthProvider>();
                await context.read<UserProvider>().deleteUser(
                      _user.id,
                      deletedBy: auth.currentUser?.id,
                    );
                if (context.mounted) {
                  Navigator.pop(context); // Dialog
                  Navigator.pop(context); // Detail screen
                }
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: AppTheme.errorColor),
              ),
            ),
          ],
        );
      },
    );
  }
}
