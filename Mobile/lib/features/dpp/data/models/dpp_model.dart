import 'dpp_question_model.dart';

class DppModel {
  final String id;
  final String title;
  final String examType;
  final String classLevel;
  final String subjectId;
  final String? subjectName;
  final String? chapterName;
  final String? chapterId;
  final List<String> topics;
  final String difficulty;
  final int configQuestions;
  final int configTimeMinutes;
  final int configMarksPerQuestion;
  final double configNegativeMarking;
  final int configTotalMarks;
  final List<String> configQuestionTypes;
  final String aiGenerationOption;
  final String? additionalInstructions;
  final String? prompt;
  final String? aiResponse;
  final String createdBy;
  final String? creatorName;
  final String status;
  final DateTime createdAt;
  final List<DppQuestionModel> questions;

  DppModel({
    required this.id,
    required this.title,
    required this.examType,
    required this.classLevel,
    required this.subjectId,
    this.subjectName,
    this.chapterName,
    this.chapterId,
    this.topics = const [],
    required this.difficulty,
    required this.configQuestions,
    required this.configTimeMinutes,
    required this.configMarksPerQuestion,
    required this.configNegativeMarking,
    required this.configTotalMarks,
    required this.configQuestionTypes,
    required this.aiGenerationOption,
    this.additionalInstructions,
    this.prompt,
    this.aiResponse,
    required this.createdBy,
    this.creatorName,
    required this.status,
    required this.createdAt,
    this.questions = const [],
  });

  factory DppModel.fromJson(Map<String, dynamic> json) {
    // Parse list of topics
    List<String> topicsList = [];
    if (json['topics'] != null) {
      if (json['topics'] is List) {
        topicsList = List<String>.from(json['topics'] as List);
      } else if (json['topics'] is String) {
        // Fallback for comma separated string
        topicsList = (json['topics'] as String)
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList();
      }
    }

    // Parse list of question types
    List<String> qTypes = [];
    if (json['config_question_types'] != null) {
      qTypes = List<String>.from(json['config_question_types'] as List);
    }

    // Parse negative marking
    double negMarking = 0.0;
    if (json['config_negative_marking'] != null) {
      negMarking = double.tryParse(json['config_negative_marking'].toString()) ?? 0.0;
    }

    // Parse questions list if present
    List<DppQuestionModel> questionModels = [];
    if (json['dpp_questions'] != null) {
      questionModels = (json['dpp_questions'] as List)
          .map((q) => DppQuestionModel.fromJson(q as Map<String, dynamic>))
          .toList();
    }

    // Hydrated fields
    String? subName = json['subjects'] != null ? json['subjects']['name'] as String? : null;
    String? createdByName = json['profiles'] != null ? json['profiles']['full_name'] as String? : null;

    return DppModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      examType: json['exam_type'] as String? ?? 'JEE',
      classLevel: json['class_level'] as String? ?? 'Class 12',
      subjectId: json['subject_id'] as String? ?? '',
      subjectName: subName ?? json['subject_name'] as String?,
      chapterName: json['chapter_name'] as String?,
      chapterId: json['chapter_id'] as String?,
      topics: topicsList,
      difficulty: json['difficulty'] as String? ?? 'Medium',
      configQuestions: json['config_questions'] as int? ?? 10,
      configTimeMinutes: json['config_time_minutes'] as int? ?? 30,
      configMarksPerQuestion: json['config_marks_per_question'] as int? ?? 4,
      configNegativeMarking: negMarking,
      configTotalMarks: json['config_total_marks'] as int? ?? 40,
      configQuestionTypes: qTypes,
      aiGenerationOption: json['ai_generation_option'] as String? ?? 'Conceptual',
      additionalInstructions: json['additional_instructions'] as String?,
      prompt: json['prompt'] as String?,
      aiResponse: json['ai_response'] as String?,
      createdBy: json['created_by'] as String? ?? '',
      creatorName: createdByName ?? json['creator_name'] as String?,
      status: json['status'] as String? ?? 'draft',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      questions: questionModels,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'title': title,
      'exam_type': examType,
      'class_level': classLevel,
      'subject_id': subjectId,
      'chapter_name': chapterName,
      if (chapterId != null) 'chapter_id': chapterId,
      'topics': topics,
      'difficulty': difficulty,
      'config_questions': configQuestions,
      'config_time_minutes': configTimeMinutes,
      'config_marks_per_question': configMarksPerQuestion,
      'config_negative_marking': configNegativeMarking,
      'config_total_marks': configTotalMarks,
      'config_question_types': configQuestionTypes,
      'ai_generation_option': aiGenerationOption,
      'additional_instructions': additionalInstructions,
      'prompt': prompt,
      'ai_response': aiResponse,
      'created_by': createdBy,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  DppModel copyWith({
    String? id,
    String? title,
    String? examType,
    String? classLevel,
    String? subjectId,
    String? subjectName,
    String? chapterName,
    String? chapterId,
    List<String>? topics,
    String? difficulty,
    int? configQuestions,
    int? configTimeMinutes,
    int? configMarksPerQuestion,
    double? configNegativeMarking,
    int? configTotalMarks,
    List<String>? configQuestionTypes,
    String? aiGenerationOption,
    String? additionalInstructions,
    String? prompt,
    String? aiResponse,
    String? createdBy,
    String? creatorName,
    String? status,
    DateTime? createdAt,
    List<DppQuestionModel>? questions,
  }) {
    return DppModel(
      id: id ?? this.id,
      title: title ?? this.title,
      examType: examType ?? this.examType,
      classLevel: classLevel ?? this.classLevel,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      chapterName: chapterName ?? this.chapterName,
      chapterId: chapterId ?? this.chapterId,
      topics: topics ?? this.topics,
      difficulty: difficulty ?? this.difficulty,
      configQuestions: configQuestions ?? this.configQuestions,
      configTimeMinutes: configTimeMinutes ?? this.configTimeMinutes,
      configMarksPerQuestion: configMarksPerQuestion ?? this.configMarksPerQuestion,
      configNegativeMarking: configNegativeMarking ?? this.configNegativeMarking,
      configTotalMarks: configTotalMarks ?? this.configTotalMarks,
      configQuestionTypes: configQuestionTypes ?? this.configQuestionTypes,
      aiGenerationOption: aiGenerationOption ?? this.aiGenerationOption,
      additionalInstructions: additionalInstructions ?? this.additionalInstructions,
      prompt: prompt ?? this.prompt,
      aiResponse: aiResponse ?? this.aiResponse,
      createdBy: createdBy ?? this.createdBy,
      creatorName: creatorName ?? this.creatorName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      questions: questions ?? this.questions,
    );
  }
}
