import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../features/dpp/data/models/dpp_question_model.dart';

class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  /// Generates questions using Google Gemini API. Falls back to realistic mock questions if API key is missing.
  Future<List<DppQuestionModel>> generateQuestions({
    required String examType,
    required String classLevel,
    required String subjectName,
    required String chapterName,
    required List<String> topics,
    required String difficulty,
    required int questionCount,
    required List<String> questionTypes,
    required String aiOption,
    String? additionalInstructions,
    required int marksPerQuestion,
  }) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

    final promptText = _buildPrompt(
      examType: examType,
      classLevel: classLevel,
      subjectName: subjectName,
      chapterName: chapterName,
      topics: topics,
      difficulty: difficulty,
      questionCount: questionCount,
      questionTypes: questionTypes,
      aiOption: aiOption,
      additionalInstructions: additionalInstructions,
      marksPerQuestion: marksPerQuestion,
    );

    if (apiKey.isEmpty || apiKey == 'your-gemini-api-key') {
      debugPrint('No Gemini API key found, generating high-quality mock questions.');
      await Future.delayed(const Duration(seconds: 3)); // simulate API call
      return _generateSubjectAwareMockQuestions(
        examType: examType,
        subjectName: subjectName,
        chapterName: chapterName,
        topics: topics,
        difficulty: difficulty,
        questionCount: questionCount,
        questionTypes: questionTypes,
        marksPerQuestion: marksPerQuestion,
      );
    }

    try {
      // Use gemini-2.5-flash for higher quality, subject-aware generation
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.15,
        ),
      );

      final content = [Content.text(promptText)];
      final response = await model.generateContent(content);
      final jsonText = response.text ?? '[]';

      final List<dynamic> decoded = jsonDecode(jsonText);
      return decoded.map((q) => DppQuestionModel.fromJson({
        ...q as Map<String, dynamic>,
        'dpp_id': '',
        'marks': q['marks'] ?? marksPerQuestion,
      })).toList();
    } catch (e) {
      debugPrint('Error generating content with Gemini: $e. Falling back to mock.');
      return _generateSubjectAwareMockQuestions(
        examType: examType,
        subjectName: subjectName,
        chapterName: chapterName,
        topics: topics,
        difficulty: difficulty,
        questionCount: questionCount,
        questionTypes: questionTypes,
        marksPerQuestion: marksPerQuestion,
      );
    }
  }

  String _buildPrompt({
    required String examType,
    required String classLevel,
    required String subjectName,
    required String chapterName,
    required List<String> topics,
    required String difficulty,
    required int questionCount,
    required List<String> questionTypes,
    required String aiOption,
    String? additionalInstructions,
    required int marksPerQuestion,
  }) {
    final subjectLower = subjectName.toLowerCase();
    final latexNote = subjectLower.contains('biology') || subjectLower.contains('zoology') || subjectLower.contains('botany')
        ? 'Use LaTeX ONLY for chemical formulas (e.g. \$O_2\$, \$CO_2\$) and genetic notations (e.g. \$F_1\$). NEVER use mathematical equations, calculus, or physics formulas.'
        : 'Use LaTeX for equations (e.g. \$F = ma\$) and block equations (e.g. \$\$\\int_0^1 x dx\$\$).';

    return '''
You are a Senior $examType $subjectName Faculty. Generate exactly $questionCount questions.

CRITICAL RULES:
- Subject: $subjectName | Chapter: $chapterName
- Do NOT mention the exam name, subject, chapter, or difficulty inside the question text.
- Just write the direct examination question (e.g. "The nephron is responsible for..." NOT "For NEET Biology, the nephron...")
- $latexNote

Configuration:
- Exam: $examType | Class: $classLevel | Difficulty: $difficulty
- Topics: ${topics.join(', ')}
- Question Types: ${questionTypes.join(', ')}
- Marks per question: $marksPerQuestion
- Pedagogy: $aiOption
${additionalInstructions != null && additionalInstructions.isNotEmpty ? '- Additional Instructions: $additionalInstructions' : ''}

Return a valid JSON array of exactly $questionCount question objects. Each object:
{
  "question_text": "Direct exam question text without subject/exam prefix.",
  "question_type": "One of: ${questionTypes.join(', ')}",
  "options": ["Option A", "Option B", "Option C", "Option D"], // Provide 4 options. Put null or omit if it's Numerical, subjective, or fill in blanks.
  "correct_answer": "The correct option label (e.g. 'Option A' or 'A') or direct numeric answer/text depending on type.",
  "explanation": "Provide a detailed step-by-step mathematical or logical explanation. Use LaTeX for equations where needed.",
  "difficulty": "Easy, Medium, or Hard",
  "estimated_time_seconds": 120, // estimated time in seconds to solve this question
  "marks": $marksPerQuestion,
  "learning_outcome": "A short sentence describing what this question tests."
}
''';
  }

  /// Subject-aware mock generator — routes by subject, no cross-contamination.
  List<DppQuestionModel> _generateSubjectAwareMockQuestions({
    required String examType,
    required String subjectName,
    required String chapterName,
    required List<String> topics,
    required String difficulty,
    required int questionCount,
    required List<String> questionTypes,
    required int marksPerQuestion,
  }) {
    final subjectLower = subjectName.toLowerCase();
    final selectedTopics = topics.isNotEmpty ? topics : [chapterName];
    final List<DppQuestionModel> results = [];

    for (int i = 1; i <= questionCount; i++) {
      final topic = selectedTopics[(i - 1) % selectedTopics.length];
      final qType = questionTypes.isNotEmpty
          ? questionTypes[(i - 1) % questionTypes.length]
          : 'Single Correct';

      DppQuestionModel question;

      if (subjectLower.contains('biology') ||
          subjectLower.contains('zoology') ||
          subjectLower.contains('botany')) {
        question = _buildBiologyMock(i, topic, chapterName, difficulty, qType, marksPerQuestion);
      } else if (subjectLower.contains('chemistry')) {
        question = _buildChemistryMock(i, topic, chapterName, difficulty, qType, marksPerQuestion);
      } else if (subjectLower.contains('physics')) {
        question = _buildPhysicsMock(i, topic, chapterName, difficulty, qType, marksPerQuestion);
      } else if (subjectLower.contains('math')) {
        question = _buildMathsMock(i, topic, chapterName, difficulty, qType, marksPerQuestion);
      } else {
        question = DppQuestionModel(
          id: 'q-mock-$i',
          dppId: '',
          questionText: 'Which of the following correctly describes a key concept in $chapterName — $topic?',
          questionType: qType,
          options: const [
            'It involves the fundamental principle of energy conservation',
            'It is governed by the laws of thermodynamics only',
            'It is independent of environmental conditions',
            'It operates exclusively at the cellular level',
          ],
          correctAnswer: 'A',
          explanation: 'The core principle of $topic in $chapterName relies on energy conservation across all systems.',
          difficulty: difficulty,
          estimatedTimeSeconds: 90,
          marks: marksPerQuestion,
          learningOutcome: 'Conceptual understanding of $topic.',
        );
      }
      results.add(question);
    }
    return results;
  }

  DppQuestionModel _buildBiologyMock(
      int i, String topic, String chapter, String difficulty, String qType, int marks) {
    final bank = [
      _MockQ(
        q: 'Which of the following is the structural and functional unit of the kidney?',
        opts: ['Nephron', 'Glomerulus', "Bowman's capsule", 'Loop of Henle'],
        ans: 'A',
        exp: "The nephron is the structural and functional unit of the kidney. Each kidney contains ~1 million nephrons. "
            "It comprises the Bowman's capsule, PCT, Loop of Henle, DCT, and collecting duct.",
        outcome: 'Structure and function of the nephron.',
      ),
      _MockQ(
        q: 'In which region of the nephron does most selective reabsorption of glucose and amino acids occur?',
        opts: ['Proximal Convoluted Tubule (PCT)', 'Distal Convoluted Tubule (DCT)', 'Loop of Henle', 'Collecting Duct'],
        ans: 'A',
        exp: 'The PCT is lined with microvilli (brush border) increasing surface area. About 70–80% of filtrate '
            'including all glucose and amino acids is reabsorbed here by active transport.',
        outcome: 'Tubular reabsorption in the PCT.',
      ),
      _MockQ(
        q: 'The countercurrent mechanism in the Loop of Henle primarily functions to:',
        opts: [
          'Concentrate urine by maintaining a medullary osmotic gradient',
          'Filter blood plasma at high pressure',
          'Reabsorb glucose by active transport',
          'Secrete urea into the filtrate',
        ],
        ans: 'A',
        exp: 'Descending limb is water-permeable/solute-impermeable; ascending limb is solute-permeable/'
            'water-impermeable. This establishes a hyperosmotic medullary gradient, concentrating urine.',
        outcome: 'Countercurrent mechanism and urine concentration.',
      ),
      _MockQ(
        q: 'Which hormone inserts aquaporin channels into the collecting duct to promote water reabsorption?',
        opts: [
          'ADH (Antidiuretic Hormone / Vasopressin)',
          'Aldosterone',
          'Renin',
          'Atrial Natriuretic Factor (ANF)',
        ],
        ans: 'A',
        exp: 'ADH (Vasopressin) is released by the posterior pituitary in response to high plasma osmolarity. '
            'It increases aquaporin-2 expression in the collecting duct, promoting water reabsorption and '
            'producing hypertonic urine.',
        outcome: 'Hormonal regulation of urine concentration by ADH.',
      ),
      _MockQ(
        q: 'Assertion (A): Kidneys regulate blood plasma osmolarity.\n'
            'Reason (R): Glomerular filtrate is processed by selective reabsorption and tubular secretion.',
        opts: [
          'Both A and R are true, and R is the correct explanation of A',
          'Both A and R are true, but R is NOT the correct explanation of A',
          'A is true but R is false',
          'A is false but R is true',
        ],
        ans: 'A',
        exp: 'Kidneys regulate plasma osmolarity by tubular processing: essential solutes are reabsorbed '
            'and excess ions/waste are secreted. This balances plasma composition and osmolarity.',
        outcome: 'Assertion-Reason: osmoregulation by kidneys.',
      ),
    ];
    final m = bank[(i - 1) % bank.length];
    return DppQuestionModel(
      id: 'q-mock-$i', dppId: '',
      questionText: m.q, questionType: qType, options: m.opts,
      correctAnswer: m.ans, explanation: m.exp, difficulty: difficulty,
      estimatedTimeSeconds: 90 + (i * 10), marks: marks, learningOutcome: m.outcome,
    );
  }

  DppQuestionModel _buildPhysicsMock(
      int i, String topic, String chapter, String difficulty, String qType, int marks) {
    final bank = [
      _MockQ(
        q: r'A particle moves with velocity $v = 3t^2 - 2t + 1$ m/s. The acceleration at $t = 2$ s is:',
        opts: [r'$10$ m/s$^2$', r'$8$ m/s$^2$', r'$12$ m/s$^2$', r'$6$ m/s$^2$'],
        ans: 'A',
        exp: r'$a = \frac{dv}{dt} = 6t - 2$. At $t = 2$ s: $a = 6(2) - 2 = 10$ m/s$^2$.',
        outcome: 'Differentiation-based kinematics.',
      ),
      _MockQ(
        q: r'A uniform rod of mass $M$ and length $L$ has its moment of inertia about one end:',
        opts: [r'$\frac{ML^2}{3}$', r'$\frac{ML^2}{12}$', r'$\frac{ML^2}{4}$', r'$ML^2$'],
        ans: 'A',
        exp: r'$I = \int_0^L \frac{M}{L} x^2\, dx = \frac{M}{L}\cdot\frac{L^3}{3} = \frac{ML^2}{3}$.',
        outcome: 'Moment of inertia by integration.',
      ),
      _MockQ(
        q: r'A charge $q$ is placed at the center of a cube. The electric flux through one face is:',
        opts: [r'$\frac{q}{6\varepsilon_0}$', r'$\frac{q}{\varepsilon_0}$', r'$\frac{q}{4\varepsilon_0}$', r'$\frac{q}{3\varepsilon_0}$'],
        ans: 'A',
        exp: r"By Gauss's law total flux $= \frac{q}{\varepsilon_0}$. By symmetry each face gets $\frac{q}{6\varepsilon_0}$.",
        outcome: "Gauss's law with symmetry.",
      ),
    ];
    final m = bank[(i - 1) % bank.length];
    return DppQuestionModel(
      id: 'q-mock-$i', dppId: '',
      questionText: m.q, questionType: qType, options: m.opts,
      correctAnswer: m.ans, explanation: m.exp, difficulty: difficulty,
      estimatedTimeSeconds: 120 + (i * 15), marks: marks, learningOutcome: m.outcome,
    );
  }

  DppQuestionModel _buildChemistryMock(
      int i, String topic, String chapter, String difficulty, String qType, int marks) {
    final bank = [
      _MockQ(
        q: r'The IUPAC name of $CH_3\text{-}CH(OH)\text{-}CH_3$ is:',
        opts: ['Propan-2-ol', 'Propan-1-ol', '2-Methylpropanol', 'Isopropyl alcohol'],
        ans: 'A',
        exp: r'3-carbon chain with $-OH$ at C-2 ⟹ Propan-2-ol (IUPAC).',
        outcome: 'IUPAC nomenclature of secondary alcohols.',
      ),
      _MockQ(
        q: r'For $N_2 + 3H_2 \rightleftharpoons 2NH_3$, doubling pressure at constant temperature will:',
        opts: [
          r'Shift equilibrium towards $NH_3$ but $K_c$ remains unchanged',
          r'Increase $K_c$ by a factor of 2',
          r'Decrease $K_c$ by a factor of 2',
          r'Have no effect on equilibrium position',
        ],
        ans: 'A',
        exp: r'$K_c$ depends only on temperature. Doubling pressure shifts equilibrium toward the side with '
            r'fewer moles (products), but $K_c$ remains constant.',
        outcome: r'Le Chatelier principle and equilibrium constant $K_c$.',
      ),
      _MockQ(
        q: r'The oxidation state of Cr in $K_2Cr_2O_7$ is:',
        opts: [r'$+6$', r'$+3$', r'$+4$', r'$+7$'],
        ans: 'A',
        exp: r'$2(+1) + 2x + 7(-2) = 0 \Rightarrow x = +6$.',
        outcome: 'Oxidation state in dichromate ion.',
      ),
    ];
    final m = bank[(i - 1) % bank.length];
    return DppQuestionModel(
      id: 'q-mock-$i', dppId: '',
      questionText: m.q, questionType: qType, options: m.opts,
      correctAnswer: m.ans, explanation: m.exp, difficulty: difficulty,
      estimatedTimeSeconds: 100 + (i * 10), marks: marks, learningOutcome: m.outcome,
    );
  }

  DppQuestionModel _buildMathsMock(
      int i, String topic, String chapter, String difficulty, String qType, int marks) {
    final bank = [
      _MockQ(
        q: r'The value of $\lim_{x \to 0} \dfrac{\sin(3x)}{x}$ is:',
        opts: [r'$3$', r'$1$', r'$0$', r'$\infty$'],
        ans: 'A',
        exp: r'Using $\lim_{x \to 0} \frac{\sin(ax)}{x} = a$, with $a = 3$, the answer is $3$.',
        outcome: 'Standard trigonometric limits.',
      ),
      _MockQ(
        q: r'The definite integral $\int_0^{\pi/2} \sin x\, dx$ equals:',
        opts: [r'$1$', r'$0$', r'$2$', r'$\pi/2$'],
        ans: 'A',
        exp: r'$[-\cos x]_0^{\pi/2} = -\cos(\pi/2) + \cos 0 = 0 + 1 = 1$.',
        outcome: 'Definite integration of trigonometric functions.',
      ),
      _MockQ(
        q: r'If $A = \begin{pmatrix}2&1\\3&4\end{pmatrix}$, then $\det(A)$ is:',
        opts: [r'$5$', r'$8$', r'$-5$', r'$11$'],
        ans: 'A',
        exp: r'$\det(A) = 2 \cdot 4 - 1 \cdot 3 = 8 - 3 = 5$.',
        outcome: 'Determinant of a 2×2 matrix.',
      ),
    ];
    final m = bank[(i - 1) % bank.length];
    return DppQuestionModel(
      id: 'q-mock-$i', dppId: '',
      questionText: m.q, questionType: qType, options: m.opts,
      correctAnswer: m.ans, explanation: m.exp, difficulty: difficulty,
      estimatedTimeSeconds: 120 + (i * 15), marks: marks, learningOutcome: m.outcome,
    );
  }
}

class _MockQ {
  final String q;
  final List<String> opts;
  final String ans;
  final String exp;
  final String outcome;
  const _MockQ({required this.q, required this.opts, required this.ans,
      required this.exp, required this.outcome});
}


