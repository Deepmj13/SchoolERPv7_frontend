class StudentProfile {
  final String id;
  final String userId;
  final String fullName;
  final String? email;
  final String? rollNumber;
  final String? classId;
  final String? className;
  final String? classSection;
  final String? parentName;
  final String? parentPhone;
  final bool isActive;

  StudentProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    this.email,
    this.rollNumber,
    this.classId,
    this.className,
    this.classSection,
    this.parentName,
    this.parentPhone,
    required this.isActive,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) => StudentProfile(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        fullName: json['full_name'] as String,
        email: json['email'] as String?,
        rollNumber: json['roll_number'] as String?,
        classId: json['class_id'] as String?,
        className: json['class_name'] as String?,
        classSection: json['class_section'] as String?,
        parentName: json['parent_name'] as String?,
        parentPhone: json['parent_phone'] as String?,
        isActive: json['is_active'] as bool? ?? true,
      );
}

class AttendanceSummary {
  final String month;
  final int total;
  final int present;
  final int absent;
  final double percentage;

  AttendanceSummary({
    required this.month,
    required this.total,
    required this.present,
    required this.absent,
    required this.percentage,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) =>
      AttendanceSummary(
        month: json['month'] as String? ?? '',
        total: (json['total'] as num?)?.toInt() ?? 0,
        present: (json['present'] as num?)?.toInt() ?? 0,
        absent: (json['absent'] as num?)?.toInt() ?? 0,
        percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      );
}

class AttendanceRecord {
  final String id;
  final String date;
  final String status;
  final String? subjectName;

  AttendanceRecord({
    required this.id,
    required this.date,
    required this.status,
    this.subjectName,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        id: json['id'] as String,
        date: json['date'] as String,
        status: json['status'] as String,
        subjectName: json['subject_name'] as String?,
      );
}

class ResultEntry {
  final String id;
  final String examName;
  final String subjectName;
  final double marksObtained;
  final double totalMarks;
  final double percentage;
  final String? grade;
  final bool passed;

  ResultEntry({
    required this.id,
    required this.examName,
    required this.subjectName,
    required this.marksObtained,
    required this.totalMarks,
    required this.percentage,
    this.grade,
    required this.passed,
  });

  factory ResultEntry.fromJson(Map<String, dynamic> json) => ResultEntry(
        id: json['id'] as String? ?? '',
        examName: json['exam_name'] as String? ?? '',
        subjectName: json['subject_name'] as String? ?? '',
        marksObtained: (json['marks_obtained'] as num?)?.toDouble() ?? 0,
        totalMarks: (json['total_marks'] as num?)?.toDouble() ?? 0,
        percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
        grade: json['grade'] as String?,
        passed: json['passed'] as bool? ?? false,
      );
}

class TimetableEntry {
  final String id;
  final String subjectName;
  final String? teacherName;
  final String day;
  final String startTime;
  final String endTime;
  final String? room;

  TimetableEntry({
    required this.id,
    required this.subjectName,
    this.teacherName,
    required this.day,
    required this.startTime,
    required this.endTime,
    this.room,
  });

  factory TimetableEntry.fromJson(Map<String, dynamic> json) =>
      TimetableEntry(
        id: json['id'] as String,
        subjectName: json['subject_name'] as String? ?? '',
        teacherName: json['teacher_name'] as String?,
        day: json['day'] as String,
        startTime: json['start_time'] as String,
        endTime: json['end_time'] as String,
        room: json['room'] as String?,
      );
}

class FeeDetail {
  final String id;
  final String feeType;
  final double amount;
  final String? dueDate;
  final bool paid;
  final String? paidDate;

  FeeDetail({
    required this.id,
    required this.feeType,
    required this.amount,
    this.dueDate,
    required this.paid,
    this.paidDate,
  });

  factory FeeDetail.fromJson(Map<String, dynamic> json) => FeeDetail(
        id: json['id'] as String? ?? '',
        feeType: json['fee_type'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        dueDate: json['due_date'] as String?,
        paid: json['paid'] as bool? ?? false,
        paidDate: json['paid_date'] as String?,
      );
}

class FeePayment {
  final String id;
  final double amount;
  final String paymentDate;
  final String? paymentMethod;
  final String? transactionId;

  FeePayment({
    required this.id,
    required this.amount,
    required this.paymentDate,
    this.paymentMethod,
    this.transactionId,
  });

  factory FeePayment.fromJson(Map<String, dynamic> json) => FeePayment(
        id: json['id'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        paymentDate: json['payment_date'] as String? ?? '',
        paymentMethod: json['payment_method'] as String?,
        transactionId: json['transaction_id'] as String?,
      );
}

class FeePost {
  final String? id;
  final String title;
  final String? description;
  final String? dueDate;
  final List<FeeDetail> structures;

  FeePost({
    this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.structures = const [],
  });

  factory FeePost.fromJson(Map<String, dynamic> json) => FeePost(
        id: json['id'] as String?,
        title: json['title'] as String? ?? 'Other Fees',
        description: json['description'] as String?,
        dueDate: json['due_date'] as String?,
        structures: (json['structures'] as List?)
                ?.map((e) => FeeDetail.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  double get totalAmount => structures.fold(0.0, (sum, s) => sum + s.amount);
  double get totalPaid =>
      structures.where((s) => s.paid).fold(0.0, (sum, s) => sum + s.amount);
  double get totalPending =>
      structures.where((s) => !s.paid).fold(0.0, (sum, s) => sum + s.amount);
}

class Assignment {
  final String id;
  final String title;
  final String? description;
  final String subjectName;
  final String? dueDate;
  final String status;
  final String? grade;
  final String? submissionStatus;
  final String? teacherRemarks;
  final String? submissionUpdatedAt;

  Assignment({
    required this.id,
    required this.title,
    this.description,
    required this.subjectName,
    this.dueDate,
    required this.status,
    this.grade,
    this.submissionStatus,
    this.teacherRemarks,
    this.submissionUpdatedAt,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) => Assignment(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        subjectName: json['subject_name'] as String? ?? '',
        dueDate: json['due_date'] as String?,
        status: json['status'] as String? ?? 'pending',
        grade: json['grade'] as String?,
        submissionStatus: json['submission_status'] as String?,
        teacherRemarks: json['teacher_remarks'] as String?,
        submissionUpdatedAt: json['submission_updated_at'] as String?,
      );
}

class Notice {
  final String id;
  final String title;
  final String? body;
  final String createdAt;
  final String? createdByEmail;
  final bool isSchoolWide;

  Notice({
    required this.id,
    required this.title,
    this.body,
    required this.createdAt,
    this.createdByEmail,
    required this.isSchoolWide,
  });

  factory Notice.fromJson(Map<String, dynamic> json) => Notice(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String?,
        createdAt: json['created_at'] as String,
        createdByEmail: json['created_by_email'] as String?,
        isSchoolWide: json['class_id'] == null,
      );
}

class StudentRemark {
  final String id;
  final String? teacherName;
  final String type;
  final String? category;
  final String message;
  final bool isRead;
  final String createdAt;

  StudentRemark({
    required this.id,
    this.teacherName,
    required this.type,
    this.category,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory StudentRemark.fromJson(Map<String, dynamic> json) => StudentRemark(
        id: json['id'] as String,
        teacherName: json['teacher_name'] as String?,
        type: json['type'] as String? ?? 'praise',
        category: json['category'] as String?,
        message: json['message'] as String? ?? '',
        isRead: json['is_read'] as bool? ?? false,
        createdAt: json['created_at'] as String? ?? '',
      );
}

class DashboardData {
  final String studentName;
  final AttendanceSummary? attendanceSummary;
  final List<Notice> recentNotices;

  DashboardData({
    required this.studentName,
    this.attendanceSummary,
    this.recentNotices = const [],
  });
}
