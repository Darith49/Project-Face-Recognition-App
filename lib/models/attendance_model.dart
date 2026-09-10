class AttendanceModel {
  final String id;
  final String odlUserId; // references UserModel.id
  final String userId; // Student/Employee ID
  final String userName;
  final String type; // Check-in, Check-out
  final String status; // Present, Late, Absent, Leave
  final DateTime dateTime;
  final String date; // yyyy-MM-dd
  final String time; // HH:mm:ss
  final String? scheduleId;
  final String? scheduleName;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final bool verified;
  final double? confidenceScore;
  final String? notes;
  final DateTime createdAt;

  AttendanceModel({
    required this.id,
    required this.odlUserId,
    required this.userId,
    required this.userName,
    required this.type,
    required this.status,
    required this.dateTime,
    required this.date,
    required this.time,
    this.scheduleId,
    this.scheduleName,
    this.latitude,
    this.longitude,
    this.locationName,
    this.verified = false,
    this.confidenceScore,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'odlUserId': odlUserId,
      'userId': userId,
      'userName': userName,
      'type': type,
      'status': status,
      'dateTime': dateTime.toIso8601String(),
      'date': date,
      'time': time,
      'scheduleId': scheduleId,
      'scheduleName': scheduleName,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'verified': verified ? 1 : 0,
      'confidenceScore': confidenceScore,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: map['id'] ?? '',
      odlUserId: map['odlUserId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      type: map['type'] ?? '',
      status: map['status'] ?? '',
      dateTime: DateTime.parse(map['dateTime']),
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      scheduleId: map['scheduleId'],
      scheduleName: map['scheduleName'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      locationName: map['locationName'],
      verified: map['verified'] == 1,
      confidenceScore: map['confidenceScore']?.toDouble(),
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  AttendanceModel copyWith({
    String? id,
    String? odlUserId,
    String? userId,
    String? userName,
    String? type,
    String? status,
    DateTime? dateTime,
    String? date,
    String? time,
    String? scheduleId,
    String? scheduleName,
    double? latitude,
    double? longitude,
    String? locationName,
    bool? verified,
    double? confidenceScore,
    String? notes,
    DateTime? createdAt,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      odlUserId: odlUserId ?? this.odlUserId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      type: type ?? this.type,
      status: status ?? this.status,
      dateTime: dateTime ?? this.dateTime,
      date: date ?? this.date,
      time: time ?? this.time,
      scheduleId: scheduleId ?? this.scheduleId,
      scheduleName: scheduleName ?? this.scheduleName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      verified: verified ?? this.verified,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
