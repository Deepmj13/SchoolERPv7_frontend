class DashboardStats {
  final int totalStudents;
  final int totalTeachers;
  final int totalClasses;
  final double todayAttendancePercentage;

  DashboardStats({
    required this.totalStudents,
    required this.totalTeachers,
    required this.totalClasses,
    required this.todayAttendancePercentage,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalStudents: json['totalStudents'] as int,
      totalTeachers: json['totalTeachers'] as int,
      totalClasses: json['totalClasses'] as int,
      todayAttendancePercentage:
          (json['todayAttendancePercentage'] as num).toDouble(),
    );
  }
}

class Student {
  final String id;
  final String userId;
  final String fullName;
  final String? classId;
  final String? rollNumber;
  final String? dob;
  final String? parentName;
  final String? parentPhone;
  final String? emergencyContact;
  final bool isActive;
  final String? email;
  final String? className;
  final String? classSection;

  Student({
    required this.id,
    required this.userId,
    required this.fullName,
    this.classId,
    this.rollNumber,
    this.dob,
    this.parentName,
    this.parentPhone,
    this.emergencyContact,
    required this.isActive,
    this.email,
    this.className,
    this.classSection,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      classId: json['class_id'] as String?,
      rollNumber: json['roll_number'] as String?,
      dob: json['dob'] as String?,
      parentName: json['parent_name'] as String?,
      parentPhone: json['parent_phone'] as String?,
      emergencyContact: json['emergency_contact'] as String?,
      isActive: json['is_active'] as bool,
      email: json['email'] as String?,
      className: json['class_name'] as String?,
      classSection: json['class_section'] as String?,
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'full_name': fullName,
        'email': email,
        'password': defaultUserPassword,
        'class_id': classId,
        'roll_number': rollNumber,
        'parent_name': parentName,
        'parent_phone': parentPhone,
      };

  Map<String, dynamic> toUpdateJson() => {
        'full_name': fullName,
        'class_id': classId,
        'roll_number': rollNumber,
        'parent_name': parentName,
        'parent_phone': parentPhone,
        'is_active': isActive,
      };
}

class Teacher {
  final String id;
  final String userId;
  final String fullName;
  final String? phone;
  final bool isActive;
  final String? email;

  Teacher({
    required this.id,
    required this.userId,
    required this.fullName,
    this.phone,
    required this.isActive,
    this.email,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      isActive: json['is_active'] as bool,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'full_name': fullName,
        'email': email,
        'password': defaultUserPassword,
        'phone': phone,
      };

  Map<String, dynamic> toUpdateJson() => {
        'full_name': fullName,
        'phone': phone,
        'is_active': isActive,
      };
}

class TeacherAssignment {
  final String classId;
  final String className;
  final String section;
  final String subjectId;
  final String subjectName;

  TeacherAssignment({
    required this.classId,
    required this.className,
    required this.section,
    required this.subjectId,
    required this.subjectName,
  });

  factory TeacherAssignment.fromJson(Map<String, dynamic> json) {
    return TeacherAssignment(
      classId: json['class_id'] as String,
      className: json['class_name'] as String,
      section: json['section'] as String,
      subjectId: json['subject_id'] as String,
      subjectName: json['subject_name'] as String,
    );
  }
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

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] as String,
      name: json['name'] as String,
      section: json['section'] as String,
      classTeacherId: json['class_teacher_id'] as String?,
      classTeacherName: json['class_teacher_name'] as String?,
      studentCount: _parseInt(json['student_count']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String get display => '$name - $section';

  Map<String, dynamic> toCreateJson() => {
        'name': name,
        'section': section,
        'class_teacher_id': classTeacherId,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'section': section,
        'class_teacher_id': classTeacherId,
      };
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

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String?,
      classId: json['class_id'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: json['created_at'] as String,
      createdByEmail: json['created_by_email'] as String?,
    );
  }

  bool get isSchoolWide => classId == null;
}

/// Generic paginated response that handles both paginated JSON and flat arrays.
class PaginatedResponse<T> {
  final List<T> items;
  final int total;
  final int page;
  final int pages;

  PaginatedResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pages,
  });

  factory PaginatedResponse.fromJson(
    dynamic json,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    // Backend returns a flat array -> wrap as a single page
    if (json is List) {
      return PaginatedResponse(
        items: json.map((e) => fromItem(e as Map<String, dynamic>)).toList(),
        total: json.length,
        page: 1,
        pages: 1,
      );
    }
    // Backend returns paginated JSON
    final data = json['data'];
    final list = (data as List)
        .map((e) => fromItem(e as Map<String, dynamic>))
        .toList();
    return PaginatedResponse(
      items: list,
      total: json['total'] as int? ?? list.length,
      page: json['page'] as int? ?? 1,
      pages: json['pages'] as int? ?? 1,
    );
  }
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

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
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
}

class TimetableEntry {
  final String id;
  final String classId;
  final String subjectId;
  final String teacherId;
  final String day;
  final String startTime;
  final String endTime;
  final String? subjectName;
  final String? teacherName;

  TimetableEntry({
    required this.id,
    required this.classId,
    required this.subjectId,
    required this.teacherId,
    required this.day,
    required this.startTime,
    required this.endTime,
    this.subjectName,
    this.teacherName,
  });

  factory TimetableEntry.fromJson(Map<String, dynamic> json) => TimetableEntry(
        id: json['id'] as String,
        classId: json['class_id'] as String,
        subjectId: json['subject_id'] as String,
        teacherId: json['teacher_id'] as String,
        day: json['day'] as String,
        startTime: json['start_time'] as String,
        endTime: json['end_time'] as String,
        subjectName: json['subject_name'] as String?,
        teacherName: json['teacher_name'] as String?,
      );

  String get dayLabel {
    const days = {
      'mon': 'Monday', 'tue': 'Tuesday', 'wed': 'Wednesday',
      'thu': 'Thursday', 'fri': 'Friday', 'sat': 'Saturday',
    };
    return days[day] ?? day;
  }
}

class FeeStructure {
  final String id;
  final String feeType;
  final double amount;
  final String? classId;
  final String? className;

  FeeStructure({
    required this.id,
    required this.feeType,
    required this.amount,
    this.classId,
    this.className,
  });

  factory FeeStructure.fromJson(Map<String, dynamic> json) => FeeStructure(
        id: json['id'] as String,
        feeType: json['fee_type'] as String,
        amount: (json['amount'] as num).toDouble(),
        classId: json['class_id'] as String?,
        className: json['class_name'] as String?,
      );
}

const String defaultUserPassword = 'ChangeMe@123';

class FeePayment {
  final String id;
  final String studentId;
  final String? studentName;
  final String? feeStructureId;
  final String? feeType;
  final double amountPaid;
  final String paymentDate;
  final String? paymentMode;
  final String status;

  FeePayment({
    required this.id,
    required this.studentId,
    this.studentName,
    this.feeStructureId,
    this.feeType,
    required this.amountPaid,
    required this.paymentDate,
    this.paymentMode,
    required this.status,
  });

  factory FeePayment.fromJson(Map<String, dynamic> json) => FeePayment(
        id: json['id'] as String,
        studentId: json['student_id'] as String,
        studentName: json['student_name'] as String?,
        feeStructureId: json['fee_structure_id'] as String?,
        feeType: json['fee_type'] as String?,
        amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0,
        paymentDate: json['payment_date'] as String,
        paymentMode: json['payment_mode'] as String?,
        status: json['status'] as String? ?? 'pending',
      );
}
