import 'package:flutter/material.dart';
import 'student_score_chart.dart';
//s
class StudentResultScreen extends StatelessWidget {
  // ✅ quizId is now quizCode (String) to match Supabase schema
  final String quizId;
  final String quizTitle;
  final int score;
  final int total;
  final String studentId;

  const StudentResultScreen({
    super.key,
    required this.quizId,
    required this.quizTitle,
    required this.score,
    required this.total,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0 : (score / total * 100).round();

    // Choose color based on performance
    Color resultColor = percent >= 50 ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Quiz Result"),
        // Prevent going back to the quiz questions after finishing
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events_outlined, size: 80, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                quizTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              const Text("Your Score", style: TextStyle(fontSize: 16, color: Colors.grey)),
              Text(
                "$score / $total",
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: resultColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "$percent%",
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: resultColor
                  ),
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentScoreChartScreen(
                        quizId: quizId,
                        quizTitle: quizTitle,
                        studentId: studentId,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.bar_chart),
                  label: const Text("View Score History"),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Back to Dashboard"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}