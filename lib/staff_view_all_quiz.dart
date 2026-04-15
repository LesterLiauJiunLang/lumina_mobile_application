import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'staff_edit_quiz.dart';
import 'db/supabase_service.dart';

class StaffViewAllQuizScreen extends StatefulWidget {
  const StaffViewAllQuizScreen({super.key});

  @override
  State<StaffViewAllQuizScreen> createState() =>
      _StaffViewAllQuizScreenState();
}

class _StaffViewAllQuizScreenState extends State<StaffViewAllQuizScreen> {
  final supabase = Supabase.instance.client;

  Future<void> _deleteQuiz(String quizId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Quiz"),
        content: const Text(
            "This will delete the quiz and all its questions. Proceed?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete")),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await SupabaseService.deleteQuiz(quizId); // ✅ FIXED

        if (!mounted) return;

        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Quiz deleted successfully")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete quiz")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Quizzes")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: supabase
            .from('quizzes')
            .select()
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final quizzes = snapshot.data ?? [];

          if (quizzes.isEmpty) {
            return const Center(child: Text("No quizzes found."));
          }

          return ListView.builder(
            itemCount: quizzes.length,
            itemBuilder: (_, i) {
              final quiz = quizzes[i];

              final String quizId = quiz['id']; // ✅ FIXED
              final String title = quiz['title'] ?? "Untitled";

              return Card(
                margin:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(title),
                  subtitle: Text("ID: $quizId"),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon:
                        const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StaffEditQuizScreen(
                                quizId: quizId, // ✅ FIXED
                                quizTitle: title,
                              ),
                            ),
                          );
                          setState(() {});
                        },
                      ),

                      IconButton(
                        icon:
                        const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteQuiz(quizId), // ✅ FIXED
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}