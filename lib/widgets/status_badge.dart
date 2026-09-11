import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double? fontSize;

  const StatusBadge({super.key, required this.status, this.fontSize});

  Color get _color {
    switch (status) {
      case 'Present':
        return AppTheme.successColor;
      case 'Late':
        return AppTheme.warningColor;
      case 'Absent':
        return AppTheme.errorColor;
      case 'Leave':
        return AppTheme.infoColor;
      case 'Check-in':
        return AppTheme.accentColor;
      case 'Check-out':
        return AppTheme.primaryLight;
      default:
        return AppTheme.textTertiary;
    }
  }

  IconData get _icon {
    switch (status) {
      case 'Present':
        return Icons.check_circle_rounded;
      case 'Late':
        return Icons.access_time_rounded;
      case 'Absent':
        return Icons.cancel_rounded;
      case 'Leave':
        return Icons.event_busy_rounded;
      case 'Check-in':
        return Icons.login_rounded;
      case 'Check-out':
        return Icons.logout_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = fontSize ?? 11;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, color: _color, size: size + 3),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: _color,
              fontSize: size,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
