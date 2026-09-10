import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../attendance/attendance_screen.dart';
import '../users/users_screen.dart';
import '../schedule/schedule_screen.dart';
import '../reports/reports_screen.dart';


class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  List<Widget> _getScreens(AuthProvider auth) {
    final screens = <Widget>[
      const DashboardScreen(),
      const AttendanceScreen(),
    ];

    if (auth.hasPermission('manage_users')) {
      screens.add(const UsersScreen());
    }

    screens.add(const ScheduleScreen());

    if (auth.hasPermission('view_reports')) {
      screens.add(const ReportsScreen());
    }

    return screens;
  }

  List<BottomNavigationBarItem> _getNavItems(AuthProvider auth) {
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_rounded),
        activeIcon: Icon(Icons.dashboard_rounded),
        label: 'Dashboard',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.fact_check_outlined),
        activeIcon: Icon(Icons.fact_check_rounded),
        label: 'Attendance',
      ),
    ];

    if (auth.hasPermission('manage_users')) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.people_outline_rounded),
        activeIcon: Icon(Icons.people_rounded),
        label: 'Users',
      ));
    }

    items.add(const BottomNavigationBarItem(
      icon: Icon(Icons.calendar_month_outlined),
      activeIcon: Icon(Icons.calendar_month_rounded),
      label: 'Schedule',
    ));

    if (auth.hasPermission('view_reports')) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.analytics_outlined),
        activeIcon: Icon(Icons.analytics_rounded),
        label: 'Reports',
      ));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final screens = _getScreens(auth);
        final navItems = _getNavItems(auth);

        // Clamp index if roles changed
        if (_currentIndex >= screens.length) {
          _currentIndex = 0;
        }

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  items: navItems,
                  backgroundColor: Colors.transparent,
                  selectedItemColor: AppTheme.primaryColor,
                  unselectedItemColor: AppTheme.textTertiary,
                  type: BottomNavigationBarType.fixed,
                  elevation: 0,
                  selectedFontSize: 12,
                  unselectedFontSize: 11,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
