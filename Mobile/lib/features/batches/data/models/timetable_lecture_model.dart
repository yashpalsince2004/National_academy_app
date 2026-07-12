class TimetableLectureModel {
  final String id;
  final String batchId;
  final String subjectName;
  final String teacherName;
  final String room;
  final String dayOfWeek;
  final String startTime; // "HH:MM AM/PM" or "HH:MM:SS"
  final String endTime;

  TimetableLectureModel({
    required this.id,
    required this.batchId,
    required this.subjectName,
    required this.teacherName,
    required this.room,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
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
    };
  }
}
