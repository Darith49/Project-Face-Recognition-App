class ActivityLogModel {
  final String id;
  final String userId;
  final String userName;
  final String action; // e.g., 'face_registered', 'attendance_checked', 'profile_updated'
  final String description;
  final String? targetId;
  final String? targetType;
  final DateTime createdAt;

  ActivityLogModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.action,
    required this.description,
    this.targetId,
    this.targetType,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'action': action,
      'description': description,
      'targetId': targetId,
      'targetType': targetType,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ActivityLogModel.fromMap(Map<String, dynamic> map) {
    return ActivityLogModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      action: map['action'] ?? '',
      description: map['description'] ?? '',
      targetId: map['targetId'],
      targetType: map['targetType'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  String get actionIcon {
    switch (action) {
      case 'face_registered':
        return '🔐';
      case 'attendance_check_in':
        return '✅';
      case 'attendance_check_out':
        return '🚪';
      case 'profile_updated':
        return '✏️';
      case 'user_created':
        return '👤';
      case 'user_deleted':
        return '🗑️';
      case 'schedule_created':
        return '📅';
      case 'attendance_modified':
        return '📝';
      default:
        return '📋';
    }
  }
}
