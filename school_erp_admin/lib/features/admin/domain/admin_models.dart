class SchoolProfile {
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;
  final String? logoUrl;
  final String? academicYear;
  final String? establishedYear;

  SchoolProfile({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.email,
    this.website,
    this.logoUrl,
    this.academicYear,
    this.establishedYear,
  });

  factory SchoolProfile.fromJson(Map<String, dynamic> json) => SchoolProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] as String?,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        website: json['website'] as String?,
        logoUrl: json['logo_url'] as String?,
        academicYear: json['academic_year'] as String?,
        establishedYear: json['established_year'] as String?,
      );

  Map<String, dynamic> toUpdateJson() {
    final map = <String, dynamic>{};
    if (name.isNotEmpty) map['name'] = name;
    if (address != null) map['address'] = address;
    if (phone != null) map['phone'] = phone;
    if (email != null) map['email'] = email;
    if (website != null) map['website'] = website;
    if (logoUrl != null) map['logo_url'] = logoUrl;
    if (academicYear != null) map['academic_year'] = academicYear;
    if (establishedYear != null) map['established_year'] = establishedYear;
    return map;
  }
}

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

class ClassSubjects {
  final String classId;
  final String className;
  final String section;
  final List<Subject> subjects;

  ClassSubjects({
    required this.classId,
    required this.className,
    required this.section,
    required this.subjects,
  });

  factory ClassSubjects.fromJson(Map<String, dynamic> json) => ClassSubjects(
        classId: json['class_id'] as String,
        className: json['class_name'] as String,
        section: json['section'] as String,
        subjects: (json['subjects'] as List)
            .map((e) => Subject.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  String get displayName => '$className${section.isNotEmpty ? ' - $section' : ''}';
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

  String get displayName =>
      '$name${section.isNotEmpty ? ' - $section' : ''}';

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

class ExamClass {
  final String id;
  final String name;
  final String? section;

  ExamClass({
    required this.id,
    required this.name,
    this.section,
  });

  String get displayName =>
      '$name${section != null && section!.isNotEmpty ? ' - $section' : ''}';

  factory ExamClass.fromJson(Map<String, dynamic> json) => ExamClass(
        id: json['id'] as String,
        name: json['name'] as String,
        section: json['section'] as String?,
      );
}

class Exam {
  final String id;
  final String name;
  final String? examDate;
  final bool isPublished;
  final List<ExamClass> classes;

  Exam({
    required this.id,
    required this.name,
    this.examDate,
    this.isPublished = false,
    this.classes = const [],
  });

  factory Exam.fromJson(Map<String, dynamic> json) => Exam(
        id: json['id'] as String,
        name: json['name'] as String,
        examDate: json['exam_date'] as String?,
        isPublished: json['is_published'] as bool? ?? false,
        classes: (json['classes'] as List?)
                ?.map((c) => ExamClass.fromJson(c as Map<String, dynamic>))
                .toList() ??
            [],
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
  final String? room;
  final String? subjectName;
  final String? teacherName;
  final String? className;
  final String? classSection;
  final String? proxyTeacherId;
  final String? originalTeacherId;
  final bool hasProxy;

  TimetableEntry({
    required this.id,
    required this.classId,
    required this.subjectId,
    required this.teacherId,
    required this.day,
    required this.startTime,
    required this.endTime,
    this.room,
    this.subjectName,
    this.teacherName,
    this.className,
    this.classSection,
    this.proxyTeacherId,
    this.originalTeacherId,
    this.hasProxy = false,
  });

  factory TimetableEntry.fromJson(Map<String, dynamic> json) => TimetableEntry(
        id: json['id'] as String,
        classId: json['class_id'] as String,
        subjectId: json['subject_id'] as String,
        teacherId: json['teacher_id'] as String,
        day: json['day'] as String,
        startTime: json['start_time'] as String,
        endTime: json['end_time'] as String,
        room: json['room'] as String?,
        subjectName: json['subject_name'] as String?,
        teacherName: json['teacher_name'] as String?,
        className: json['class_name'] as String?,
        classSection: json['class_section'] as String?,
        proxyTeacherId: json['proxy_teacher_id'] as String?,
        originalTeacherId: json['original_teacher_id'] as String?,
        hasProxy: json['has_proxy'] as bool? ?? false,
      );

  String get dayLabel {
    const days = {
      'mon': 'Monday', 'tue': 'Tuesday', 'wed': 'Wednesday',
      'thu': 'Thursday', 'fri': 'Friday', 'sat': 'Saturday',
    };
    return days[day] ?? day;
  }

  String get classDisplay => className != null ? '$className${classSection != null && classSection!.isNotEmpty ? ' - $classSection' : ''}' : '';
}

class FeeStructure {
  final String id;
  final String feeType;
  final double amount;
  final String? classId;
  final String? className;
  final String? postTitle;

  FeeStructure({
    required this.id,
    required this.feeType,
    required this.amount,
    this.classId,
    this.className,
    this.postTitle,
  });

  factory FeeStructure.fromJson(Map<String, dynamic> json) => FeeStructure(
        id: json['id'] as String,
        feeType: json['fee_type'] as String,
        amount: (json['amount'] as num).toDouble(),
        classId: json['class_id'] as String?,
        className: json['class_name'] as String?,
        postTitle: json['post_title'] as String?,
      );
}

class FeePost {
  final String id;
  final String title;
  final String? description;
  final String? dueDate;
  final List<FeeStructure> structures;

  FeePost({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.structures = const [],
  });

  factory FeePost.fromJson(Map<String, dynamic> json) => FeePost(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        dueDate: json['due_date'] as String?,
        structures: (json['structures'] as List?)
                ?.map((e) => FeeStructure.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class UnpaidFeeItem {
  final String studentId;
  final String studentName;
  final String className;
  final String feeStructureId;
  final String feeType;
  final double amount;
  final double totalAmount;
  final String? dueDate;
  final String paymentStatus;

  UnpaidFeeItem({
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.feeStructureId,
    required this.feeType,
    required this.amount,
    this.totalAmount = 0,
    this.dueDate,
    this.paymentStatus = 'none',
  });

  bool get isPartial => paymentStatus == 'partial';
  bool get isNone => paymentStatus == 'none';

  factory UnpaidFeeItem.fromJson(Map<String, dynamic> json) => UnpaidFeeItem(
        studentId: json['student_id'] as String,
        studentName: json['student_name'] as String,
        className: json['class_name'] as String? ?? '',
        feeStructureId: json['fee_structure_id'] as String,
        feeType: json['fee_type'] as String,
        amount: (json['amount'] as num).toDouble(),
        totalAmount: (json['total_amount'] as num?)?.toDouble() ?? (json['amount'] as num).toDouble(),
        dueDate: json['due_date'] as String?,
        paymentStatus: json['payment_status'] as String? ?? 'none',
      );
}

class StaffMember {
  final String id;
  final String userId;
  final String fullName;
  final String? email;
  final String? phone;
  final String? department;
  final String? designation;
  final double? salary;
  final String? joiningDate;
  final bool isActive;

  StaffMember({
    required this.id,
    required this.userId,
    required this.fullName,
    this.email,
    this.phone,
    this.department,
    this.designation,
    this.salary,
    this.joiningDate,
    required this.isActive,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) => StaffMember(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        fullName: json['full_name'] as String,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        department: json['department'] as String?,
        designation: json['designation'] as String?,
        salary: json['salary'] != null ? double.tryParse(json['salary'].toString()) : null,
        joiningDate: json['joining_date'] as String?,
        isActive: json['is_active'] as bool? ?? true,
      );

  Map<String, dynamic> toCreateJson() => {
        'email': email,
        'password': defaultUserPassword,
        'full_name': fullName,
        'phone': phone,
        'department': department,
        'designation': designation,
        'salary': salary,
        'joining_date': joiningDate,
      };

  Map<String, dynamic> toUpdateJson() => {
        'full_name': fullName,
        'phone': phone,
        'department': department,
        'designation': designation,
        'salary': salary,
        'joining_date': joiningDate,
        'is_active': isActive,
      };
}

class Holiday {
  final String id;
  final String title;
  final String? description;
  final String date;
  final String type;
  final bool isRecurring;

  Holiday({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    this.type = 'holiday',
    this.isRecurring = false,
  });

  factory Holiday.fromJson(Map<String, dynamic> json) => Holiday(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        date: json['date'] as String,
        type: json['type'] as String? ?? 'holiday',
        isRecurring: json['is_recurring'] as bool? ?? false,
      );

  bool get isHoliday => type == 'holiday';
  String get displayType => isHoliday ? 'Holiday' : 'Event';
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

class GradingRange {
  final String id;
  final String gradingSystemId;
  final String grade;
  final double minPercentage;
  final double maxPercentage;
  final double? gradePoint;
  final String? description;

  GradingRange({
    required this.id,
    required this.gradingSystemId,
    required this.grade,
    required this.minPercentage,
    required this.maxPercentage,
    this.gradePoint,
    this.description,
  });

  factory GradingRange.fromJson(Map<String, dynamic> json) => GradingRange(
        id: json['id'] as String,
        gradingSystemId: json['grading_system_id'] as String,
        grade: json['grade'] as String,
        minPercentage: double.parse(json['min_percentage'].toString()),
        maxPercentage: double.parse(json['max_percentage'].toString()),
        gradePoint: json['grade_point'] != null ? double.parse(json['grade_point'].toString()) : null,
        description: json['description'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'grade': grade,
        'min_percentage': minPercentage,
        'max_percentage': maxPercentage,
        'grade_point': gradePoint,
        'description': description,
      };
}

class GradingSystem {
  final String id;
  final String name;
  final bool isActive;
  final List<GradingRange> ranges;

  GradingSystem({
    required this.id,
    required this.name,
    this.isActive = true,
    this.ranges = const [],
  });

  factory GradingSystem.fromJson(Map<String, dynamic> json) => GradingSystem(
        id: json['id'] as String,
        name: json['name'] as String,
        isActive: json['is_active'] as bool? ?? true,
        ranges: (json['ranges'] as List?)
                ?.map((e) => GradingRange.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class ExamSubject {
  final String id;
  final String examId;
  final String subjectId;
  final String subjectName;
  final double maxMarks;
  final double? passingMarks;

  ExamSubject({
    required this.id,
    required this.examId,
    required this.subjectId,
    required this.subjectName,
    required this.maxMarks,
    this.passingMarks,
  });

  factory ExamSubject.fromJson(Map<String, dynamic> json) => ExamSubject(
        id: json['id'] as String,
        examId: json['exam_id'] as String,
        subjectId: json['subject_id'] as String,
        subjectName: json['subject_name'] as String? ?? '',
        maxMarks: double.parse(json['max_marks'].toString()),
        passingMarks: json['passing_marks'] != null ? double.parse(json['passing_marks'].toString()) : null,
      );
}

class ProxyAssignment {
  final String id;
  final String timetableId;
  final String date;
  final String originalTeacherId;
  final String originalTeacherName;
  final String proxyTeacherId;
  final String proxyTeacherName;
  final String requestedBy;
  final String? requestedByEmail;
  final String status;
  final String? reason;
  final String? subjectId;
  final String? subjectName;
  final String? day;
  final String? startTime;
  final String? endTime;
  final String? room;
  final String? className;
  final String? classSection;

  ProxyAssignment({
    required this.id,
    required this.timetableId,
    required this.date,
    required this.originalTeacherId,
    required this.originalTeacherName,
    required this.proxyTeacherId,
    required this.proxyTeacherName,
    required this.requestedBy,
    this.requestedByEmail,
    required this.status,
    this.reason,
    this.subjectId,
    this.subjectName,
    this.day,
    this.startTime,
    this.endTime,
    this.room,
    this.className,
    this.classSection,
  });

  factory ProxyAssignment.fromJson(Map<String, dynamic> json) =>
      ProxyAssignment(
        id: json['id'] as String,
        timetableId: json['timetable_id'] as String,
        date: json['date'] as String,
        originalTeacherId: json['original_teacher_id'] as String,
        originalTeacherName: json['original_teacher_name'] as String? ?? '',
        proxyTeacherId: json['proxy_teacher_id'] as String,
        proxyTeacherName: json['proxy_teacher_name'] as String? ?? '',
        requestedBy: json['requested_by'] as String,
        requestedByEmail: json['requested_by_email'] as String?,
        status: json['status'] as String? ?? 'pending',
        reason: json['reason'] as String?,
        subjectId: json['subject_id'] as String?,
        subjectName: json['subject_name'] as String?,
        day: json['day'] as String?,
        startTime: json['start_time'] as String?,
        endTime: json['end_time'] as String?,
        room: json['room'] as String?,
        className: json['class_name'] as String?,
        classSection: json['class_section'] as String?,
      );

  String get classDisplay {
    if (className == null) return '';
    return classSection != null && classSection!.isNotEmpty
        ? '$className - $classSection'
        : className!;
  }

  String get statusLabel {
    switch (status) {
      case 'pending': return 'Pending';
      case 'accepted': return 'Accepted';
      case 'rejected': return 'Rejected';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  }
}
