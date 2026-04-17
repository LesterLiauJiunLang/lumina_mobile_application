import 'package:flutter/material.dart';
import 'db/supabase_service.dart';
import 'student_result.dart';

class StudentAttemptQuizScreen extends StatefulWidget {
  final String quizId;      // ✅ changed
  final String quizTitle;
  final String studentId;

  const StudentAttemptQuizScreen({
    super.key,
    required this.quizId,   // ✅ changed
    required this.quizTitle,
    required this.studentId,
  });

  @override
  State<StudentAttemptQuizScreen> createState() => _StudentAttemptQuizScreenState();
}

class _StudentAttemptQuizScreenState extends State<StudentAttemptQuizScreen> {
  int index = 0;
  int? selectedOriginalIndex;
  int score = 0;
  bool isLoading = true;
  List<Map<String, dynamic>> questions = [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final rows = await SupabaseService.getQuestions(widget.quizId); // ✅ changed
      setState(() {
        questions = rows;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load questions")),
      );
    }
  }

  Future<void> _nextOrSubmit() async {
    final q = questions[index];
    final correctIndex =
        int.tryParse(q['correct_index']?.toString() ?? "0") ?? 0;

    if (selectedOriginalIndex == correctIndex) score++;

    if (index < questions.length - 1) {
      setState(() {
        index++;
        selectedOriginalIndex = null;
      });
    } else {
      setState(() => isLoading = true);
      try {
        await SupabaseService.saveAttempt(
          quizId: widget.quizId, // ✅ changed
          studentId: widget.studentId,
          score: score,
          total: questions.length,
        );
      } catch (e) {
        debugPrint("Save failed, but proceeding to results.");
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StudentResultScreen(
            quizId: widget.quizId, // ✅ changed
            quizTitle: widget.quizTitle,
            score: score,
            total: questions.length,
            studentId: widget.studentId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Attempt: ${widget.quizTitle}")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text("Attempt: ${widget.quizTitle}")),
        body: const Center(child: Text("No questions found for this quiz.")),
      );
    }

    final q = questions[index];
    final questionText = (q['question'] as String?) ?? "";

    final allOptions = <Map<String, Object?>>[
      {"label": "A", "text": (q['option_a'] as String?)?.trim() ?? "", "idx": 0},
      {"label": "B", "text": (q['option_b'] as String?)?.trim() ?? "", "idx": 1},
      {"label": "C", "text": (q['option_c'] as String?)?.trim() ?? "", "idx": 2},
      {"label": "D", "text": (q['option_d'] as String?)?.trim() ?? "", "idx": 3},
    ];

    final displayOptions =
    allOptions.where((o) => (o["text"] as String).isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(title: Text("Attempt: ${widget.quizTitle}")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Question ${index + 1}/${questions.length}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(questionText, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),

            for (final opt in displayOptions)
              RadioListTile<int>(
                value: opt["idx"] as int,
                groupValue: selectedOriginalIndex,
                title: Text(" ${opt["text"]}"),
                onChanged: (v) => setState(() => selectedOriginalIndex = v),
              ),

            const Spacer(),
            FilledButton(
              onPressed:
              selectedOriginalIndex == null ? null : _nextOrSubmit,
              child: Text(index == questions.length - 1 ? "Submit" : "Next"),
            ),
          ],
        ),
      ),
    );
  }
}