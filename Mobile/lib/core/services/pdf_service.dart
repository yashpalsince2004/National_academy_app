import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/dpp/data/models/dpp_model.dart';

class PdfService {
  static Future<void> exportDppToPdf(DppModel dpp) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Academy Logo / Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'NATIONAL ACADEMY',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.Text(
                        'Daily Practice Problem (DPP)',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'AI Smart DPP',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue700,
                        ),
                      ),
                      pw.Text(
                        'National Academy AI',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontStyle: pw.FontStyle.italic,
                          color: PdfColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // DPP Configuration summary card
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300, width: 1),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    dpp.title.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Subject: ${dpp.subjectName ?? "N/A"}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Class: ${dpp.classLevel}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Exam Target: ${dpp.examType}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Questions: ${dpp.configQuestions}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Max Marks: ${dpp.configTotalMarks}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Time: ${dpp.configTimeMinutes} Mins', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Difficulty: ${dpp.difficulty}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Negative Marking: -${dpp.configNegativeMarking}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Marks per Question: +${dpp.configMarksPerQuestion}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  if (dpp.chapterName != null && dpp.chapterName!.isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text('Chapter: ${dpp.chapterName}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                  if (dpp.topics.isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text('Topics: ${dpp.topics.join(", ")}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Instructions
            pw.Text(
              'GENERAL INSTRUCTIONS:',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '1. This DPP contains ${dpp.configQuestions} questions. Maximize your score within the allotted ${dpp.configTimeMinutes} minutes.\n'
              '2. Each correct response carries +${dpp.configMarksPerQuestion} marks. Incorrect responses carry a penalty of -${dpp.configNegativeMarking} marks.\n'
              '3. Use proper logic, mathematical methods, and derivations. Verify your answers with the solutions key at the end.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
            ),
            pw.SizedBox(height: 20),

            pw.Text(
              'QUESTIONS:',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.Divider(color: PdfColors.blue800, thickness: 1.5),
            pw.SizedBox(height: 10),

            ...dpp.questions.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final q = entry.value;
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 16),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Q$index. ',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            q.questionText,
                            style: const pw.TextStyle(fontSize: 11),
                          ),
                        ),
                        pw.Text(
                          '[+${q.marks} Marks]',
                          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700, fontStyle: pw.FontStyle.italic),
                        ),
                      ],
                    ),
                    if (q.options != null && q.options!.isNotEmpty) ...[
                      pw.SizedBox(height: 6),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 20),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: q.options!.asMap().entries.map((opt) {
                            final label = String.fromCharCode(65 + opt.key); // A, B, C, D
                            return pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(vertical: 2),
                              child: pw.Text(
                                '($label) ${opt.value}',
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),

            pw.NewPage(),

            // Answer Key & Solutions
            pw.Text(
              'ANSWER KEY & SOLUTIONS:',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.Divider(color: PdfColors.blue800, thickness: 1.5),
            pw.SizedBox(height: 10),

            ...dpp.questions.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final q = entry.value;
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Q$index Correct Option/Answer: ${q.correctAnswer}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.blue900),
                    ),
                    if (q.explanation != null && q.explanation!.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Detailed Solution: ${q.explanation}',
                        style: const pw.TextStyle(color: PdfColors.grey800, fontSize: 9),
                      ),
                    ],
                    if (q.learningOutcome != null && q.learningOutcome!.isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Learning Outcome: ${q.learningOutcome}',
                        style: pw.TextStyle(color: PdfColors.blueGrey800, fontSize: 8, fontStyle: pw.FontStyle.italic),
                      ),
                    ],
                    pw.SizedBox(height: 6),
                    pw.Divider(color: PdfColors.grey300, thickness: 0.5),
                  ],
                ),
              );
            }).toList(),
          ];
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.grey500),
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${dpp.title.replaceAll(" ", "_")}.pdf',
    );
  }
}
