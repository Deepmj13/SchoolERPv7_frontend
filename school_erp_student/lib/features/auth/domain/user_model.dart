class UserModel {
  final String token;
  final String role;
  final String userId;
  final String? teacherId;
  final String? studentId;

  UserModel({
    required this.token,
    required this.role,
    required this.userId,
    this.teacherId,
    this.studentId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        token: json['token'] as String,
        role: json['role'] as String,
        userId: json['userId'].toString(),
        teacherId: json['teacherId']?.toString(),
        studentId: json['studentId']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'token': token,
        'role': role,
        'userId': userId,
        'teacherId': teacherId,
        'studentId': studentId,
      };

  bool get isStudent => role == 'student';
}
