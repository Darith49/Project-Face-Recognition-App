import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  // Cache screens that have been visited — lazy loading instead of IndexedStack
  final Map<int, Widget> _screenCache = {};

  Widget _getScreen(int index, AuthProvider auth) {
    if (_screenCache.containsKey(index)) {
      return _screenCache[index]!;
    }

    final allScreens = _getAllScreens(auth);
    if (index < allScreens.length) {
      _screenCache[index] = allScreens[index];
      return _screenCache[index]!;
    }
    return const SizedBox.shrink();
  }

  List<Widget> _getAllScreens(AuthProvider auth) {
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

  List<_NavItem> _getNavItems(AuthProvider auth) {
    final items = <_NavItem>[
      _NavItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        label: 'Home',
      ),
      _NavItem(
        icon: Icons.fact_check_outlined,
        activeIcon: Icons.fact_check_rounded,
        label: 'Attendance',
      ),
    ];

    if (auth.hasPermission('manage_users')) {
      items.add(_NavItem(
        icon: Icons.people_outline_rounded,
        activeIcon: Icons.people_rounded,
        label: 'Users',
      ));
    }

    items.add(_NavItem(
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month_rounded,
      label: 'Schedule',
    ));

    if (auth.hasPermission('view_reports')) {
      items.add(_NavItem(
        icon: Icons.analytics_outlined,
        activeIcon: Icons.analytics_rounded,
        label: 'Reports',
      ));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final navItems = _getNavItems(auth);
        final totalScreens = _getAllScreens(auth).length;

        // Clamp index if roles changed
        if (_currentIndex >= totalScreens) {
          _currentIndex = 0;
          _screenCache.clear();
        }

        return Scaffold(
          // Lazy-load only the current screen (huge perf win over IndexedStack)
          body: _getScreen(_currentIndex, auth),
          bottomNavigationBar: _buildNavBar(navItems),
          extendBody: false,
        );
      },
    );
  }

  Widget _buildNavBar(List<_NavItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.04),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isActive = _currentIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_currentIndex != index) {
                      HapticFeedback.selectionClick();
                      setState(() => _currentIndex = index);
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: _NavBarItem(
                    icon: isActive ? item.activeIcon : item.icon,
                    label: item.label,
                    isActive: isActive,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppTheme.animFast,
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Active indicator dot
          AnimatedContainer(
            duration: AppTheme.animFast,
            width: isActive ? 20 : 0,
            height: 3,
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: isActive ? AppTheme.primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Icon(
            icon,
            color: isActive ? AppTheme.primaryColor : AppTheme.textTertiary,
            size: 22,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: isActive ? AppTheme.primaryColor : AppTheme.textTertiary,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
