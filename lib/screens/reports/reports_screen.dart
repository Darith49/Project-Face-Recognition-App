import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/database_service.dart';
import '../../models/activity_log_model.dart';
import '../../widgets/glass_card.dart';


class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _db = DatabaseService();

  Map<String, int> _monthlyStats = {};
  Map<String, int> _statusDist = {};
  double _overallRate = 0;
  List<ActivityLogModel> _activityLogs = [];
  String _selectedPeriod = 'This Week';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final attendanceProvider = context.read<AttendanceProvider>();

    final monthly = await attendanceProvider.getMonthlyStats();
    final distribution = await attendanceProvider.getStatusDistribution();
    final rate = await attendanceProvider.getAttendanceRate();
    final logs = await _loadActivityLogs();

    if (mounted) {
      setState(() {
        _monthlyStats = monthly;
        _statusDist = distribution;
        _overallRate = rate;
        _activityLogs = logs;
      });
    }
  }

  Future<List<ActivityLogModel>> _loadActivityLogs() async {
    final results = await _db.query(
      'activity_logs',
      orderBy: 'createdAt DESC',
      limit: 50,
    );
    return results.map((m) => ActivityLogModel.fromMap(m)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildAnalyticsTab(),
                    _buildActivityLogTab(),
                  ],
                ),
              ),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.analytics_rounded,
              color: AppTheme.infoColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reports',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Analytics & activity logs',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textTertiary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        dividerHeight: 0,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Analytics'),
          Tab(text: 'Activity'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Attendance Rate Card
          GlassCard(
            gradient: AppTheme.primaryGradient,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overall Attendance Rate',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_overallRate.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Stack(
                        children: [
                          CircularProgressIndicator(
                            value: _overallRate / 100,
                            strokeWidth: 8,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeCap: StrokeCap.round,
                          ),
                          Center(
                            child: Text(
                              '${_overallRate.toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
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

          // Status Summary
          const SizedBox(height: 8),
          const Text(
            'Today\'s Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Consumer<AttendanceProvider>(
            builder: (context, attendance, _) {
              return Column(
                children: [
                  _buildSummaryRow('Check-ins', '${attendance.todayCheckIns}', Icons.login_rounded, AppTheme.accentColor),
                  _buildSummaryRow('Check-outs', '${attendance.todayCheckOuts}', Icons.logout_rounded, AppTheme.primaryColor),
                  _buildSummaryRow('Present', '${attendance.todayPresent}', Icons.check_circle_rounded, AppTheme.successColor),
                  _buildSummaryRow('Late', '${attendance.todayLate}', Icons.access_time_rounded, AppTheme.warningColor),
                ],
              );
            },
          ),

          // User stats
          const SizedBox(height: 20),
          const Text(
            'User Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Consumer<UserProvider>(
            builder: (context, users, _) {
              final withFace = users.users.where((u) => u.hasFaceData).length;
              final withoutFace = users.users.where((u) => !u.hasFaceData).length;

              return Column(
                children: [
                  _buildSummaryRow('Total Users', '${users.users.length}', Icons.people_rounded, AppTheme.primaryColor),
                  _buildSummaryRow('Students', '${users.students.length}', Icons.school_rounded, AppTheme.infoColor),
                  _buildSummaryRow('Teachers', '${users.teachers.length}', Icons.person_rounded, AppTheme.warningColor),
                  _buildSummaryRow('Face Registered', '$withFace', Icons.face_rounded, AppTheme.successColor),
                  _buildSummaryRow('No Face Data', '$withoutFace', Icons.face_retouching_off_rounded, AppTheme.errorColor),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['This Week', 'This Month', 'Last Month'].map((period) {
                final isSelected = _selectedPeriod == period;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPeriod = period),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor.withValues(alpha: 0.15)
                          : AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Text(
                      period,
                      style: TextStyle(
                        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Monthly trend chart
          const Text(
            'Attendance Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(18),
            child: SizedBox(
              height: 200,
              child: _monthlyStats.isNotEmpty
                  ? LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.white.withValues(alpha: 0.05),
                            strokeWidth: 1,
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
                              interval: 5,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 && index < _monthlyStats.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      _monthlyStats.keys.elementAt(index),
                                      style: TextStyle(
                                        color: AppTheme.textTertiary,
                                        fontSize: 10,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _monthlyStats.entries
                                .toList()
                                .asMap()
                                .entries
                                .map((e) => FlSpot(
                                      e.key.toDouble(),
                                      e.value.value.toDouble(),
                                    ))
                                .toList(),
                            isCurved: true,
                            gradient: AppTheme.primaryGradient,
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryColor.withValues(alpha: 0.2),
                                  AppTheme.primaryColor.withValues(alpha: 0.0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const Center(
                      child: Text(
                        'No data available',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 20),

          // Status distribution
          const Text(
            'Status Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(18),
            child: _statusDist.isNotEmpty
                ? Column(
                    children: _statusDist.entries.map((e) {
                      final total = _statusDist.values.fold<int>(0, (a, b) => a + b);
                      final percentage = total > 0 ? e.value / total : 0.0;
                      final colors = {
                        'Present': AppTheme.successColor,
                        'Late': AppTheme.warningColor,
                        'Absent': AppTheme.errorColor,
                        'Leave': AppTheme.infoColor,
                      };
                      final color = colors[e.key] ?? AppTheme.textTertiary;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  e.key,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${e.value} (${(percentage * 100).toStringAsFixed(0)}%)',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage,
                                backgroundColor: Colors.white.withValues(alpha: 0.05),
                                valueColor: AlwaysStoppedAnimation<Color>(color),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                : const Center(
                    child: Text(
                      'No data available',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
          ),

          // Class breakdown
          const SizedBox(height: 20),
          const Text(
            'Class Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Consumer<UserProvider>(
            builder: (context, users, _) {
              final classes = users.allClasses;
              if (classes.isEmpty) {
                return GlassCard(
                  child: Center(
                    child: Text('No class data', style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                );
              }

              return Column(
                children: classes.map((className) {
                  final classStudents = users.filterUsers(className: className);
                  return GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.class_rounded,
                              color: AppTheme.primaryColor, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              className,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${classStudents.length} students',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppTheme.textTertiary),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildActivityLogTab() {
    if (_activityLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, color: AppTheme.textTertiary, size: 48),
            const SizedBox(height: 12),
            const Text(
              'No activity logs yet',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        itemCount: _activityLogs.length,
        itemBuilder: (context, index) {
          final log = _activityLogs[index];
          return GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      log.actionIcon,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.description,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${log.userName} • ${DateFormat('dd MMM yyyy, hh:mm a').format(log.createdAt)}',
                        style: const TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
