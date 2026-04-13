import 'package:flutter/material.dart';
import 'db/supabase_service.dart';
import 'student_attempt_quiz.dart';

class StudentQuizListScreen extends StatefulWidget {
  final String studentId;

  const StudentQuizListScreen({
    super.key,
    required this.studentId,
  });

  @override
  State<StudentQuizListScreen> createState() => _StudentQuizListScreenState();
}

class _StudentQuizListScreenState extends State<StudentQuizListScreen> {
  Key _refreshKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Quizzes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _refreshKey = UniqueKey()),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        key: _refreshKey,
        future: SupabaseService.client
            .from('quizzes')
            .select()
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final rows = snapshot.data ?? [];
          if (rows.isEmpty) {
            return const Center(
                child: Text('No quizzes available at the moment.'));
          }

          return RefreshIndicator(
            onRefresh: () async =>
                setState(() => _refreshKey = UniqueKey()),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: rows.length,
              itemBuilder: (context, i) {
                final quiz = rows[i];

                final String quizId = quiz['id'] ?? ""; // ✅ changed
                final String title = quiz['title'] ?? "Untitled Quiz";
                final String topic = quiz['topic'] ?? "General";
                final int duration = quiz['duration'] ?? 0;

                return Card(
                  elevation: 2,
                  margin:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Topic: $topic'),
                        Text('Duration: $duration mins • ID: $quizId'), // ✅ changed
                      ],
                    ),
                    trailing: const Icon(Icons.play_arrow_rounded,
                        color: Colors.blue, size: 30),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentAttemptQuizScreen(
                            quizId: quizId, // ✅ changed
                            quizTitle: title,
                            studentId: widget.studentId,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}