class ScheduleModel {
  final String id;
  final String name;
  final String? subject;
  final String? className;
  final String? department;
  final String? room;
  final String? teacherId;
  final String? teacherName;
  final String dayOfWeek; // Monday, Tuesday, etc.
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final double? latitude;
  final double? longitude;
  final double? radiusMeters;
  final String? locationName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ScheduleModel({
    required this.id,
    required this.name,
    this.subject,
    this.className,
    this.department,
    this.room,
    this.teacherId,
    this.teacherName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.latitude,
    this.longitude,
    this.radiusMeters,
    this.locationName,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'subject': subject,
      'className': className,
      'department': department,
      'room': room,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'locationName': locationName,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ScheduleModel.fromMap(Map<String, dynamic> map) {
    return ScheduleModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      subject: map['subject'],
      className: map['className'],
      department: map['department'],
      room: map['room'],
      teacherId: map['teacherId'],
      teacherName: map['teacherName'],
      dayOfWeek: map['dayOfWeek'] ?? '',
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      radiusMeters: map['radiusMeters']?.toDouble(),
      locationName: map['locationName'],
      isActive: map['isActive'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}
