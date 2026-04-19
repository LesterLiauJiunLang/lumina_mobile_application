import 'package:flutter/material.dart';
import 'db/supabase_service.dart';
import 'student_result.dart';
import 'dart:async';

class StudentAttemptQuizScreen extends StatefulWidget {
  final String quizId;
  final String quizTitle;
  final String studentId;

  const StudentAttemptQuizScreen({
    super.key,
    required this.quizId,
    required this.quizTitle,
    required this.studentId,
  });

  @override
  State<StudentAttemptQuizScreen> createState() =>
      _StudentAttemptQuizScreenState();
}

class _StudentAttemptQuizScreenState extends State<StudentAttemptQuizScreen> {
  int index = 0;
  int score = 0;
  bool isLoading = true;

  List<Map<String, dynamic>> questions = [];
  List<int?> selectedAnswers = [];

  Timer? _timer;
  int remainingSeconds = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ================= SNACKBAR =================
  void _showStatusSnackbar(String title, String message, bool isSuccess) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
            isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "$title\n$message",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= EXIT DIALOG =================
  Future<bool> _showExitDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Exit Quiz"),
        content: const Text("Are you sure you want to exit the quiz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Exit"),
          ),
        ],
      ),
    ) ??
        false;
  }

  Future<void> _autoSubmitDueToTime() async {
    _showStatusSnackbar("Time is over", "Quiz will be submitted automatically", false);

    int finalScore = 0;

    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final correctIndex =
          int.tryParse(q['correct_index']?.toString() ?? "0") ?? 0;

      if (selectedAnswers[i] == correctIndex) {
        finalScore++;
      }
    }

    await SupabaseService.saveAttempt(
      quizId: widget.quizId,
      studentId: widget.studentId,
      score: finalScore,
      total: questions.length,
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => StudentResultScreen(
          quizId: widget.quizId,
          quizTitle: widget.quizTitle,
          score: finalScore,
          total: questions.length,
          studentId: widget.studentId,
          questions: questions,
          selectedAnswers: selectedAnswers,
        ),
      ),
    );
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (remainingSeconds <= 0) {
        timer.cancel();
        await _autoSubmitDueToTime();
      } else {
        setState(() {
          remainingSeconds--;
        });
      }
    });
  }

  // ================= LOAD QUESTIONS =================
  Future<void> _loadQuestions() async {
    try {
      final rows = await SupabaseService.getQuestions(widget.quizId);

      // 🔥 fetch quiz duration from first question or pass separately
      final quizData = await SupabaseService.client
          .from('quizzes')
          .select('duration')
          .eq('id', widget.quizId)
          .single();

      final durationMinutes = quizData['duration'] ?? 0;

      setState(() {
        questions = rows;
        selectedAnswers = List<int?>.filled(rows.length, null);
        isLoading = false;

        remainingSeconds = durationMinutes * 60; // convert to seconds
      });

      _startTimer();
    } catch (e) {
      setState(() => isLoading = false);
      _showStatusSnackbar("Error", "Failed to load questions", false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  // ================= NEXT / SUBMIT =================
  Future<void> _nextOrSubmit() async {
    if (selectedAnswers[index] == null) {
      _showStatusSnackbar("Warning", "Please select an answer", false);
      return;
    }

    if (index < questions.length - 1) {
      setState(() {
        index++;
      });
    } else {
      // ✅ CALCULATE SCORE ONLY ON SUBMIT
      int finalScore = 0;

      for (int i = 0; i < questions.length; i++) {
        final q = questions[i];
        final correctIndex =
            int.tryParse(q['correct_index']?.toString() ?? "0") ?? 0;

        if (selectedAnswers[i] == correctIndex) {
          finalScore++;
        }
      }

      await SupabaseService.saveAttempt(
        quizId: widget.quizId,
        studentId: widget.studentId,
        score: finalScore,
        total: questions.length,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StudentResultScreen(
            quizId: widget.quizId,
            quizTitle: widget.quizTitle,
            score: finalScore,
            total: questions.length,
            studentId: widget.studentId,
            questions: questions,
            selectedAnswers: selectedAnswers,
          ),
        ),
      );
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
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
                  onPressed: () async {
                    final exit = await _showExitDialog();
                    if (exit && mounted) {
                      Navigator.pop(context);
                    }
                  },
                ),

                Expanded(
                  child: Text(
                    widget.quizTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis, // ✅ avoid overflow
                  ),
                ),

                Text(
                  "${(remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(remainingSeconds % 60).toString().padLeft(2, '0')}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // ===== BODY =====
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : questions.isEmpty
                ? const Center(
              child: Text("No questions available."),
            )
                : _buildQuestionUI(),
          ),
        ],
      ),
    );
  }

  // ================= QUESTION UI =================
  Widget _buildQuestionUI() {
    final q = questions[index];

    final options = [
      {"text": q['option_a'], "idx": 0},
      {"text": q['option_b'], "idx": 1},
      {"text": q['option_c'], "idx": 2},
      {"text": q['option_d'], "idx": 3},
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: (index + 1) / questions.length,
            color: const Color(0xFF005A9C),
          ),

          const SizedBox(height: 20),

          // QUESTION BOX
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: SingleChildScrollView(
              child: Text(
                "Q${index + 1}: ${q['question']}",
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // OPTIONS
          ...options.map((opt) {
            final text = (opt["text"] ?? "").toString();
            if (text.isEmpty) return const SizedBox();

            final idx = opt["idx"] as int;
            final isSelected = selectedAnswers[index] == idx;

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedAnswers[index] = idx;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF005A9C).withOpacity(0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF005A9C)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: const Color(0xFF005A9C),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(text)),
                  ],
                ),
              ),
            );
          }),

          const Spacer(),

          // BUTTONS
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: index == 0
                      ? null
                      : () {
                    setState(() {
                      index--;
                    });
                  },
                  child: const Text("Back"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _nextOrSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005A9C),
                  ),
                  child: Text(
                    index == questions.length - 1 ? "Submit" : "Next",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}