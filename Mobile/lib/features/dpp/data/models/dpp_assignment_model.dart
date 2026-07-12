class DppAssignmentModel {
  final String id;
  final String dppId;
  final String? dppTitle;
  final String assignedBy;
  final String assigneeType; // 'batch', 'individual'
  final String? batchId;
  final String? batchName;
  final String? studentId;
  final String? studentName;
  final DateTime scheduledAt;
  final DateTime? dueAt;
  final bool notify;
  final DateTime createdAt;

  DppAssignmentModel({
    required this.id,
    required this.dppId,
    this.dppTitle,
    required this.assignedBy,
    required this.assigneeType,
    this.batchId,
    this.batchName,
    this.studentId,
    this.studentName,
    required this.scheduledAt,
    this.dueAt,
    required this.notify,
    required this.createdAt,
  });

  factory DppAssignmentModel.fromJson(Map<String, dynamic> json) {
    String? dppT = json['dpps'] != null ? json['dpps']['title'] as String? : null;
    String? bName = json['batches'] != null ? json['batches']['name'] as String? : null;
    
    String? sName;
    if (json['students'] != null && json['students']['profiles'] != null) {
      sName = json['students']['profiles']['full_name'] as String?;
    }

    return DppAssignmentModel(
      id: json['id'] as String? ?? '',
      dppId: json['dpp_id'] as String? ?? '',
      dppTitle: dppT ?? json['dpp_title'] as String?,
      assignedBy: json['assigned_by'] as String? ?? '',
      assigneeType: json['assignee_type'] as String? ?? 'batch',
      batchId: json['batch_id'] as String?,
      batchName: bName ?? json['batch_name'] as String?,
      studentId: json['student_id'] as String?,
      studentName: sName ?? json['student_name'] as String?,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      dueAt: json['due_at'] != null ? DateTime.parse(json['due_at'] as String) : null,
      notify: json['notify'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'dpp_id': dppId,
      'assigned_by': assignedBy,
      'assignee_type': assigneeType,
      if (batchId != null) 'batch_id': batchId,
      if (studentId != null) 'student_id': studentId,
      'scheduled_at': scheduledAt.toIso8601String(),
      if (dueAt != null) 'due_at': dueAt?.toIso8601String(),
      'notify': notify,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
