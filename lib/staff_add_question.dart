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

  @override
  Widget build(BuildContext context) {
    final showBack = _questions.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Questions')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.quizTitle,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("Topic: ${widget.topic} • Duration: ${widget.duration} min"),
              const SizedBox(height: 12),

              TextFormField(
                controller: _q,
                decoration: const InputDecoration(labelText: "Question"),
                validator: (value) =>
                value == null || value.trim().isEmpty ? "Question cannot be empty" : null,
              ),

              TextFormField(controller: _a, decoration: const InputDecoration(labelText: "Option A")),
              TextFormField(controller: _b, decoration: const InputDecoration(labelText: "Option B")),
              TextFormField(controller: _c, decoration: const InputDecoration(labelText: "Option C")),
              TextFormField(controller: _d, decoration: const InputDecoration(labelText: "Option D")),

              if (_optionsMsg != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _optionsMsg!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                  ),
                ),

              const SizedBox(height: 8),

              DropdownButton<String>(
                value: _correct,
                items: const [
                  DropdownMenuItem(value: "A", child: Text("Correct: A")),
                  DropdownMenuItem(value: "B", child: Text("Correct: B")),
                  DropdownMenuItem(value: "C", child: Text("Correct: C")),
                  DropdownMenuItem(value: "D", child: Text("Correct: D")),
                ],
                onChanged: (v) => setState(() => _correct = v ?? "A"),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  if (showBack) ...[
                    OutlinedButton(
                      onPressed: _goBackToPreviousQuestion,
                      child: const Text("Back"),
                    ),
                    const SizedBox(width: 10),
                  ],
                  OutlinedButton(
                    onPressed: _addQuestion,
                    child: const Text("Add Question"),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _questions.isEmpty ? null : _publish,
                    child: const Text("Publish"),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Text("Added Questions: ${_questions.length}"),

              Expanded(
                child: ListView.builder(
                  itemCount: _questions.length,
                  itemBuilder: (_, i) => ListTile(
                    title: Text("Q${i + 1}: ${_questions[i]["q"]}"),
                    subtitle: Text("Correct: ${_questions[i]["correct"]}"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}