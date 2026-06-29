class TeacherClass {
  final String classId;
  final String className;
  final String section;
  final String subjectId;
  final String subjectName;
  final String? classTeacherId;

  TeacherClass({
    required this.classId,
    required this.className,
    required this.section,
    required this.subjectId,
    required this.subjectName,
    this.classTeacherId,
  });

  factory TeacherClass.fromJson(Map<String, dynamic> json) => TeacherClass(
        classId: json['class_id'] as String,
        className: json['class_name'] as String,
        section: json['section'] as String,
        subjectId: json['subject_id'] as String,
        subjectName: json['subject_name'] as String,
        classTeacherId: json['class_teacher_id'] as String?,
      );

  String get display => '$className - $section';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeacherClass &&
          classId == other.classId &&
          subjectId == other.subjectId;

  @override
  int get hashCode => Object.hash(classId, subjectId);
}

class ClassModel {
  final String id;
  final String name;
  final String section;
  final String? classTeacherId;
  final String? classTeacherName;
  final int studentCount;

  ClassModel({
    required this.id,
    required this.name,
    required this.section,
    this.classTeacherId,
    this.classTeacherName,
    required this.studentCount,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) => ClassModel(
        id: json['id'] as String,
        name: json['name'] as String,
        section: json['section'] as String,
        classTeacherId: json['class_teacher_id'] as String?,
        classTeacherName: json['class_teacher_name'] as String?,
        studentCount: _parseInt(json['student_count']),
      );

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String get display => '$name - $section';
}

class Student {
  final String id;
  final String userId;
  final String fullName;
  final String? classId;
  final String? rollNumber;
  final String? email;
  final String? className;
  final String? classSection;
  final bool isActive;

  Student({
    required this.id,
    required this.userId,
    required this.fullName,
    this.classId,
    this.rollNumber,
    this.email,
    this.className,
    this.classSection,
    required this.isActive,
  });

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        fullName: json['full_name'] as String,
        classId: json['class_id'] as String?,
        rollNumber: json['roll_number'] as String?,
        email: json['email'] as String?,
        className: json['class_name'] as String?,
        classSection: json['class_section'] as String?,
        isActive: json['is_active'] as bool? ?? true,
      );
}

class AttendanceRecord {
  final String id;
  final String studentId;
  final String classId;
  final String date;
  final String status;
  final String markedBy;
  final String studentName;
  final String? rollNumber;

  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.date,
    required this.status,
    required this.markedBy,
    required this.studentName,
    this.rollNumber,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        id: json['id'] as String,
        studentId: json['student_id'] as String,
        classId: json['class_id'] as String,
        date: json['date'] as String,
        status: json['status'] as String,
        markedBy: json['marked_by'] as String,
        studentName: json['student_name'] as String,
        rollNumber: json['roll_number'] as String?,
      );
}

class Exam {
  final String id;
  final String name;
  final String? examDate;
  final bool isPublished;

  Exam({
    required this.id,
    required this.name,
    this.examDate,
    this.isPublished = false,
  });

  factory Exam.fromJson(Map<String, dynamic> json) => Exam(
        id: json['id'] as String,
        name: json['name'] as String,
        examDate: json['exam_date'] as String?,
        isPublished: json['is_published'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Exam && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Subject {
  final String id;
  final String name;

  Subject({required this.id, required this.name});

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json['id'] as String,
        name: json['name'] as String,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Subject && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class TimetableEntry {
  final String id;
  final String classId;
  final String subjectId;
  final String? subjectName;
  final String? teacherName;
  final String day;
  final String startTime;
  final String endTime;

  TimetableEntry({
    required this.id,
    required this.classId,
    required this.subjectId,
    this.subjectName,
    this.teacherName,
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  factory TimetableEntry.fromJson(Map<String, dynamic> json) =>
      TimetableEntry(
        id: json['id'] as String,
        classId: json['class_id'] as String,
        subjectId: json['subject_id'] as String,
        subjectName: json['subject_name'] as String?,
        teacherName: json['teacher_name'] as String?,
        day: json['day'] as String,
        startTime: json['start_time'] as String,
        endTime: json['end_time'] as String,
      );
}

class Announcement {
  final String id;
  final String title;
  final String? body;
  final String? classId;
  final String createdBy;
  final String createdAt;
  final String? createdByEmail;

  Announcement({
    required this.id,
    required this.title,
    this.body,
    this.classId,
    required this.createdBy,
    required this.createdAt,
    this.createdByEmail,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String?,
        classId: json['class_id'] as String?,
        createdBy: json['created_by'] as String,
        createdAt: json['created_at'] as String,
        createdByEmail: json['created_by_email'] as String?,
      );

  bool get isSchoolWide => classId == null;
}

class TeacherProfile {
  final String id;
  final String userId;
  final String fullName;
  final String? phone;
  final bool isActive;
  final String? email;

  TeacherProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    this.phone,
    required this.isActive,
    this.email,
  });

  factory TeacherProfile.fromJson(Map<String, dynamic> json) =>
      TeacherProfile(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        fullName: json['full_name'] as String,
        phone: json['phone'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        email: json['email'] as String?,
      );
}

class DashboardData {
  final String teacherName;
  final List<TeacherClass> assignedClasses;
  final List<TimetableEntry> todaySchedule;
  final ClassModel? classTeacherClass;

  DashboardData({
    required this.teacherName,
    required this.assignedClasses,
    required this.todaySchedule,
    this.classTeacherClass,
  });
}

class MarkEntry {
  final String studentId;
  final String studentName;
  final String? rollNumber;
  double marksObtained;
  double totalMarks;

  MarkEntry({
    required this.studentId,
    required this.studentName,
    this.rollNumber,
    this.marksObtained = 0,
    this.totalMarks = 100,
  });
}
