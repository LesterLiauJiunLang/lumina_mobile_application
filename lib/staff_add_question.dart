import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StaffAddQuestionScreen extends StatefulWidget {
  final String quizId;   // ✅ changed
  final String quizTitle;
  final String topic;
  final String duration;

  const StaffAddQuestionScreen({
    super.key,
    required this.quizId,   // ✅ changed
    required this.quizTitle,
    required this.topic,
    required this.duration,
  });

  @override
  State<StaffAddQuestionScreen> createState() => _StaffAddQuestionScreenState();
}

class _StaffAddQuestionScreenState extends State<StaffAddQuestionScreen> {
  final _formKey = GlobalKey<FormState>();

  final _q = TextEditingController();
  final _a = TextEditingController();
  final _b = TextEditingController();
  final _c = TextEditingController();
  final _d = TextEditingController();

  String _correct = "A";
  String? _optionsMsg;

  final List<Map<String, String>> _questions = [];

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();

    void clearMsg() {
      if (_optionsMsg != null) setState(() => _optionsMsg = null);
    }

    _a.addListener(clearMsg);
    _b.addListener(clearMsg);
    _c.addListener(clearMsg);
    _d.addListener(clearMsg);
  }

  @override
  void dispose() {
    _q.dispose();
    _a.dispose();
    _b.dispose();
    _c.dispose();
    _d.dispose();
    super.dispose();
  }

  int _filledOptionsCount() {
    return [_a, _b, _c, _d]
        .map((c) => c.text.trim())
        .where((x) => x.isNotEmpty)
        .length;
  }

  bool _isCorrectOptionFilled() {
    switch (_correct) {
      case "A":
        return _a.text.trim().isNotEmpty;
      case "B":
        return _b.text.trim().isNotEmpty;
      case "C":
        return _c.text.trim().isNotEmpty;
      case "D":
        return _d.text.trim().isNotEmpty;
      default:
        return false;
    }
  }

  void _clearInputs() {
    _q.clear();
    _a.clear();
    _b.clear();
    _c.clear();
    _d.clear();
    _correct = "A";
    _optionsMsg = null;
  }

  void _addQuestion() {
    if (!_formKey.currentState!.validate()) return;

    if (_filledOptionsCount() < 2) {
      setState(() => _optionsMsg = "Please enter at least 2 options");
      return;
    }

    if (!_isCorrectOptionFilled()) {
      setState(() => _optionsMsg = "Correct option ($_correct) cannot be empty");
      return;
    }

    setState(() {
      _questions.add({
        "q": _q.text.trim(),
        "a": _a.text.trim(),
        "b": _b.text.trim(),
        "c": _c.text.trim(),
        "d": _d.text.trim(),
        "correct": _correct,
      });

      _clearInputs();
    });
  }

  void _goBackToPreviousQuestion() {
    if (_questions.isEmpty) return;

    setState(() {
      final last = _questions.removeLast();

      _q.text = last["q"] ?? "";
      _a.text = last["a"] ?? "";
      _b.text = last["b"] ?? "";
      _c.text = last["c"] ?? "";
      _d.text = last["d"] ?? "";
      _correct = last["correct"] ?? "A";
      _optionsMsg = null;
    });
  }

  Future<void> _publish() async {
    if (_questions.isEmpty) {
      setState(() => _optionsMsg = "Please add at least 1 question before publishing");
      return;
    }

    final hasTyping = _q.text.trim().isNotEmpty ||
        _a.text.trim().isNotEmpty ||
        _b.text.trim().isNotEmpty ||
        _c.text.trim().isNotEmpty ||
        _d.text.trim().isNotEmpty;

    if (hasTyping) {
      setState(() => _optionsMsg = "You have an unfinished question. Press 'Add Question' first.");
      return;
    }

    try {
      for (final q in _questions) {
        final correctIndex = switch (q["correct"]) {
          "A" => 0,
          "B" => 1,
          "C" => 2,
          "D" => 3,
          _ => 0,
        };

        await supabase.from('questions').insert({
          'quiz_id': widget.quizId, // ✅ FIXED
          'question': q["q"],
          'option_a': q["a"],
          'option_b': q["b"],
          'option_c': q["c"],
          'option_d': q["d"],
          'correct_index': correctIndex,
        });
      }

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Quiz Published"),
          content: Text("Saved ${_questions.length} question(s) successfully."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
              child: const Text("OK"),
            )
          ],
        ),
      );

    } catch (e) {
      setState(() => _optionsMsg = "Failed to publish. Try again.");
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
    final showBack = _questions.isNotEmpty;

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
                  child: Icon(Icons.help_outline,
                      size: 30, color: Color(0xFF005A9C)),
                ),

                const SizedBox(width: 15),

                const Expanded(
                  child: Text(
                    "Add Questions",
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

          // ===== CONTENT =====
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ===== QUIZ INFO CARD =====
                Container(
                  padding: const EdgeInsets.all(15),
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.quizTitle,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text("Topic: ${widget.topic}"),
                      Text("Duration: ${widget.duration} min"),
                    ],
                  ),
                ),

                // ===== FORM CARD =====
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
                        TextFormField(
                          controller: _q,
                          decoration: _inputDecoration("Question"),
                          validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? "Question cannot be empty"
                              : null,
                        ),

                        const SizedBox(height: 15),

                        TextFormField(controller: _a, decoration: _inputDecoration("Option A")),
                        const SizedBox(height: 10),
                        TextFormField(controller: _b, decoration: _inputDecoration("Option B")),
                        const SizedBox(height: 10),
                        TextFormField(controller: _c, decoration: _inputDecoration("Option C")),
                        const SizedBox(height: 10),
                        TextFormField(controller: _d, decoration: _inputDecoration("Option D")),

                        if (_optionsMsg != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _optionsMsg!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12),
                            ),
                          ),

                        const SizedBox(height: 10),

                        DropdownButtonFormField<String>(
                          value: _correct,
                          decoration: _inputDecoration("Correct Answer"),
                          items: const [
                            DropdownMenuItem(value: "A", child: Text("A")),
                            DropdownMenuItem(value: "B", child: Text("B")),
                            DropdownMenuItem(value: "C", child: Text("C")),
                            DropdownMenuItem(value: "D", child: Text("D")),
                          ],
                          onChanged: (v) => setState(() => _correct = v ?? "A"),
                        ),

                        const SizedBox(height: 20),

                        // ===== BUTTONS =====
                        Row(
                          children: [
                            if (showBack) ...[
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _goBackToPreviousQuestion,
                                  child: const Text("Back"),
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _addQuestion,
                                child: const Text("Add"),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF005A9C),
                                ),
                                onPressed:
                                _questions.isEmpty ? null : _publish,
                                child: const Text("Publish",
                                  style: TextStyle(
                                      color: Colors.white,
                                  ),
                                )
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // ===== QUESTION LIST =====
                Text(
                  "Added Questions (${_questions.length})",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),

                const SizedBox(height: 10),

                ..._questions.asMap().entries.map((entry) {
                  final i = entry.key;
                  final q = entry.value;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text("Q${i + 1}: ${q["q"]}"),
                      subtitle: Text("Correct: ${q["correct"]}"),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}