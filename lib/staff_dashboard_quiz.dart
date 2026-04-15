import 'package:flutter/material.dart';
import 'staff_create_quiz.dart';
import 'all_score_quiz_screen.dart';
import 'staff_view_all_quiz.dart';

class StaffDashboard extends StatelessWidget {
  const StaffDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Staff Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const StaffCreateQuizScreen()),
                  );
                },
                child: const Text("Create Quiz"),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const StaffViewAllQuizScreen()),
                  );
                },
                child: const Text("View All Quizzes"),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AllScoreQuizScreen()),
                  );
                },
                child: const Text("Check Results"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
