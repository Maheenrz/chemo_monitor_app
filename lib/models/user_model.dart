class UserModel {
  final String uid;
  final String email;
  final String role; // 'doctor' or 'patient'
  final String? assignedDoctorId; // Null if user is a doctor
  final String? myDoctorCode; // Only for doctors (to share with patients)

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.assignedDoctorId,
    this.myDoctorCode,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'assignedDoctorId': assignedDoctorId,
      'myDoctorCode': myDoctorCode,
    };
  }

  // Create from Firestore Document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'patient',
      assignedDoctorId: map['assignedDoctorId'],
      myDoctorCode: map['myDoctorCode'],
    );
  }
}