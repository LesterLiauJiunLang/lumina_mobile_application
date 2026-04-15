  import 'package:flutter/material.dart';
  import 'student_quiz_list.dart';
  import 'all_score_quiz_screen.dart';

  class StudentDashboardQuiz extends StatelessWidget {
    final String studentId = "S001";

    const StudentDashboardQuiz({super.key});

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: const Text("Student Dashboard")),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [

              /// Attempt Quiz Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentQuizListScreen(
                          studentId: studentId,
                        ),
                      ),
                    );
                  },
                  child: const Text("Attempt Quiz"),
                ),
              ),

              const SizedBox(height: 20),

              /// View Result Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AllScoreQuizScreen(studentId: studentId),
                      ),
                    );
                  },
                  child: const Text("View Result"),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
