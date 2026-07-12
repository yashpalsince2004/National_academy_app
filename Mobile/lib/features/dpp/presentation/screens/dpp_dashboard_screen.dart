import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/dpp_generator_controller.dart';

class DppDashboardScreen extends ConsumerStatefulWidget {
  const DppDashboardScreen({super.key});

  @override
  ConsumerState<DppDashboardScreen> createState() => _DppDashboardScreenState();
}

class _DppDashboardScreenState extends ConsumerState<DppDashboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _chapterController = TextEditingController();
  final _topicsController = TextEditingController();
  final _questionsController = TextEditingController(text: '5');
  final _timeController = TextEditingController(text: '30');
  final _marksController = TextEditingController();

  String _selectedExam = 'JEE';
  String? _selectedSubject;
  String _selectedDifficulty = 'Medium';

  final List<String> _exams = const ['JEE', 'NEET', 'NDA'];
  final List<String> _allPossibleSubjects = const [
    'Physics',
    'Chemistry',
    'Mathematics',
    'Biology',
    'English',
    'Reasoning',
    'GK'
  ];

  @override
  void initState() {
    super.initState();
    _selectedSubject = _getSubjectsForExam(_selectedExam).first;
  }

  @override
  void dispose() {
    _chapterController.dispose();
    _topicsController.dispose();
    _questionsController.dispose();
    _timeController.dispose();
    _marksController.dispose();
    super.dispose();
  }

  List<String> _getSubjectsForExam(String exam) {
    switch (exam.toUpperCase()) {
      case 'JEE':
        return ['Physics', 'Chemistry', 'Mathematics'];
      case 'NEET':
        return ['Physics', 'Chemistry', 'Biology'];
      case 'NDA':
        return ['Mathematics', 'Biology', 'English', 'Reasoning', 'GK'];
      default:
        return ['Physics', 'Chemistry', 'Mathematics'];
    }
  }

  void _onExamChanged(String exam) {
    setState(() {
      _selectedExam = exam;
      final active = _getSubjectsForExam(exam);
      if (!active.contains(_selectedSubject)) {
        _selectedSubject = active.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(dppGeneratorControllerProvider);

    // Watch for success generation and navigate
    ref.listen(dppGeneratorControllerProvider, (previous, next) {
      if (next.generatedDpp != null && !next.isLoading) {
        context.push('/admin/dpp/preview');
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.redAccent),
        );
      }
    });

    final scaffoldBgColor = isDark ? const Color(0xFF151516) : const Color(0xFFFAFAFC);
    final cardBgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final inputFillColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);
    final borderColor = isDark ? const Color(0xFF3C3C3E) : const Color(0xFFE5E5EA);
    final textHeaderColor = isDark ? Colors.grey.shade400 : const Color(0xFF6E6E73);
    const deepBlueColor = Color(0xFF0038A8);

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: scaffoldBgColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'NA Smart DPP',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -0.6,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, size: 24),
            onPressed: () => context.push('/admin/dpp/history'),
          )
        ],
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
              children: [
                // SECTION: EXAM
                _buildSectionLabel('EXAM', textHeaderColor),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  children: _exams.map((exam) {
                    final isSel = _selectedExam == exam;
                    return ChoiceChip(
                      label: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        child: Text(
                          exam,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isSel ? Colors.white : const Color(0xFF6E6E73),
                          ),
                        ),
                      ),
                      selected: isSel,
                      selectedColor: deepBlueColor,
                      backgroundColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                      checkmarkColor: Colors.transparent,
                      showCheckmark: false,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9999),
                        side: BorderSide(
                          color: isSel ? deepBlueColor : borderColor,
                          width: 1,
                        ),
                      ),
                      onSelected: (val) {
                        if (val) _onExamChanged(exam);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // SECTION: SUBJECT
                _buildSectionLabel('SUBJECT', textHeaderColor),
                const SizedBox(height: 8),
                Wrap(
                  children: _allPossibleSubjects.map((sub) {
                    final isActive = _getSubjectsForExam(_selectedExam).contains(sub);
                    return _buildAnimatedSubjectChip(
                      sub: sub,
                      isActive: isActive,
                      isDark: isDark,
                      deepBlueColor: deepBlueColor,
                      borderColor: borderColor,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // SECTION: CHAPTER NAME
                _buildSectionLabel('CHAPTER NAME', textHeaderColor),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _chapterController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Kinematics, Thermodynamics',
                    hintStyle: TextStyle(color: isDark ? Colors.grey.shade600 : Colors.grey.shade500, fontSize: 15),
                    filled: true,
                    fillColor: inputFillColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: deepBlueColor, width: 1.5),
                    ),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Chapter name is required' : null,
                ),
                const SizedBox(height: 20),

                // SECTION: TOPICS
                _buildSectionLabel('TOPICS (comma-separated, optional)', textHeaderColor),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _topicsController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Projectile Motion, Relative Velocity',
                    hintStyle: TextStyle(color: isDark ? Colors.grey.shade600 : Colors.grey.shade500, fontSize: 15),
                    filled: true,
                    fillColor: inputFillColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: deepBlueColor, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // SECTION: DIFFICULTY LEVEL
                _buildSectionLabel('DIFFICULTY LEVEL', textHeaderColor),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDifficultyCard(
                        title: 'Basic',
                        percentage: '70% easy • 25%\nmed • 5% hard',
                        dotColor: Colors.green,
                        isSelected: _selectedDifficulty == 'Basic',
                        onTap: () => setState(() => _selectedDifficulty = 'Basic'),
                        isDark: isDark,
                        borderColor: borderColor,
                        cardBgColor: cardBgColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDifficultyCard(
                        title: 'Medium',
                        percentage: '30% easy • 50%\nmed • 20% hard',
                        dotColor: Colors.orange,
                        isSelected: _selectedDifficulty == 'Medium',
                        onTap: () => setState(() => _selectedDifficulty = 'Medium'),
                        isDark: isDark,
                        borderColor: borderColor,
                        cardBgColor: cardBgColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDifficultyCard(
                        title: 'High',
                        percentage: '10% easy • 35%\nmed • 55% hard',
                        dotColor: Colors.red,
                        isSelected: _selectedDifficulty == 'High',
                        onTap: () => setState(() => _selectedDifficulty = 'High'),
                        isDark: isDark,
                        borderColor: borderColor,
                        cardBgColor: cardBgColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // SECTION: BOTTOM ROW INPUTS
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Questions Count
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('# QUESTIONS', textHeaderColor),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _questionsController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: inputFillColor,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: deepBlueColor, width: 1.5),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final val = int.tryParse(v);
                              if (val == null || val < 1 || val > 200) return '1-200';
                              return null;
                            },
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '1-200',
                            style: TextStyle(color: isDark ? Colors.grey.shade600 : Colors.grey.shade500, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Allowed Time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('TIME (min)', textHeaderColor),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _timeController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: inputFillColor,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: deepBlueColor, width: 1.5),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final val = int.tryParse(v);
                              if (val == null || val < 5 || val > 240) return '5-240';
                              return null;
                            },
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '5-240',
                            style: TextStyle(color: isDark ? Colors.grey.shade600 : Colors.grey.shade500, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Total Marks
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('TOTAL MARKS', textHeaderColor),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _marksController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'auto',
                              hintStyle: TextStyle(color: isDark ? Colors.grey.shade600 : Colors.grey.shade500, fontSize: 15),
                              filled: true,
                              fillColor: inputFillColor,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: deepBlueColor, width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'optional',
                            style: TextStyle(color: isDark ? Colors.grey.shade600 : Colors.grey.shade500, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom Action Button Layer
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: scaffoldBgColor,
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: deepBlueColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: state.isGenerating ? null : _submitGenerate,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'GENERATE WITH NA',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Shimmer loading / AI Thinking Overlay
          if (state.isGenerating)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              strokeWidth: 4,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0038A8)),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'AI Formulation in progress...',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Composing original questions, options, step-by-step solutions and learning outcomes.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
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
    );
  }

  Widget _buildSectionLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 12,
        color: color,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildAnimatedSubjectChip({
    required String sub,
    required bool isActive,
    required bool isDark,
    required Color deepBlueColor,
    required Color borderColor,
  }) {
    final isSel = _selectedSubject == sub;
    return AnimatedAlign(
      alignment: Alignment.centerLeft,
      duration: const Duration(milliseconds: 300),
      widthFactor: isActive ? 1.0 : 0.0,
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: isActive ? 1.0 : 0.0,
        curve: Curves.easeInOut,
        child: ClipRect(
          child: Padding(
            padding: EdgeInsets.only(right: isActive ? 12.0 : 0.0, bottom: isActive ? 8.0 : 0.0),
            child: ChoiceChip(
              label: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                child: Text(
                  sub,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isSel ? Colors.white : const Color(0xFF6E6E73),
                  ),
                ),
              ),
              selected: isSel,
              selectedColor: deepBlueColor,
              backgroundColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
              checkmarkColor: Colors.transparent,
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9999),
                side: BorderSide(
                  color: isSel ? deepBlueColor : borderColor,
                  width: 1,
                ),
              ),
              onSelected: (val) {
                if (val && isActive) setState(() => _selectedSubject = sub);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyCard({
    required String title,
    required String percentage,
    required Color dotColor,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required Color borderColor,
    required Color cardBgColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: cardBgColor,
          border: Border.all(
            color: isSelected ? const Color(0xFFF1A80A) : borderColor,
            width: isSelected ? 2.0 : 1.0,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFF1A80A).withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 5, backgroundColor: dotColor),
                const SizedBox(width: 6),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: isSelected ? (isDark ? Colors.white : const Color(0xFF0F172A)) : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              percentage,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey.shade400 : const Color(0xFF8E8E93),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitGenerate() {
    if (!_formKey.currentState!.validate()) return;

    final selectedSub = _selectedSubject;
    if (selectedSub == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject')),
      );
      return;
    }

    final List<String> topics = _topicsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final questionsCount = int.parse(_questionsController.text);
    final timeMins = int.parse(_timeController.text);
    final totalMarks = int.tryParse(_marksController.text) ?? (questionsCount * 4); // fallback marks default to 4 per question

    ref.read(dppGeneratorControllerProvider.notifier).generateDpp(
          title: 'Smart DPP Set — $_selectedExam',
          examType: _selectedExam,
          classLevel: 'Class 12', // default class level
          subjectId: selectedSub,
          subjectName: selectedSub,
          chapterName: _chapterController.text.trim(),
          topics: topics,
          difficulty: _selectedDifficulty,
          questionCount: questionsCount,
          timeMinutes: timeMins,
          marksPerQuestion: (totalMarks ~/ questionsCount).clamp(1, 5), // auto-compute marks per question
          negativeMarking: 1.0, // default negative marking
          questionTypes: const ['Single Correct'], // default question types
          aiOption: 'Conceptual', // default option pedagogy
          additionalInstructions: null,
        );
  }
}
