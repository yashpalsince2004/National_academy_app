import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/supabase_providers.dart';
import '../../data/models/dpp_model.dart';
import '../../data/models/dpp_question_model.dart';
import '../../data/models/dpp_assignment_model.dart';
import '../../data/repositories/dpp_repository_impl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DPP Attempt Screen — shows questions, handles answers, timer, and submits results
// ─────────────────────────────────────────────────────────────────────────────

class DppAttemptScreen extends ConsumerStatefulWidget {
  final String assignmentId;
  const DppAttemptScreen({super.key, required this.assignmentId});

  @override
  ConsumerState<DppAttemptScreen> createState() => _DppAttemptScreenState();
}

class _DppAttemptScreenState extends ConsumerState<DppAttemptScreen> {
  bool _isLoading = true;
  String? _error;

  DppAssignmentModel? _assignment;
  DppModel? _dpp;
  List<DppQuestionModel> _questions = [];

  // Quiz state
  int _currentIndex = 0;
  final Map<String, String> _answers = {}; // question_id -> selected_option (A/B/C/D)
  
  // Timer state
  int _secondsRemaining = 0;
  Timer? _timer;
  late DateTime _startedAt;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _loadQuizData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuizData() async {
    try {
      final repo = ref.read(dppRepositoryProvider);
      
      // 1. Fetch assignment
      final assignment = await repo.fetchAssignmentById(widget.assignmentId);
      if (assignment == null) {
        setState(() {
          _error = 'Assignment not found.';
          _isLoading = false;
        });
        return;
      }

      // 2. Fetch DPP details
      final dpp = await repo.fetchDppById(assignment.dppId);
      if (dpp == null) {
        setState(() {
          _error = 'DPP content not found.';
          _isLoading = false;
        });
        return;
      }

      // 3. Fetch Questions
      final questions = await repo.fetchQuestionsForDpp(assignment.dppId);
      if (questions.isEmpty) {
        setState(() {
          _error = 'No questions found for this DPP.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _assignment = assignment;
        _dpp = dpp;
        _questions = questions;
        _secondsRemaining = dpp.configTimeMinutes * 60;
        _isLoading = false;
      });

      _startTimer();
    } catch (e) {
      setState(() {
        _error = 'Failed to load test: $e';
        _isLoading = false;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
        _autoSubmit();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _autoSubmit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Time is up! Submitting your answers automatically...'),
        backgroundColor: AppColors.error,
      ),
    );
    _performSubmission();
  }

  Future<void> _performSubmission() async {
    _timer?.cancel();
    setState(() => _isLoading = true);

    try {
      final studentId = await ref.read(studentIdProvider.future);
      if (studentId == null) throw Exception('Student ID not found');

      final repo = ref.read(dppRepositoryProvider);

      // Create an attempt row first
      final attemptId = await repo.createAttempt(
        assignmentId: widget.assignmentId,
        studentId: studentId,
      );

      // Compute score and answer stats
      int correctCount = 0;
      int wrongCount = 0;
      int skippedCount = 0;

      for (final q in _questions) {
        final studentAns = _answers[q.id];
        if (studentAns == null || studentAns.isEmpty) {
          skippedCount++;
        } else if (studentAns.trim().toUpperCase() == q.correctAnswer.trim().toUpperCase()) {
          correctCount++;
        } else {
          wrongCount++;
        }
      }

      // Compute total marks/scores
      // Let's check marks per question config
      final marksPerQ = _dpp?.configMarksPerQuestion ?? 4;
      final negativeMark = _dpp?.configNegativeMarking ?? 1.0;
      
      final double score = (correctCount * marksPerQ) - (wrongCount * negativeMark);
      final int totalQs = _questions.length;
      final int timeTaken = DateTime.now().difference(_startedAt).inSeconds;

      // Submit attempt details
      await repo.submitAttempt(
        attemptId: attemptId,
        studentId: studentId,
        answers: _answers,
        score: score,
        totalQuestions: totalQs,
        correctAnswers: correctCount,
        wrongAnswers: wrongCount,
        skippedQuestions: skippedCount,
        timeTakenSeconds: timeTaken,
      );

      // Invalidate the feed provider to reload the completed status
      ref.invalidate(studentDppFeedProvider);

      if (mounted) {
        // Show success screen or bottom sheet
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Test Submitted'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Correct: $correctCount / $totalQs'),
                Text('Wrong: $wrongCount'),
                Text('Skipped: $skippedCount'),
                const SizedBox(height: 8),
                Text(
                  'Score: ${score.toStringAsFixed(1)} / ${totalQs * marksPerQ}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  context.pop(); // Return to dashboard
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit test: $e'), backgroundColor: Colors.redAccent),
        );
        setState(() => _isLoading = false);
        _startTimer(); // Resume timer
      }
    }
  }

  void _showSubmitConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Test?'),
        content: Text(
          'Are you sure you want to submit your answers? You have answered ${_answers.length} out of ${_questions.length} questions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performSubmission();
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.ink;
    final cardBg = isDark ? AppColors.surfaceTile1 : AppColors.canvas;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Test Error')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentIndex];
    final selectedOption = _answers[currentQuestion.id];

    // Attempt to extract options safely
    List<dynamic> rawOptions = [];
    if (currentQuestion.options is List) {
      rawOptions = currentQuestion.options as List;
    }

    final optionLabels = ['A', 'B', 'C', 'D'];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Block back button to prevent accidental quits
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Quit Test?'),
            content: const Text('If you quit now, your progress will not be saved.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  context.pop(); // Leave test
                },
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                child: const Text('Quit'),
              ),
            ],
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            _dpp?.title ?? 'DPP Practice',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          actions: [
            // Timer Badge
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _secondsRemaining < 60
                    ? AppColors.error.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: _secondsRemaining < 60 ? AppColors.error : AppColors.primary,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: _secondsRemaining < 60 ? AppColors.error : AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDuration(_secondsRemaining),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      color: _secondsRemaining < 60 ? AppColors.error : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Question Progress Bar
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              backgroundColor: AppColors.hairline,
              color: AppColors.primary,
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Meta Info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Question ${_currentIndex + 1} of ${_questions.length}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '+${_dpp?.configMarksPerQuestion ?? 4} / -${_dpp?.configNegativeMarking ?? 1.0}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Question Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.hairline),
                      ),
                      child: Text(
                        currentQuestion.questionText,
                        style: TextStyle(
                          fontSize: 16,
                          color: textColor,
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Options List
                    ...List.generate(rawOptions.length, (optIdx) {
                      final optionText = rawOptions[optIdx].toString();
                      final optionLetter = optionLabels[optIdx];
                      final isSelected = selectedOption == optionLetter;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : cardBg,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              setState(() {
                                _answers[currentQuestion.id] = optionLetter;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.hairline,
                                  width: isSelected ? 1.8 : 1.0,
                                ),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  // Styled selection badge
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary
                                          : theme.dividerColor.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        optionLetter,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.white
                                              : textColor.withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      optionText,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: textColor,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: const Border(top: BorderSide(color: AppColors.hairline)),
              ),
              child: Row(
                children: [
                  // Previous button
                  if (_currentIndex > 0)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        setState(() {
                          _currentIndex--;
                        });
                      },
                      child: const Text('Previous'),
                    )
                  else
                    const SizedBox.shrink(),
                  
                  const Spacer(),

                  // Clear Option (if selected)
                  if (selectedOption != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _answers.remove(currentQuestion.id);
                        });
                      },
                      child: const Text('Clear Response'),
                    ),

                  const Spacer(),

                  // Next / Submit button
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _currentIndex == _questions.length - 1
                          ? AppColors.success
                          : AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (_currentIndex < _questions.length - 1) {
                        setState(() {
                          _currentIndex++;
                        });
                      } else {
                        _showSubmitConfirmation();
                      }
                    },
                    child: Text(_currentIndex == _questions.length - 1 ? 'Submit' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
