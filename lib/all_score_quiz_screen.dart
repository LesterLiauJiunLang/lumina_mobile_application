import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_score_chart.dart';

class AllScoreQuizScreen extends StatelessWidget {
  final String? studentId;

  const AllScoreQuizScreen({super.key, this.studentId});

  @override
  Widget build(BuildContext context) {
    final isStaff = studentId == null;
    final supabase = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(
        title: Text(isStaff ? "Staff: Check Result" : "My Results"),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: supabase
            .from('quizzes')
            .select()
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final quizzes = snapshot.data ?? [];

          if (quizzes.isEmpty) {
            return const Center(child: Text("No quizzes available."));
          }

          return ListView.builder(
            itemCount: quizzes.length,
            itemBuilder: (_, i) {
              final quiz = quizzes[i];

              final String quizId = quiz['id']; // ✅ FIXED
              final String title = quiz['title'] ?? "Untitled Quiz";

              return Card(
                margin:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(title),
                  subtitle: Text("ID: $quizId"),
                  trailing: const Icon(Icons.analytics_outlined),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentScoreChartScreen(
                          quizId: quizId, // ✅ FIXED
                          quizTitle: title,
                          studentId: studentId,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}