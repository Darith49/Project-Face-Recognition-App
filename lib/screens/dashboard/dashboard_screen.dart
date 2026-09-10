import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_badge.dart';
import '../auth/login_screen.dart';
import '../face_recognition/face_scan_screen.dart';
import '../../models/attendance_model.dart';
import 'package:uuid/uuid.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, int> _weeklyStats = {};
  Map<String, int> _statusDistribution = {};
  double _attendanceRate = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final attendanceProvider = context.read<AttendanceProvider>();
    final userProvider = context.read<UserProvider>();
    final scheduleProvider = context.read<ScheduleProvider>();

    await Future.wait([
      attendanceProvider.loadTodayAttendance(),
      userProvider.loadUsers(),
      scheduleProvider.loadSchedules(),
    ]);

    final weekly = await attendanceProvider.getWeeklyStats();
    final distribution = await attendanceProvider.getStatusDistribution();
    final rate = await attendanceProvider.getAttendanceRate();

    if (mounted) {
      setState(() {
        _weeklyStats = weekly;
        _statusDistribution = distribution;
        _attendanceRate = rate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.darkGradient,
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: AppTheme.primaryColor,
            child: CustomScrollView(
              slivers: [
                // App Bar
                SliverToBoxAdapter(
                  child: _buildHeader(),
                ),

                // Stats Cards
                SliverToBoxAdapter(
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    child: _buildStatsGrid(),
                  ),
                ),

                // Quick Actions
                SliverToBoxAdapter(
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 100),
                    child: _buildQuickActions(),
                  ),
                ),

                // Today's Schedule
                SliverToBoxAdapter(
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 200),
                    child: _buildTodaySchedule(),
                  ),
                ),

                // Weekly Chart
                SliverToBoxAdapter(
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 300),
                    child: _buildWeeklyChart(),
                  ),
                ),

                // Status Distribution
                SliverToBoxAdapter(
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 400),
                    child: _buildStatusDistribution(),
                  ),
                ),

                // Recent Activity
                SliverToBoxAdapter(
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 500),
                    child: _buildRecentActivity(),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          child: Row(
            children: [
              // Profile Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    auth.currentUser?.name.substring(0, 1).toUpperCase() ?? 'A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${auth.currentUser?.name.split(' ').first ?? 'User'} 👋',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Logout
              GestureDetector(
                onTap: () async {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsGrid() {
    return Consumer2<AttendanceProvider, UserProvider>(
      builder: (context, attendance, users, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
          child: Column(
            children: [
              // Attendance Rate Card
              GlassCard(
                gradient: AppTheme.primaryGradient,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attendance Rate',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_attendanceRate.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Overall performance',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Stack(
                        children: [
                          CircularProgressIndicator(
                            value: _attendanceRate / 100,
                            strokeWidth: 8,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeCap: StrokeCap.round,
                          ),
                          Center(
                            child: Icon(
                              Icons.trending_up_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Stats grid
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Present',
                      value: '${attendance.todayPresent}',
                      icon: Icons.check_circle_rounded,
                      color: AppTheme.successColor,
                      subtitle: 'Today',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Late',
                      value: '${attendance.todayLate}',
                      icon: Icons.access_time_rounded,
                      color: AppTheme.warningColor,
                      subtitle: 'Today',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Check-ins',
                      value: '${attendance.todayCheckIns}',
                      icon: Icons.login_rounded,
                      color: AppTheme.accentColor,
                      subtitle: 'Today',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Total Users',
                      value: '${users.users.length}',
                      icon: Icons.people_rounded,
                      color: AppTheme.infoColor,
                      subtitle: 'Active',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.face_retouching_natural_rounded,
                  title: 'Face Scan',
                  subtitle: 'Check Attendance',
                  color: AppTheme.primaryColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FaceScanScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.qr_code_scanner_rounded,
                  title: 'Manual',
                  subtitle: 'Quick Entry',
                  color: AppTheme.accentColor,
                  onTap: () {
                    _showManualAttendanceDialog();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySchedule() {
    return Consumer<ScheduleProvider>(
      builder: (context, schedule, _) {
        final todaySchedules = schedule.todaySchedules;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Today\'s Schedule',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${todaySchedules.length} classes',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (todaySchedules.isEmpty)
                GlassCard(
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          color: AppTheme.textTertiary,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No classes scheduled today',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: todaySchedules.length,
                    itemBuilder: (context, index) {
                      final s = todaySchedules[index];
                      final colors = [
                        AppTheme.primaryColor,
                        AppTheme.accentColor,
                        AppTheme.warningColor,
                        AppTheme.infoColor,
                      ];
                      final color = colors[index % colors.length];

                      return Container(
                        width: 200,
                        margin: EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              color.withValues(alpha: 0.15),
                              color.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                          border: Border.all(
                            color: color.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              s.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                Icon(Icons.access_time, color: color, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${s.startTime} - ${s.endTime}',
                                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.room_rounded, color: AppTheme.textTertiary, size: 14),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    s.room ?? 'TBA',
                                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeeklyChart() {
    if (_weeklyStats.isEmpty) return const SizedBox.shrink();

    final maxVal = _weeklyStats.values.fold<int>(0, (a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Attendance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Check-in trend this week',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (maxVal + 2).toDouble(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => AppTheme.cardDark,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final day = _weeklyStats.keys.elementAt(group.x);
                        return BarTooltipItem(
                          '$day\n${rod.toY.toInt()}',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _weeklyStats.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _weeklyStats.keys.elementAt(index),
                                style: TextStyle(
                                  color: AppTheme.textTertiary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxVal / 4).ceilToDouble().clamp(1, double.infinity),
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.white.withValues(alpha: 0.05),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _weeklyStats.entries.toList().asMap().entries.map((entry) {
                    final isToday = entry.key == _weeklyStats.length - 1;
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.value.toDouble(),
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                          gradient: isToday
                              ? AppTheme.primaryGradient
                              : LinearGradient(
                                  colors: [
                                    AppTheme.primaryColor.withValues(alpha: 0.4),
                                    AppTheme.primaryColor.withValues(alpha: 0.2),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDistribution() {
    if (_statusDistribution.isEmpty) return const SizedBox.shrink();

    final total = _statusDistribution.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    final colors = {
      'Present': AppTheme.successColor,
      'Late': AppTheme.warningColor,
      'Absent': AppTheme.errorColor,
      'Leave': AppTheme.infoColor,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status Distribution',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Today\'s attendance breakdown',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                      sections: _statusDistribution.entries.map((e) {
                        final percentage = (e.value / total * 100);
                        return PieChartSectionData(
                          value: e.value.toDouble(),
                          color: colors[e.key] ?? AppTheme.textTertiary,
                          radius: 25,
                          title: percentage > 10 ? '${percentage.toStringAsFixed(0)}%' : '',
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: _statusDistribution.entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: colors[e.key],
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              e.key,
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${e.value}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Consumer<AttendanceProvider>(
      builder: (context, attendance, _) {
        final recentRecords = attendance.todayRecords.take(5).toList();

        return Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              if (recentRecords.isEmpty)
                GlassCard(
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          color: AppTheme.textTertiary,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No activity today yet',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...recentRecords.map((record) {
                  return GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              record.userName.substring(0, 1),
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${record.type} • ${record.time.substring(0, 5)}',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StatusBadge(status: record.status),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  void _showManualAttendanceDialog() {
    final userProvider = context.read<UserProvider>();
    final attendanceProvider = context.read<AttendanceProvider>();
    final auth = context.read<AuthProvider>();

    String? selectedUserId;
    String selectedType = 'Check-in';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.textTertiary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Manual Attendance',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // User selector
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select User',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    dropdownColor: AppTheme.inputDark,
                    style: const TextStyle(color: Colors.white),
                    items: userProvider.users
                        .where((u) => u.role != 'admin')
                        .map((u) => DropdownMenuItem(
                              value: u.id,
                              child: Text('${u.name} (${u.userId})'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setModalState(() => selectedUserId = value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Type selector
                  Row(
                    children: ['Check-in', 'Check-out'].map((type) {
                      final isSelected = selectedType == type;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setModalState(() => selectedType = type);
                          },
                          child: Container(
                            margin: EdgeInsets.only(
                              right: type == 'Check-in' ? 8 : 0,
                              left: type == 'Check-out' ? 8 : 0,
                            ),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor.withValues(alpha: 0.15)
                                  : AppTheme.inputDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.transparent,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                type,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: selectedUserId == null
                          ? null
                          : () async {
                              final user = await userProvider.getUserById(selectedUserId!);
                              if (user == null) return;

                              final now = DateTime.now();
                              final record = AttendanceModel(
                                id: const Uuid().v4(),
                                odlUserId: user.id,
                                userId: user.userId,
                                userName: user.name,
                                type: selectedType,
                                status: 'Present',
                                dateTime: now,
                                date: DateFormat('yyyy-MM-dd').format(now),
                                time: DateFormat('HH:mm:ss').format(now),
                                verified: false,
                                notes: 'Manual entry',
                                createdAt: now,
                              );

                              await attendanceProvider.recordAttendance(
                                record,
                                recordedBy: auth.currentUser?.id,
                              );

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('$selectedType recorded for ${user.name}'),
                                    backgroundColor: AppTheme.successColor,
                                  ),
                                );
                              }
                            },
                      child: const Text('Record Attendance'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
