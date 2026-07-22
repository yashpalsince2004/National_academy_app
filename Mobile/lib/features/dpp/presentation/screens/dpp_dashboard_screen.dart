import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/dpp_generator_controller.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;


class DppDashboardScreen extends ConsumerStatefulWidget {
  const DppDashboardScreen({super.key});

  @override
  ConsumerState<DppDashboardScreen> createState() => _DppDashboardScreenState();
}

class _DppDashboardScreenState extends ConsumerState<DppDashboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _chapterController = TextEditingController();
  final _topicsController = TextEditingController();
  final _questionsController = TextEditingController(text: '10');
  final _marksController = TextEditingController();
  final _timeController = TextEditingController(text: '45');
  
  String _selectedSubject = 'Physics';
  String _selectedDifficulty = 'Intermediate';



  @override
  void dispose() {
    _chapterController.dispose();
    _topicsController.dispose();
    _questionsController.dispose();
    _marksController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _submitGenerate() {
    if (!_formKey.currentState!.validate()) return;

    final questionsCount = int.parse(_questionsController.text);
    final timeMins = int.parse(_timeController.text);
    final totalMarks = int.tryParse(_marksController.text) ?? (questionsCount * 4);

    final List<String> topics = _topicsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    // Map difficulty: Basic -> Basic, Intermediate -> Medium, Advance -> High
    String mappedDifficulty = 'Medium';
    if (_selectedDifficulty == 'Basic') {
      mappedDifficulty = 'Basic';
    } else if (_selectedDifficulty == 'Advance') {
      mappedDifficulty = 'High';
    }

    // Call generateDpp
    ref.read(dppGeneratorControllerProvider.notifier).generateDpp(
          title: 'Smart DPP — $_selectedSubject',
          examType: 'JEE',
          classLevel: 'Class 12',
          subjectId: _selectedSubject,
          subjectName: _selectedSubject,
          chapterName: _chapterController.text.trim(),
          topics: topics,
          difficulty: mappedDifficulty,
          questionCount: questionsCount,
          timeMinutes: timeMins,
          marksPerQuestion: (totalMarks ~/ questionsCount).clamp(1, 5),
          negativeMarking: 1.0,
          questionTypes: const ['Single Correct'],
          aiOption: 'Conceptual',
        );
  }

  bool _isLoadingDialogShowing = false;

  void _showLoadingDialog() {
    if (_isLoadingDialogShowing || !mounted) return;
    _isLoadingDialogShowing = true;

    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;
        final cardBg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
        final borderC = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);

        return PopScope(
          canPop: false,
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderC),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset(
                    'assets/Animation/sparkles_loop_loader_ai.lottie',
                    width: 110,
                    height: 110,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'AI Formulation in progress...',
                    style: TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : const Color(0xFF1D1D1F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Composing original questions, options, step-by-step solutions and learning outcomes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'SF Pro Text',
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      _isLoadingDialogShowing = false;
    });
  }

  void _hideLoadingDialog() {
    if (_isLoadingDialogShowing && mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      _isLoadingDialogShowing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(dppGeneratorControllerProvider);

    // Success navigation, dialog management and notifications
    ref.listen(dppGeneratorControllerProvider, (previous, next) {
      if (next.isGenerating) {
        _showLoadingDialog();
      } else {
        _hideLoadingDialog();
      }

      if (next.generatedDpp != null && previous?.isGenerating == true && !next.isGenerating) {
        context.push('/admin/dpp/preview');
      }
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.redAccent),
        );
      }
    });

    // Apple-spec colors
    final scaffoldBgColor = isDark ? const Color(0xFF000000) : const Color(0xFFF5F5F7);
    final cardBgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
    const appleBlue = Color(0xFF0066CC); // Signature Action Blue

    List<Color> getDifficultyGradient(String diff, bool isSel) {
      if (!isSel) {
        return [cardBgColor, cardBgColor];
      }
      return const [appleBlue, appleBlue];
    }

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      body: SafeArea(
        child: Stack(
          children: [
            Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                children: [
                  // Title Header (SF Pro Display, weight 600, negative letter-spacing)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_awesome_rounded, color: appleBlue, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'NA SMART-DPP',
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontWeight: FontWeight.w600,
                          fontSize: 22,
                          letterSpacing: -0.4,
                          color: isDark ? Colors.white : const Color(0xFF1D1D1F),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 1. SUBJECT SELECTOR (2x2 Pill Grid with Solid Gradients)
                  _buildSectionLabel('Subject', isDark),
                  const SizedBox(height: 8),
                  SubjectGridSelector(
                    selectedSubject: _selectedSubject,
                    isDark: isDark,
                    onSubjectSelected: (sub) => setState(() => _selectedSubject = sub),
                  ),
                  const SizedBox(height: 14),

                  // 2. DIFFICULTY LEVEL (Pills)
                  _buildSectionLabel('Difficulty', isDark),
                  const SizedBox(height: 6),
                  Row(
                    children: ['Basic', 'Intermediate', 'Advance'].map((diff) {
                      final isSel = _selectedDifficulty == diff;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: AnimatedTapScale(
                            onTap: () => setState(() => _selectedDifficulty = diff),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: getDifficultyGradient(diff, isSel),
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(9999), // pill
                                border: Border.all(
                                  color: isSel ? Colors.transparent : borderColor,
                                  width: 1.0,
                                ),
                              ),
                              child: Text(
                                diff,
                                style: TextStyle(
                                  fontFamily: 'SF Pro Text',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: isSel ? Colors.white : (isDark ? const Color(0xFFCCCCCC) : const Color(0xFF1D1D1F)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // 4. CHAPTER & TOPIC ROW
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel('Chapter', isDark),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _chapterController,
                              style: TextStyle(
                                fontFamily: 'SF Pro Text',
                                color: isDark ? Colors.white : const Color(0xFF1D1D1F),
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: cardBgColor,
                                hintText: 'e.g. Kinematics',
                                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: appleBlue, width: 1.5),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                                ),
                                errorStyle: const TextStyle(
                                  fontFamily: 'SF Pro Text',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.redAccent,
                                ),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel('Topic (optional)', isDark),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _topicsController,
                              style: TextStyle(
                                fontFamily: 'SF Pro Text',
                                color: isDark ? Colors.white : const Color(0xFF1D1D1F),
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: cardBgColor,
                                hintText: 'e.g. Projectile',
                                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: appleBlue, width: 1.5),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                                ),
                                errorStyle: const TextStyle(
                                  fontFamily: 'SF Pro Text',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 5. QUESTIONS, MARKS, AND TIME ROW
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Questions Count
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel('Questions', isDark),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _questionsController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              style: TextStyle(
                                fontFamily: 'SF Pro Text',
                                color: isDark ? Colors.white : const Color(0xFF1D1D1F),
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: cardBgColor,
                                hintText: 'e.g. 10',
                                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: appleBlue, width: 1.5),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                                ),
                                errorStyle: const TextStyle(
                                  fontFamily: 'SF Pro Text',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.redAccent,
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                final num = int.tryParse(v);
                                if (num == null || num < 1) return 'Min 1';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Marks
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel('Marks', isDark),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _marksController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              style: TextStyle(
                                fontFamily: 'SF Pro Text',
                                color: isDark ? Colors.white : const Color(0xFF1D1D1F),
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: cardBgColor,
                                hintText: 'auto',
                                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: appleBlue, width: 1.5),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                                ),
                                errorStyle: const TextStyle(
                                  fontFamily: 'SF Pro Text',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Time Given
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel('Time (min)', isDark),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _timeController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              style: TextStyle(
                                fontFamily: 'SF Pro Text',
                                color: isDark ? Colors.white : const Color(0xFF1D1D1F),
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: cardBgColor,
                                hintText: 'e.g. 45',
                                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: appleBlue, width: 1.5),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                                ),
                                errorStyle: const TextStyle(
                                  fontFamily: 'SF Pro Text',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.redAccent,
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                final num = int.tryParse(v);
                                if (num == null || num < 1) return 'Min 1';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 6. PREVIOUS DPP BUTTON (Ghost Pill Style)
                  AnimatedTapScale(
                    onTap: () => context.push('/admin/dpp/history'),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1D1D1F) : Colors.white,
                        borderRadius: BorderRadius.circular(9999), // pill
                        border: Border.all(color: borderColor, width: 1.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_rounded, size: 18, color: isDark ? Colors.white70 : const Color(0xFF1D1D1F)),
                          const SizedBox(width: 6),
                          Text(
                            'Previous DPP',
                            style: TextStyle(
                              fontFamily: 'SF Pro Text',
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: isDark ? Colors.white : const Color(0xFF1D1D1F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),

            // Bottom Action Button Layer
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                decoration: BoxDecoration(
                  color: scaffoldBgColor,
                  border: Border(top: BorderSide(color: borderColor)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: AnimatedTapScale(
                    onTap: state.isGenerating ? () {} : _submitGenerate,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: state.isGenerating ? appleBlue.withValues(alpha: 0.5) : appleBlue,
                        borderRadius: BorderRadius.circular(9999), // Primary action is pill-shaped
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.auto_awesome_rounded, size: 18, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'GENERATE WITH NA',
                            style: TextStyle(
                              fontFamily: 'SF Pro Text',
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              letterSpacing: -0.1,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'SF Pro Text',
        fontWeight: FontWeight.w600,
        fontSize: 13,
        letterSpacing: -0.1,
        color: isDark ? const Color(0xFFCCCCCC) : const Color(0xFF1D1D1F),
      ),
    );
  }
}

// ── 2x2 SUBJECT GRID WITH SOLID GRADIENT PILL CARDS ────────────────────────

class SubjectGridSelector extends StatelessWidget {
  final String selectedSubject;
  final bool isDark;
  final ValueChanged<String> onSubjectSelected;

  const SubjectGridSelector({
    super.key,
    required this.selectedSubject,
    required this.isDark,
    required this.onSubjectSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SubjectCardPill(
                subject: 'Physics',
                isSelected: selectedSubject.toLowerCase() == 'physics',
                isDark: isDark,
                onTap: () => onSubjectSelected('Physics'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SubjectCardPill(
                subject: 'Chemistry',
                isSelected: selectedSubject.toLowerCase() == 'chemistry',
                isDark: isDark,
                onTap: () => onSubjectSelected('Chemistry'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SubjectCardPill(
                subject: 'Mathematics',
                isSelected: selectedSubject.toLowerCase() == 'mathematics',
                isDark: isDark,
                onTap: () => onSubjectSelected('Mathematics'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SubjectCardPill(
                subject: 'Biology',
                isSelected: selectedSubject.toLowerCase() == 'biology',
                isDark: isDark,
                onTap: () => onSubjectSelected('Biology'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SubjectCardPill extends StatelessWidget {
  final String subject;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _SubjectCardPill({
    required this.subject,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final meta = _getSubjectMeta(subject);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 56,
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: meta.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected
              ? null
              : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
          borderRadius: BorderRadius.circular(9999), // Pill shape
          border: Border.all(
            color: isSelected
                ? meta.gradientColors.first
                : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA)),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Stack(
          children: [
            // Background Watermark Motif
            Positioned.fill(
              child: CustomPaint(
                painter: meta.painter(
                  isSelected
                      ? Colors.white.withValues(alpha: 0.22)
                      : meta.gradientColors.first.withValues(alpha: isDark ? 0.12 : 0.08),
                ),
              ),
            ),

            // Card Content (Icon, Label, Checkmark) - Perfectly Centered
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon Badge (Centered 34x34 Circle)
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.25)
                            : meta.gradientColors.first.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        meta.icon,
                        size: 18,
                        color: isSelected ? Colors.white : meta.gradientColors.first,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Label Text
                    Expanded(
                      child: Text(
                        subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 14,
                          letterSpacing: -0.2,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? const Color(0xFFEEEEEE) : const Color(0xFF1D1D1F)),
                        ),
                      ),
                    ),

                    // Active Checkmark Indicator
                    if (isSelected) ...[
                      const SizedBox(width: 4),
                      Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 13,
                          color: meta.gradientColors.first,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _SubjectMeta _getSubjectMeta(String subject) {
    switch (subject.toLowerCase()) {
      case 'physics':
        return _SubjectMeta(
          icon: Icons.alt_route_rounded,
          gradientColors: const [Color(0xFF0052D4), Color(0xFF4364F7)],
          painter: (color) => PhysicsTrajectoryPainter(color: color),
        );
      case 'chemistry':
        return _SubjectMeta(
          icon: Icons.science_rounded,
          gradientColors: const [Color(0xFF11998E), Color(0xFF38EF7D)],
          painter: (color) => ChemistryCarbonChainPainter(color: color),
        );
      case 'mathematics':
      case 'maths':
      case 'math':
        return _SubjectMeta(
          icon: Icons.functions_rounded,
          gradientColors: const [Color(0xFF7F00FF), Color(0xFFE100FF)],
          painter: (color) => MathFormulasPainter(color: color),
        );
      case 'biology':
        return _SubjectMeta(
          icon: Icons.monitor_heart_rounded,
          gradientColors: const [Color(0xFFFF0844), Color(0xFFFFB199)],
          painter: (color) => BiologyHeartPulsePainter(color: color),
        );
      default:
        return _SubjectMeta(
          icon: Icons.book_rounded,
          gradientColors: const [Color(0xFF0066CC), Color(0xFF5AC8FA)],
          painter: (color) => PhysicsTrajectoryPainter(color: color),
        );
    }
  }
}

class _SubjectMeta {
  final IconData icon;
  final List<Color> gradientColors;
  final CustomPainter Function(Color color) painter;

  _SubjectMeta({
    required this.icon,
    required this.gradientColors,
    required this.painter,
  });
}

// ── CUSTOM WATERMARK PAINTERS ──────────────────────────────────────────────

/// Physics Background Motif: Projectile Motion Arc Trajectory Curve
class PhysicsTrajectoryPainter extends CustomPainter {
  final Color color;
  PhysicsTrajectoryPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final startX = size.width * 0.45;
    final startY = size.height * 0.85;
    final controlX = size.width * 0.72;
    final controlY = size.height * 0.12;
    final endX = size.width * 0.95;
    final endY = size.height * 0.85;

    path.moveTo(startX, startY);
    path.quadraticBezierTo(controlX, controlY, endX, endY);
    canvas.drawPath(path, paint);

    // Initial Velocity Vector Arrow at origin
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(startX, startY), Offset(startX + 18, startY - 14), arrowPaint);
    canvas.drawLine(Offset(startX + 18, startY - 14), Offset(startX + 12, startY - 14), arrowPaint);
    canvas.drawLine(Offset(startX + 18, startY - 14), Offset(startX + 16, startY - 8), arrowPaint);

    // Origin & Peak dots
    canvas.drawCircle(Offset(startX, startY), 2.5, Paint()..color = color..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(controlX, size.height * 0.48), 2.0, Paint()..color = color..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant PhysicsTrajectoryPainter oldDelegate) => oldDelegate.color != color;
}

/// Chemistry Background Motif: Carbon Chain & Benzene Ring
class ChemistryCarbonChainPainter extends CustomPainter {
  final Color color;
  ChemistryCarbonChainPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final cx = size.width * 0.80;
    final cy = size.height * 0.50;
    final r = 16.0;

    // Benzene Hexagon Ring
    final hexPath = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        hexPath.moveTo(x, y);
      } else {
        hexPath.lineTo(x, y);
      }
    }
    hexPath.close();
    canvas.drawPath(hexPath, paint);

    // Inner aromatic bond circle
    canvas.drawCircle(Offset(cx, cy), r * 0.55, paint);

    // Carbon chain extension bonds
    canvas.drawLine(Offset(cx - r, cy), Offset(cx - r - 12, cy - 8), paint);
    canvas.drawCircle(Offset(cx - r - 12, cy - 8), 2.2, Paint()..color = color..style = PaintingStyle.fill);

    canvas.drawLine(Offset(cx + r, cy), Offset(cx + r + 10, cy + 8), paint);
    canvas.drawCircle(Offset(cx + r + 10, cy + 8), 2.2, Paint()..color = color..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant ChemistryCarbonChainPainter oldDelegate) => oldDelegate.color != color;
}

/// Mathematics Background Motif: Formulas & Notation (∫, π, ∑)
class MathFormulasPainter extends CustomPainter {
  final Color color;
  MathFormulasPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Integral notation ∫
    textPainter.text = TextSpan(
      text: '∫',
      style: TextStyle(
        fontFamily: 'SF Pro Display',
        fontSize: 32,
        fontWeight: FontWeight.w300,
        color: color,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.66, size.height * 0.08));

    // Pi symbol π
    textPainter.text = TextSpan(
      text: 'π',
      style: TextStyle(
        fontFamily: 'SF Pro Display',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.85, size.height * 0.18));

    // Summation ∑
    textPainter.text = TextSpan(
      text: '∑',
      style: TextStyle(
        fontFamily: 'SF Pro Display',
        fontSize: 22,
        fontWeight: FontWeight.w400,
        color: color,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.78, size.height * 0.48));
  }

  @override
  bool shouldRepaint(covariant MathFormulasPainter oldDelegate) => oldDelegate.color != color;
}

/// Biology Background Motif: Heart Silhouette & ECG Pulse Wave
class BiologyHeartPulsePainter extends CustomPainter {
  final Color color;
  BiologyHeartPulsePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // ECG Heart Pulse line
    final path = Path();
    final startX = size.width * 0.40;
    final cy = size.height * 0.58;

    path.moveTo(startX, cy);
    path.lineTo(startX + 12, cy);
    path.lineTo(startX + 16, cy - 7);
    path.lineTo(startX + 20, cy + 10);
    path.lineTo(startX + 26, cy - 20);
    path.lineTo(startX + 32, cy + 8);
    path.lineTo(startX + 37, cy);
    path.lineTo(startX + 55, cy);

    canvas.drawPath(path, paint);

    // Heart silhouette on top right
    final heartPath = Path();
    final hx = size.width * 0.84;
    final hy = size.height * 0.28;

    heartPath.moveTo(hx, hy + 5);
    heartPath.cubicTo(hx - 7, hy - 5, hx - 12, hy + 5, hx, hy + 14);
    heartPath.cubicTo(hx + 12, hy + 5, hx + 7, hy - 5, hx, hy + 5);

    canvas.drawPath(heartPath, Paint()..color = color..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant BiologyHeartPulsePainter oldDelegate) => oldDelegate.color != color;
}

// Custom interactive wrapper adhering to transform: scale(0.95) rule
class AnimatedTapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const AnimatedTapScale({super.key, required this.child, required this.onTap});

  @override
  State<AnimatedTapScale> createState() => _AnimatedTapScaleState();
}

class _AnimatedTapScaleState extends State<AnimatedTapScale> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
