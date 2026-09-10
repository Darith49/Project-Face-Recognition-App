import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/attendance_provider.dart';

import '../../models/attendance_model.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_badge.dart';
import '../face_recognition/face_scan_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  String? _selectedStatus;


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = context.read<AttendanceProvider>();
    await provider.loadTodayAttendance();
    await provider.loadAllAttendance();
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
                    _buildTodayTab(),
                    _buildHistoryTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FaceScanScreen()),
          ).then((_) => _loadData());
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.face_retouching_natural_rounded),
        label: const Text('Face Scan',
            style: TextStyle(fontWeight: FontWeight.w600)),
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
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.fact_check_rounded,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendance',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Track and manage attendance records',
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
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        dividerHeight: 0,
        tabs: const [
          Tab(text: 'Today'),
          Tab(text: 'History'),
        ],
      ),
    );
  }

  Widget _buildTodayTab() {
    return Consumer<AttendanceProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
        }

        final records = provider.todayRecords;

        if (records.isEmpty) {
          return _buildEmptyState(
            icon: Icons.fact_check_outlined,
            title: 'No attendance records today',
            subtitle: 'Start by scanning a face to record attendance',
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          color: AppTheme.primaryColor,
          child: ListView.builder(
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            itemCount: records.length,
            itemBuilder: (context, index) {
              return FadeInUp(
                duration: const Duration(milliseconds: 400),
                delay: Duration(milliseconds: index * 50),
                child: _buildAttendanceCard(records[index]),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return Consumer<AttendanceProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // Filters
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              child: Column(
                children: [
                  // Date picker
                  GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppTheme.primaryColor,
                                surface: AppTheme.cardDark,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null) {
                        setState(() => _selectedDate = date);
                        await provider.loadAttendanceByDate(
                          DateFormat('yyyy-MM-dd').format(date),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.inputDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              color: AppTheme.primaryColor, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('dd MMMM yyyy').format(_selectedDate),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_drop_down_rounded,
                              color: AppTheme.textTertiary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Status filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', _selectedStatus == null, () {
                          setState(() => _selectedStatus = null);
                        }),
                        _buildFilterChip('Present', _selectedStatus == 'Present', () {
                          setState(() => _selectedStatus = 'Present');
                        }),
                        _buildFilterChip('Late', _selectedStatus == 'Late', () {
                          setState(() => _selectedStatus = 'Late');
                        }),
                        _buildFilterChip('Absent', _selectedStatus == 'Absent', () {
                          setState(() => _selectedStatus = 'Absent');
                        }),
                        _buildFilterChip('Leave', _selectedStatus == 'Leave', () {
                          setState(() => _selectedStatus = 'Leave');
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Records list
            Expanded(
              child: Builder(
                builder: (context) {
                  var records = provider.attendanceRecords;
                  if (_selectedStatus != null) {
                    records = records
                        .where((r) => r.status == _selectedStatus)
                        .toList();
                  }

                  if (records.isEmpty) {
                    return _buildEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No records found',
                      subtitle: 'Try changing the date or filters',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMD),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      return _buildAttendanceCard(records[index]);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor.withValues(alpha: 0.15)
              : AppTheme.inputDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.primaryColor : AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceModel record) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: record.type == 'Check-in'
                  ? const LinearGradient(
                      colors: [Color(0xFF00D4AA), Color(0xFF00B894)],
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF4DABF7)],
                    ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              record.type == 'Check-in'
                  ? Icons.login_rounded
                  : Icons.logout_rounded,
              color: Colors.white,
              size: 22,
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
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: AppTheme.textTertiary,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${record.type} • ${record.time.substring(0, 5)}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if (record.verified) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.verified_rounded,
                        color: AppTheme.successColor,
                        size: 14,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusBadge(status: record.status),
              if (record.confidenceScore != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${(record.confidenceScore! * 100).toStringAsFixed(0)}% match',
                  style: TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: AppTheme.textTertiary, size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
