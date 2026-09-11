import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
import '../../widgets/section_header.dart';
import '../../widgets/empty_state.dart';
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
  bool _statsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final attendanceProvider = context.read<AttendanceProvider>();
    final userProvider = context.read<UserProvider>();
    final scheduleProvider = context.read<ScheduleProvider>();

    // Load essential data first (fast)
    await Future.wait([
      attendanceProvider.loadTodayAttendance(),
      userProvider.loadUsers(),
      scheduleProvider.loadSchedules(),
    ]);

    // Load stats lazily after the first frame renders
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final weekly = await attendanceProvider.getWeeklyStats();
        final distribution = await attendanceProvider.getStatusDistribution();
        final rate = await attendanceProvider.getAttendanceRate();

        if (mounted) {
          setState(() {
            _weeklyStats = weekly;
            _statusDistribution = distribution;
            _attendanceRate = rate;
            _statsLoaded = true;
          });
        }
      });
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
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
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildStatsGrid()),
                SliverToBoxAdapter(child: _buildQuickActions()),
                SliverToBoxAdapter(child: _buildTodaySchedule()),
                if (_statsLoaded) ...[
                  SliverToBoxAdapter(
                    child: RepaintBoundary(child: _buildWeeklyChart()),
                  ),
                  SliverToBoxAdapter(
                    child: RepaintBoundary(child: _buildStatusDistribution()),
                  ),
                ],
                SliverToBoxAdapter(child: _buildRecentActivity()),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
          padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingMD, AppTheme.spacingMD, AppTheme.spacingMD, 8),
          child: Row(
            children: [
              // Profile Avatar
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    auth.currentUser?.name.substring(0, 1).toUpperCase() ?? 'A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
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
                      '$_greeting, ${auth.currentUser?.name.split(' ').first ?? 'User'} 👋',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      DateFormat('EEEE, dd MMM yyyy').format(DateTime.now()),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Notification + Logout
              GestureDetector(
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
                    );
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: AppTheme.textSecondary,
                    size: 18,
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
              // Attendance Rate Card — hero card
              GlassCard(
                gradient: AppTheme.primaryGradient,
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attendance Rate',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_attendanceRate.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Overall performance',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: _attendanceRate / 100,
                            strokeWidth: 6,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.15),
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                            strokeCap: StrokeCap.round,
                          ),
                          const Icon(
                            Icons.trending_up_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
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
                  const SizedBox(width: 10),
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
              const SizedBox(height: 10),
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
                  const SizedBox(width: 10),
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
          const SectionHeader(title: 'Quick Actions'),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.face_retouching_natural_rounded,
                  title: 'Face Scan',
                  subtitle: 'Check Attendance',
                  color: AppTheme.primaryColor,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FaceScanScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.edit_note_rounded,
                  title: 'Manual',
                  subtitle: 'Quick Entry',
                  color: AppTheme.accentColor,
                  onTap: () {
                    HapticFeedback.lightImpact();
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
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.12),
              color.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: color.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
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
              SectionHeader(
                title: "Today's Schedule",
                trailing: Text(
                  '${todaySchedules.length} classes',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ),
              if (todaySchedules.isEmpty)
                GlassCard(
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          color: AppTheme.textTertiary,
                          size: 36,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'No classes scheduled today',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 95,
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
                        width: 190,
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              color.withValues(alpha: 0.12),
                              color.withValues(alpha: 0.04),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLarge),
                          border: Border.all(
                            color: color.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              s.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                Icon(Icons.access_time,
                                    color: color, size: 13),
                                const SizedBox(width: 4),
                                Text(
                                  '${s.startTime} - ${s.endTime}',
                                  style: TextStyle(
                                      color: color,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.room_rounded,
                                    color: AppTheme.textTertiary, size: 13),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    s.room ?? 'TBA',
                                    style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 11),
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

    final maxVal =
        _weeklyStats.values.fold<int>(0, (a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Weekly Attendance',
              subtitle: 'Check-in trend this week',
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (maxVal + 2).toDouble(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => AppTheme.cardDarkElevated,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final day =
                            _weeklyStats.keys.elementAt(group.x);
                        return BarTooltipItem(
                          '$day\n${rod.toY.toInt()}',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
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
                          if (index >= 0 &&
                              index < _weeklyStats.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                _weeklyStats.keys.elementAt(index),
                                style: const TextStyle(
                                  color: AppTheme.textTertiary,
                                  fontSize: 10,
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
                    horizontalInterval:
                        (maxVal / 4).ceilToDouble().clamp(1, double.infinity),
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.white.withValues(alpha: 0.04),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _weeklyStats.entries
                      .toList()
                      .asMap()
                      .entries
                      .map((entry) {
                    final isToday =
                        entry.key == _weeklyStats.length - 1;
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.value.toDouble(),
                          width: 18,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5),
                          ),
                          gradient: isToday
                              ? AppTheme.primaryGradient
                              : LinearGradient(
                                  colors: [
                                    AppTheme.primaryColor
                                        .withValues(alpha: 0.35),
                                    AppTheme.primaryColor
                                        .withValues(alpha: 0.15),
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

    final total =
        _statusDistribution.values.fold<int>(0, (a, b) => a + b);
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
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Status Distribution',
              subtitle: "Today's attendance breakdown",
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 28,
                      sections:
                          _statusDistribution.entries.map((e) {
                        final percentage = (e.value / total * 100);
                        return PieChartSectionData(
                          value: e.value.toDouble(),
                          color: colors[e.key] ?? AppTheme.textTertiary,
                          radius: 22,
                          title: percentage > 10
                              ? '${percentage.toStringAsFixed(0)}%'
                              : '',
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    children: _statusDistribution.entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: colors[e.key],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              e.key,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${e.value}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
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
              const SectionHeader(title: 'Recent Activity'),
              if (recentRecords.isEmpty)
                GlassCard(
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          color: AppTheme.textTertiary,
                          size: 36,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'No activity today yet',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...recentRecords.map((record) {
                  return GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor
                                .withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Center(
                            child: Text(
                              record.userName.substring(0, 1),
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${record.type} • ${record.time.substring(0, 5)}',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11,
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
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.textTertiary.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Manual Attendance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 18),

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
                  const SizedBox(height: 14),

                  // Type selector
                  Row(
                    children: ['Check-in', 'Check-out'].map((type) {
                      final isSelected = selectedType == type;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setModalState(() => selectedType = type);
                          },
                          child: Container(
                            margin: EdgeInsets.only(
                              right: type == 'Check-in' ? 6 : 0,
                              left: type == 'Check-out' ? 6 : 0,
                            ),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                      .withValues(alpha: 0.12)
                                  : AppTheme.inputDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.white
                                        .withValues(alpha: 0.04),
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
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: selectedUserId == null
                          ? null
                          : () async {
                              final user = await userProvider
                                  .getUserById(selectedUserId!);
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
                                date: DateFormat('yyyy-MM-dd')
                                    .format(now),
                                time: DateFormat('HH:mm:ss')
                                    .format(now),
                                verified: false,
                                notes: 'Manual entry',
                                createdAt: now,
                              );

                              await attendanceProvider
                                  .recordAttendance(
                                record,
                                recordedBy: auth.currentUser?.id,
                              );

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '$selectedType recorded for ${user.name}'),
                                    backgroundColor:
                                        AppTheme.successColor,
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
