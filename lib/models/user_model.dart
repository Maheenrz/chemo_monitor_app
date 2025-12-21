import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String role; // 'doctor' or 'patient'
  final String name;
  final String? phoneNumber;
  final String? gender;
  final int? age;
  final String? profileImageUrl;
  final DateTime createdAt;
  
  // Doctor-specific
  final String? doctorCode;
  final String? specialization;
  
  // Patient-specific
  final String? assignedDoctorId;
  final String? bloodGroup;
  final String? diagnosisDate;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.name,
    this.phoneNumber,
    this.gender,
    this.age,
    this.profileImageUrl,
    required this.createdAt,
    this.doctorCode,
    this.specialization,
    this.assignedDoctorId,
    this.bloodGroup,
    this.diagnosisDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'name': name,
      'phoneNumber': phoneNumber,
      'gender': gender,
      'age': age,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'doctorCode': doctorCode,
      'specialization': specialization,
      'assignedDoctorId': assignedDoctorId,
      'bloodGroup': bloodGroup,
      'diagnosisDate': diagnosisDate,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      name: map['name'] ?? 'User',
      phoneNumber: map['phoneNumber'],
      gender: map['gender'],
      age: map['age'],
      profileImageUrl: map['profileImageUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      doctorCode: map['doctorCode'],
      specialization: map['specialization'],
      assignedDoctorId: map['assignedDoctorId'],
      bloodGroup: map['bloodGroup'],
      diagnosisDate: map['diagnosisDate'],
    );
  }

  // Get initials for avatar
  String getInitials() {
    List<String> nameParts = name.trim().split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  // Copy with method for easy updates
  UserModel copyWith({
    String? uid,
    String? email,
    String? role,
    String? name,
    String? phoneNumber,
    String? gender,
    int? age,
    String? profileImageUrl,
    DateTime? createdAt,
    String? doctorCode,
    String? specialization,
    String? assignedDoctorId,
    String? bloodGroup,
    String? diagnosisDate,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      doctorCode: doctorCode ?? this.doctorCode,
      specialization: specialization ?? this.specialization,
      assignedDoctorId: assignedDoctorId ?? this.assignedDoctorId,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      diagnosisDate: diagnosisDate ?? this.diagnosisDate,
    );
  }
}