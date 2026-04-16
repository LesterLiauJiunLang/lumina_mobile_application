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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to create quiz (maybe duplicate ID)")),
      );
      print("ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Quiz (Staff)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ✅ NEW: Quiz ID input
              TextFormField(
                controller: _quizId,
                decoration: const InputDecoration(labelText: 'Quiz ID (e.g. AMMS1234)'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Quiz ID is required";
                  }
                  if (value.length < 5) {
                    return "ID too short";
                  }
                  return null;
                },
              ),

              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Quiz Title'),
                validator: (value) =>
                value == null || value.trim().isEmpty
                    ? "Title is required"
                    : null,
              ),

              TextFormField(
                controller: _topic,
                decoration: const InputDecoration(labelText: 'Topic'),
                validator: (value) =>
                value == null || value.trim().isEmpty
                    ? "Topic is required"
                    : null,
              ),

              TextFormField(
                controller: _duration,
                decoration:
                const InputDecoration(labelText: 'Duration (minutes)'),
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

              const SizedBox(height: 16),

              FilledButton(
                onPressed: _saveQuizAndGoAddQuestions,
                child: const Text('Save & Add Questions'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}