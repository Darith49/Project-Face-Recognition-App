import 'dart:convert';

class UserModel {
  final String id;
  final String userId; // Student ID, Employee ID
  final String name;
  final String email;
  final String password;
  final String gender;
  final String role; // admin, teacher, student, employee
  final String? group;
  final String? className;
  final String? department;
  final String? subject;
  final String? phone;
  final String? profileImage;
  final List<String> faceData; // Base64 encoded face embeddings
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.password,
    required this.gender,
    required this.role,
    this.group,
    this.className,
    this.department,
    this.subject,
    this.phone,
    this.profileImage,
    this.faceData = const [],
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'email': email,
      'password': password,
      'gender': gender,
      'role': role,
      'groupName': group,
      'className': className,
      'department': department,
      'subject': subject,
      'phone': phone,
      'profileImage': profileImage,
      'faceData': jsonEncode(faceData),
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    List<String> parsedFaceData = [];
    if (map['faceData'] != null && map['faceData'].toString().isNotEmpty) {
      try {
        parsedFaceData = List<String>.from(jsonDecode(map['faceData']));
      } catch (_) {
        parsedFaceData = [];
      }
    }

    return UserModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      gender: map['gender'] ?? '',
      role: map['role'] ?? 'student',
      group: map['groupName'],
      className: map['className'],
      department: map['department'],
      subject: map['subject'],
      phone: map['phone'],
      profileImage: map['profileImage'],
      faceData: parsedFaceData,
      isActive: map['isActive'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  UserModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    String? password,
    String? gender,
    String? role,
    String? group,
    String? className,
    String? department,
    String? subject,
    String? phone,
    String? profileImage,
    List<String>? faceData,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      gender: gender ?? this.gender,
      role: role ?? this.role,
      group: group ?? this.group,
      className: className ?? this.className,
      department: department ?? this.department,
      subject: subject ?? this.subject,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      faceData: faceData ?? this.faceData,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get hasFaceData => faceData.isNotEmpty;
}
