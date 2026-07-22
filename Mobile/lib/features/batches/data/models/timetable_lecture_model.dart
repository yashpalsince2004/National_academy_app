class TimetableLectureModel {
  final String id;
  final String batchId;
  final String subjectName;
  final String teacherName;
  final String room;
  final String dayOfWeek;
  final String startTime; // "HH:MM AM/PM" or "HH:MM:SS"
  final String endTime;
  final String? lectureDate; // "YYYY-MM-DD"
  final bool isCancelled;

  TimetableLectureModel({
    required this.id,
    required this.batchId,
    required this.subjectName,
    required this.teacherName,
    required this.room,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.lectureDate,
    this.isCancelled = false,
  });

  factory TimetableLectureModel.fromJson(Map<String, dynamic> json) {
    return TimetableLectureModel(
      id: json['id'] as String? ?? '',
      batchId: json['batch_id'] as String? ?? '',
      subjectName: json['subject_name'] as String? ?? '',
      teacherName: json['teacher_name'] as String? ?? '',
      room: json['room'] as String? ?? '',
      dayOfWeek: json['day_of_week'] as String? ?? 'Monday',
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      lectureDate: json['lecture_date'] as String?,
      isCancelled: json['is_cancelled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batch_id': batchId,
      'subject_name': subjectName,
      'teacher_name': teacherName,
      'room': room,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'lecture_date': lectureDate,
      'is_cancelled': isCancelled,
    };
  }

  TimetableLectureModel copyWith({
    String? id,
    String? batchId,
    String? subjectName,
    String? teacherName,
    String? room,
    String? dayOfWeek,
    String? startTime,
    String? endTime,
    String? lectureDate,
    bool? isCancelled,
  }) {
    return TimetableLectureModel(
      id: id ?? this.id,
      batchId: batchId ?? this.batchId,
      subjectName: subjectName ?? this.subjectName,
      teacherName: teacherName ?? this.teacherName,
      room: room ?? this.room,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      lectureDate: lectureDate ?? this.lectureDate,
      isCancelled: isCancelled ?? this.isCancelled,
    );
  }
}
