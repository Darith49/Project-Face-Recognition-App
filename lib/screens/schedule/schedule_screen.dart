import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/schedule_model.dart';
import '../../widgets/glass_card.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  String _selectedDay = '';
  final _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = _days[now.weekday - 1];
    _loadData();
  }

  Future<void> _loadData() async {
    await context.read<ScheduleProvider>().loadSchedules();
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
              _buildDaySelector(),
              Expanded(child: _buildScheduleList()),
            ],
          ),
        ),
      ),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (!auth.hasPermission('manage_schedules')) return const SizedBox.shrink();
          return FloatingActionButton(
            onPressed: () => _showCreateScheduleDialog(),
            backgroundColor: AppTheme.primaryColor,
            child: const Icon(Icons.add_rounded),
          );
        },
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
              color: AppTheme.warningColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: AppTheme.warningColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Schedule',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Manage class & work schedules',
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

  Widget _buildDaySelector() {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _days.length,
        itemBuilder: (context, index) {
          final day = _days[index];
          final isSelected = _selectedDay == day;
          final isToday = _days[DateTime.now().weekday - 1] == day;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedDay = day);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: isToday && !isSelected
                    ? Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.5))
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                day.substring(0, 3),
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScheduleList() {
    return Consumer<ScheduleProvider>(
      builder: (context, provider, _) {
        final schedules = provider.getSchedulesByDay(_selectedDay);

        if (schedules.isEmpty) {
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
                  child: Icon(Icons.event_available_rounded,
                      color: AppTheme.textTertiary, size: 48),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No classes scheduled',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'No schedule for $_selectedDay',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
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
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              return FadeInUp(
                duration: const Duration(milliseconds: 400),
                delay: Duration(milliseconds: index * 80),
                child: _buildScheduleCard(schedules[index], index),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildScheduleCard(ScheduleModel schedule, int index) {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.accentColor,
      AppTheme.warningColor,
      AppTheme.infoColor,
      AppTheme.errorColor,
    ];
    final color = colors[index % colors.length];

    return Dismissible(
      key: Key(schedule.id),
      direction: context.read<AuthProvider>().hasPermission('manage_schedules')
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: const Icon(Icons.delete_rounded, color: AppTheme.errorColor),
      ),
      confirmDismiss: (_) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.cardDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Delete Schedule', style: TextStyle(color: Colors.white)),
            content: Text('Delete "${schedule.name}"?',
                style: const TextStyle(color: AppTheme.textSecondary)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        context.read<ScheduleProvider>().deleteSchedule(schedule.id);
      },
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Time column
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    schedule.startTime,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 10,
                    color: color.withValues(alpha: 0.3),
                    margin: const EdgeInsets.symmetric(vertical: 2),
                  ),
                  Text(
                    schedule.endTime,
                    style: TextStyle(
                      color: color.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Info column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (schedule.className != null) ...[
                        Icon(Icons.class_rounded, color: AppTheme.textTertiary, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          schedule.className!,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (schedule.room != null) ...[
                        Icon(Icons.room_rounded, color: AppTheme.textTertiary, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          schedule.room!,
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                  if (schedule.teacherName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(Icons.person_rounded, color: AppTheme.textTertiary, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            schedule.teacherName!,
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Color indicator
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateScheduleDialog() {
    final nameController = TextEditingController();
    final subjectController = TextEditingController();
    final classController = TextEditingController();
    final roomController = TextEditingController();
    final teacherController = TextEditingController();
    String selectedDay = _selectedDay;
    TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textTertiary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add Schedule',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          TextField(
                            controller: nameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Schedule Name',
                              prefixIcon: Icon(Icons.event_note_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: subjectController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Subject',
                              prefixIcon: Icon(Icons.book_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: classController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Class',
                              prefixIcon: Icon(Icons.class_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: roomController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Room',
                              prefixIcon: Icon(Icons.room_outlined),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: teacherController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Teacher Name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            initialValue: selectedDay,
                            decoration: const InputDecoration(
                              labelText: 'Day of Week',
                              prefixIcon: Icon(Icons.calendar_today_outlined),
                            ),
                            dropdownColor: AppTheme.inputDark,
                            style: const TextStyle(color: Colors.white),
                            items: _days.map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d),
                            )).toList(),
                            onChanged: (v) => setModalState(() => selectedDay = v!),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: startTime,
                                      builder: (context, child) => Theme(
                                        data: ThemeData.dark().copyWith(
                                          colorScheme: const ColorScheme.dark(primary: AppTheme.primaryColor),
                                        ),
                                        child: child!,
                                      ),
                                    );
                                    if (time != null) setModalState(() => startTime = time);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppTheme.inputDark,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.access_time, color: AppTheme.textTertiary, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text('to', style: TextStyle(color: AppTheme.textSecondary)),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: endTime,
                                      builder: (context, child) => Theme(
                                        data: ThemeData.dark().copyWith(
                                          colorScheme: const ColorScheme.dark(primary: AppTheme.primaryColor),
                                        ),
                                        child: child!,
                                      ),
                                    );
                                    if (time != null) setModalState(() => endTime = time);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppTheme.inputDark,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.access_time, color: AppTheme.textTertiary, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (nameController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter a schedule name'),
                                      backgroundColor: AppTheme.errorColor,
                                    ),
                                  );
                                  return;
                                }

                                final now = DateTime.now();
                                final schedule = ScheduleModel(
                                  id: const Uuid().v4(),
                                  name: nameController.text,
                                  subject: subjectController.text.isEmpty ? null : subjectController.text,
                                  className: classController.text.isEmpty ? null : classController.text,
                                  room: roomController.text.isEmpty ? null : roomController.text,
                                  teacherName: teacherController.text.isEmpty ? null : teacherController.text,
                                  dayOfWeek: selectedDay,
                                  startTime: '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                                  endTime: '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                                  createdAt: now,
                                  updatedAt: now,
                                );

                                final auth = context.read<AuthProvider>();
                                await context.read<ScheduleProvider>().createSchedule(
                                      schedule,
                                      createdBy: auth.currentUser?.id,
                                    );

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Schedule "${schedule.name}" created'),
                                      backgroundColor: AppTheme.successColor,
                                    ),
                                  );
                                }
                              },
                              child: const Text('Create Schedule'),
                            ),
                          ),
                        ],
                      ),
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
