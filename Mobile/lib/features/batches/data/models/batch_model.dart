class BatchModel {
  final String id;
  final String courseId;
  final String name;
  final int capacity;
  final DateTime? startDate;
  final DateTime? endDate;
  final String examType;
  final String classLevel;
  final String medium;
  final List<String> lectureDays;
  final String? startTime;
  final String? endTime;
  final String? roomNumber;
  final String? color;
  final String? remarks;
  final String status;
  final int studentCount;
  final String? teacherName;

  BatchModel({
    required this.id,
    required this.courseId,
    required this.name,
    required this.capacity,
    this.startDate,
    this.endDate,
    required this.examType,
    required this.classLevel,
    required this.medium,
    required this.lectureDays,
    this.startTime,
    this.endTime,
    this.roomNumber,
    this.color,
    this.remarks,
    required this.status,
    this.studentCount = 0,
    this.teacherName,
  });

  factory BatchModel.fromJson(Map<String, dynamic> json) {
    // Parse lectureDays from db array
    List<String> parseDays(dynamic days) {
      if (days == null) return [];
      if (days is List) {
        return days.map((e) => e.toString()).toList();
      }
      return [];
    }

    return BatchModel(
      id: json['id'] as String? ?? '',
      courseId: json['course_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      capacity: json['capacity'] as int? ?? 30,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date'] as String) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      examType: json['exam_type'] as String? ?? 'JEE',
      classLevel: json['class_level'] as String? ?? '12',
      medium: json['medium'] as String? ?? 'English',
      lectureDays: parseDays(json['lecture_days']),
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      roomNumber: json['room_number'] as String?,
      color: json['color'] as String?,
      remarks: json['remarks'] as String?,
      status: json['status'] as String? ?? 'active',
      studentCount: json['student_count'] as int? ?? 0,
      teacherName: json['teacher_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'name': name,
      'capacity': capacity,
      'start_date': startDate?.toIso8601String().substring(0, 10),
      'end_date': endDate?.toIso8601String().substring(0, 10),
      'exam_type': examType,
      'class_level': classLevel,
      'medium': medium,
      'lecture_days': lectureDays,
      'start_time': startTime,
      'end_time': endTime,
      'room_number': roomNumber,
      'color': color,
      'remarks': remarks,
      'status': status,
    };
  }

  BatchModel copyWith({
    String? id,
    String? courseId,
    String? name,
    int? capacity,
    DateTime? startDate,
    DateTime? endDate,
    String? examType,
    String? classLevel,
    String? medium,
    List<String>? lectureDays,
    String? startTime,
    String? endTime,
    String? roomNumber,
    String? color,
    String? remarks,
    String? status,
    int? studentCount,
    String? teacherName,
  }) {
    return BatchModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      examType: examType ?? this.examType,
      classLevel: classLevel ?? this.classLevel,
      medium: medium ?? this.medium,
      lectureDays: lectureDays ?? this.lectureDays,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      roomNumber: roomNumber ?? this.roomNumber,
      color: color ?? this.color,
      remarks: remarks ?? this.remarks,
      status: status ?? this.status,
      studentCount: studentCount ?? this.studentCount,
      teacherName: teacherName ?? this.teacherName,
    );
  }
}
