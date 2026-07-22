class ExamModel {
  final String id;
  final String batchId;
  final String subjectId;
  final String subjectName; // Joined from subjects table
  final String name; // Topic/Syllabus
  final String examDate; // "YYYY-MM-DD"
  final int maxMarks;
  final String examTime; // "02:00 PM - 03:30 PM"
  final bool isCancelled;

  ExamModel({
    required this.id,
    required this.batchId,
    required this.subjectId,
    required this.subjectName,
    required this.name,
    required this.examDate,
    required this.maxMarks,
    required this.examTime,
    this.isCancelled = false,
  });

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    // Check if subject is pre-joined or mapping object exists
    String sName = 'Chemistry';
    if (json['subjects'] != null && json['subjects']['name'] != null) {
      sName = json['subjects']['name'] as String;
    } else if (json['subject_name'] != null) {
      sName = json['subject_name'] as String;
    }
    // Clean suffix from subject name if any e.g. "Physics (JEE)" -> "Physics"
    if (sName.contains(' (')) {
      sName = sName.substring(0, sName.indexOf(' (')).trim();
    }
    if (sName.toLowerCase() == 'mathematics') {
      sName = 'Maths';
    }

    return ExamModel(
      id: json['id'] as String? ?? '',
      batchId: json['batch_id'] as String? ?? '',
      subjectId: json['subject_id'] as String? ?? '',
      subjectName: sName,
      name: json['name'] as String? ?? '',
      examDate: json['exam_date'] as String? ?? '',
      maxMarks: json['max_marks'] as int? ?? 100,
      examTime: json['exam_time'] as String? ?? '',
      isCancelled: json['is_cancelled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batch_id': batchId,
      'subject_id': subjectId,
      'name': name,
      'exam_date': examDate,
      'max_marks': maxMarks,
      'exam_time': examTime,
      'is_cancelled': isCancelled,
    };
  }

  ExamModel copyWith({
    String? id,
    String? batchId,
    String? subjectId,
    String? subjectName,
    String? name,
    String? examDate,
    int? maxMarks,
    String? examTime,
    bool? isCancelled,
  }) {
    return ExamModel(
      id: id ?? this.id,
      batchId: batchId ?? this.batchId,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      name: name ?? this.name,
      examDate: examDate ?? this.examDate,
      maxMarks: maxMarks ?? this.maxMarks,
      examTime: examTime ?? this.examTime,
      isCancelled: isCancelled ?? this.isCancelled,
    );
  }
}
