import 'package:flutter/material.dart';
import 'student_score_chart.dart';

class StudentResultScreen extends StatelessWidget {
  final String quizId;
  final String quizTitle;
  final int score;
  final int total;
  final String studentId;

  final List<Map<String, dynamic>> questions;
  final List<int?> selectedAnswers;

  const StudentResultScreen({
    super.key,
    required this.quizId,
    required this.quizTitle,
    required this.score,
    required this.total,
    required this.studentId,
    required this.questions,
    required this.selectedAnswers,
  });

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0 : (score / total * 100).round();
    final bool isPass = percent >= 50;
    final Color mainColor = isPass ? Colors.green : Colors.red;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F9),
      body: Column(
        children: [
          // ===== HEADER =====
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
            decoration: const BoxDecoration(
              color: Color(0xFF005A9C),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(35),
                bottomRight: Radius.circular(35),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    "Quiz Result",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [

                // ===== SCORE CARD =====
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        quizTitle,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text("$score / $total",
                          style: const TextStyle(
                              fontSize: 36, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(
                        "$percent% ${isPass ? "PASS" : "FAIL"}",
                        style: TextStyle(
                          color: mainColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ===== BUTTON =====
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF005A9C),
                    padding: const EdgeInsets.all(14),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentScoreChartScreen(
                          quizId: quizId,
                          quizTitle: quizTitle,
                          studentId: studentId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.bar_chart),
                  label: const Text(
                    "View Score History",
                    style: TextStyle(color: Colors.white),
                  ),
                ),

                const SizedBox(height: 20),

                // ===== ANSWER REVIEW =====
                const Text(
                  "Answer Review",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                ...questions.asMap().entries.map((entry) {
                  final i = entry.key;
                  final q = entry.value;

                  final selected = selectedAnswers[i];
                  final correctIndex =
                      int.tryParse(q['correct_index'].toString()) ?? 0;

                  final isQuestionCorrect = selected == correctIndex;

                  final options = [
                    q['option_a'],
                    q['option_b'],
                    q['option_c'],
                    q['option_d'],
                  ];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ===== QUESTION TITLE =====
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Q${i + 1}: ${q['question']}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              isQuestionCorrect ? "Correct" : "Wrong",
                              style: TextStyle(
                                color: isQuestionCorrect
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // ===== OPTIONS =====
                        ...List.generate(options.length, (optIndex) {
                          final text = options[optIndex];
                          if (text == null || text.toString().isEmpty) {
                            return const SizedBox();
                          }

                          final isSelected = selected == optIndex;
                          final isCorrect = correctIndex == optIndex;

                          Color bgColor = Colors.transparent;
                          String label = "";

                          if (isCorrect) {
                            bgColor = Colors.green.withOpacity(0.15);
                            label = "Correct Answer";
                          }

                          if (isSelected && !isCorrect) {
                            bgColor = Colors.red.withOpacity(0.15);
                            label = "Your Answer";
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isCorrect
                                    ? Colors.green
                                    : (isSelected
                                    ? Colors.red
                                    : Colors.grey.shade300),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (isCorrect)
                                      const Icon(Icons.check_circle,
                                          color: Colors.green),
                                    if (isSelected && !isCorrect)
                                      const Icon(Icons.cancel,
                                          color: Colors.red),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(text)),
                                  ],
                                ),

                                if (label.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isCorrect
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),

                        // ===== SHOW CORRECT ANSWER TEXT =====
                        if (!isQuestionCorrect)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              "Correct answer: ${options[correctIndex]}",
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}