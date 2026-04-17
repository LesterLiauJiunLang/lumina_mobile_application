import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'staff_add_question.dart';

class StaffCreateQuizScreen extends StatefulWidget {
  const StaffCreateQuizScreen({super.key});

  @override
  State<StaffCreateQuizScreen> createState() => _StaffCreateQuizScreenState();
}

class _StaffCreateQuizScreenState extends State<StaffCreateQuizScreen> {
  final _formKey = GlobalKey<FormState>();

  final _quizId = TextEditingController(); // ✅ NEW
  final _title = TextEditingController();
  final _topic = TextEditingController();
  final _duration = TextEditingController();

  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    _quizId.dispose(); // ✅ NEW
    _title.dispose();
    _topic.dispose();
    _duration.dispose();
    super.dispose();
  }

  void _showStatusSnackbar(String title, String message, bool isSuccess) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSuccess
                ? const Color(0xFF2E7D32) // green
                : const Color(0xFFC62828), // red
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error_outline,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveQuizAndGoAddQuestions() async {
    if (!_formKey.currentState!.validate()) return;

    final quizId = _quizId.text.trim(); // ✅ manual input
    final title = _title.text.trim();
    final topic = _topic.text.trim();
    final duration = int.parse(_duration.text.trim());

    try {
      await supabase.from('quizzes').insert({
        'id': quizId, // ✅ manual ID
        'title': title,
        'topic': topic,
        'duration': duration,
      });

      if (!mounted) return;

      final published = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => StaffAddQuestionScreen(
            quizId: quizId,
            quizTitle: title,
            topic: topic,
            duration: duration.toString(),
          ),
        ),
      );

      if (published == true && mounted) {
        Navigator.pop(context, true);
      }

    } catch (e) {
      _showStatusSnackbar(
        "Creation Failed",
        "Quiz ID might already exist.",
        false,
      );
      print("ERROR: $e");
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF5F7FA),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F9),
      body: Column(
        children: [
          // ===== HEADER =====
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
                // 🔙 Back Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),

                const SizedBox(width: 12),

                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.add_task,
                      size: 30, color: Color(0xFF005A9C)),
                ),

                const SizedBox(width: 15),

                const Expanded(
                  child: Text(
                    "Create Quiz",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ===== FORM =====
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
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

                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Quiz ID
                        TextFormField(
                          controller: _quizId,
                          decoration: _inputDecoration("Quiz ID"),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Quiz ID is required";
                            }
                            if (value.length < 5) return "ID too short";
                            return null;
                          },
                        ),

                        const SizedBox(height: 15),

                        TextFormField(
                          controller: _title,
                          decoration: _inputDecoration("Quiz Title"),
                          validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? "Title is required"
                              : null,
                        ),

                        const SizedBox(height: 15),

                        TextFormField(
                          controller: _topic,
                          decoration: _inputDecoration("Topic"),
                          validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? "Topic is required"
                              : null,
                        ),

                        const SizedBox(height: 15),

                        TextFormField(
                          controller: _duration,
                          decoration:
                          _inputDecoration("Duration (minutes)"),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Duration is required";
                            }
                            final number = int.tryParse(value.trim());
                            if (number == null) return "Must be a number";
                            if (number <= 0) return "Must be > 0";
                            return null;
                          },
                        ),

                        const SizedBox(height: 25),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF005A9C),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: _saveQuizAndGoAddQuestions,
                            child: const Text(
                              'Save & Add Questions',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}