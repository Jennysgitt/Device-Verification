class UserModel {
  final String id;
  final String email;
  final String? fullName;
  final String role;
  final String? studentId;
  final String? department;
  final String? profilePictureUrl;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.email,
    this.fullName,
    required this.role,
    this.studentId,
    this.department,
    this.profilePictureUrl,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle nested student_id from joins
    String? sId = json['student_id'] as String?;
    if (sId == null && json['student_ids'] != null) {
      final sIds = json['student_ids'];
      if (sIds is List && sIds.isNotEmpty) {
        sId = sIds[0]['student_id'];
      } else if (sIds is Map) {
        sId = sIds['student_id'];
      }
    }

    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      role: json['role'] as String? ?? 'student',
      studentId: sId,
      department: json['department'] as String?,
      profilePictureUrl: json['profile_picture_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'profile_picture_url': profilePictureUrl,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

