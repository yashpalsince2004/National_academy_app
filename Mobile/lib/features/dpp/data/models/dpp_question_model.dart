class DppQuestionModel {
  final String id;
  final String dppId;
  final String questionText;
  final String questionType;
  final List<String>? options;
  final String correctAnswer;
  final String? explanation;
  final String? difficulty;
  final int? estimatedTimeSeconds;
  final int marks;
  final String? learningOutcome;

  DppQuestionModel({
    required this.id,
    required this.dppId,
    required this.questionText,
    required this.questionType,
    this.options,
    required this.correctAnswer,
    this.explanation,
    this.difficulty,
    this.estimatedTimeSeconds,
    required this.marks,
    this.learningOutcome,
  });

  factory DppQuestionModel.fromJson(Map<String, dynamic> json) {
    return DppQuestionModel(
      id: json['id'] as String? ?? '',
      dppId: json['dpp_id'] as String? ?? '',
      questionText: json['question_text'] as String? ?? '',
      questionType: json['question_type'] as String? ?? 'Single Correct',
      options: json['options'] != null
          ? List<String>.from(json['options'] as List)
          : null,
      correctAnswer: json['correct_answer'] as String? ?? '',
      explanation: json['explanation'] as String?,
      difficulty: json['difficulty'] as String?,
      estimatedTimeSeconds: json['estimated_time_seconds'] as int?,
      marks: json['marks'] as int? ?? 1,
      learningOutcome: json['learning_outcome'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final isMock = id.isEmpty || id.startsWith('q-mock');
    return {
      if (!isMock) 'id': id,
      'dpp_id': dppId,
      'question_text': questionText,
      'question_type': questionType,
      'options': options,
      'correct_answer': correctAnswer,
      'explanation': explanation,
      'difficulty': difficulty,
      'estimated_time_seconds': estimatedTimeSeconds,
      'marks': marks,
      'learning_outcome': learningOutcome,
    };
  }

  DppQuestionModel copyWith({
    String? id,
    String? dppId,
    String? questionText,
    String? questionType,
    List<String>? options,
    String? correctAnswer,
    String? explanation,
    String? difficulty,
    int? estimatedTimeSeconds,
    int? marks,
    String? learningOutcome,
  }) {
    return DppQuestionModel(
      id: id ?? this.id,
      dppId: dppId ?? this.dppId,
      questionText: questionText ?? this.questionText,
      questionType: questionType ?? this.questionType,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      difficulty: difficulty ?? this.difficulty,
      estimatedTimeSeconds: estimatedTimeSeconds ?? this.estimatedTimeSeconds,
      marks: marks ?? this.marks,
      learningOutcome: learningOutcome ?? this.learningOutcome,
    );
  }
}
