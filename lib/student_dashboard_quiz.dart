import 'package:flutter/material.dart';
import 'student_quiz_list.dart';
import 'all_score_quiz_screen.dart';
import 'model/student.dart';

class StudentDashboardQuiz extends StatelessWidget {
  const StudentDashboardQuiz({super.key});

  @override
  Widget build(BuildContext context) {
    final student = ModalRoute.of(context)!.settings.arguments as Student;
    final String studentId = student.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F9),

      body: Column(
        children: [
          /// ===== HEADER =====
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 65, 20, 30),
            decoration: const BoxDecoration(
              color: Color(0xFF005A9C),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Row(
              children: [
                /// BACK BUTTON
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                const SizedBox(width: 12),

                const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.quiz, color: Color(0xFF005A9C)),
                ),

                const SizedBox(width: 12),

                const Text(
                  "My Quizzes",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          /// ===== BODY =====
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [

                  /// ATTEMPT QUIZ CARD
                  _buildActionCard(
                    title: "Attempt Quiz",
                    subtitle: "Start answering quizzes",
                    icon: Icons.play_arrow_rounded,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentQuizListScreen(
                            studentId: studentId,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  /// VIEW RESULT CARD
                  _buildActionCard(
                    title: "View Results",
                    subtitle: "Check your scores",
                    icon: Icons.bar_chart_rounded,
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AllScoreQuizScreen(
                            studentId: studentId,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ===== BEAUTIFUL CARD =====
  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            /// ICON
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),

            const SizedBox(width: 15),

            /// TEXT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),

            /// ARROW
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}