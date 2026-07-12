class BatchStudentModel {
  final String id; // student_id
  final String fullName;
  final String email;
  final String rollNo;
  final double attendancePercentage;
  final String feeStatus; // 'Paid', 'Pending', 'Overdue'
  final String classLevel;
  final String examType;

  BatchStudentModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.rollNo,
    required this.attendancePercentage,
    required this.feeStatus,
    required this.classLevel,
    required this.examType,
  });

  factory BatchStudentModel.fromJson(Map<String, dynamic> json) {
    return BatchStudentModel(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      rollNo: json['roll_no'] as String? ?? '',
      attendancePercentage: (json['attendance_percentage'] as num?)?.toDouble() ?? 100.0,
      feeStatus: json['fee_status'] as String? ?? 'Paid',
      classLevel: json['class_level'] as String? ?? '12',
      examType: json['exam_type'] as String? ?? 'JEE',
    );
  }
}
