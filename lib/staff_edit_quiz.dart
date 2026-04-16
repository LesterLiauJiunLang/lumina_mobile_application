import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'staff_add_question.dart';

class StaffEditQuizScreen extends StatefulWidget {
  final String quizId; // ✅ FIXED
  final String quizTitle;

  const StaffEditQuizScreen({
    super.key,
    required this.quizId,
    required this.quizTitle,
  });

  @override
  State<StaffEditQuizScreen> createState() => _StaffEditQuizScreenState();
}

class _StaffEditQuizScreenState extends State<StaffEditQuizScreen> {
  late String _quizTitle;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _quizTitle = widget.quizTitle;
  }

  // ✏️ Edit Quiz Title
  Future<void> _editQuizTitle() async {
    final controller = TextEditingController(text: _quizTitle);

    final newTitle = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Quiz Title"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () =>
                  Navigator.pop(context, controller.text.trim()),
              child: const Text("Save")),
        ],
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty) {
      await supabase
          .from('quizzes')
          .update({'title': newTitle})
          .eq('id', widget.quizId); // ✅ FIXED

      setState(() => _quizTitle = newTitle);
    }
  }

  // ✏️ Edit Question
  Future<void> _editQuestionDialog(Map<String, dynamic> qRow) async {
    final qCtrl = TextEditingController(text: qRow['question']);
    final aCtrl = TextEditingController(text: qRow['option_a']);
    final bCtrl = TextEditingController(text: qRow['option_b']);
    final cCtrl = TextEditingController(text: qRow['option_c']);
    final dCtrl = TextEditingController(text: qRow['option_d']);

    int correctIndex =
        int.tryParse(qRow['correct_index']?.toString() ?? "0") ?? 0;

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Question"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: qCtrl),
              TextField(controller: aCtrl),
              TextField(controller: bCtrl),
              TextField(controller: cCtrl),
              TextField(controller: dCtrl),
              DropdownButtonFormField<int>(
                value: correctIndex,
                items: const [
                  DropdownMenuItem(value: 0, child: Text("A")),
                  DropdownMenuItem(value: 1, child: Text("B")),
                  DropdownMenuItem(value: 2, child: Text("C")),
                  DropdownMenuItem(value: 3, child: Text("D")),
                ],
                onChanged: (v) => correctIndex = v ?? 0,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Save")),
        ],
      ),
    );

    if (saved == true) {
      await supabase.from('questions').update({
        'question': qCtrl.text.trim(),
        'option_a': aCtrl.text.trim(),
        'option_b': bCtrl.text.trim(),
        'option_c': cCtrl.text.trim(),
        'option_d': dCtrl.text.trim(),
        'correct_index': correctIndex.toString(),
      }).eq('id', qRow['id']);

      setState(() {});
    }
  }

  Future<void> _deleteQuestion(dynamic id) async {
    await supabase.from('questions').delete().eq('id', id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_quizTitle),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _editQuizTitle),

          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StaffAddQuestionScreen(
                  quizId: widget.quizId, // ✅ FIXED
                  quizTitle: _quizTitle,
                  topic: "",
                  duration: "",
                ),
              ),
            ).then((_) => setState(() {})),
          ),
        ],
      ),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: supabase
            .from('questions')
            .select()
            .eq('quiz_id', widget.quizId) // ✅ FIXED
            .order('id'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final questions = snapshot.data ?? [];

          return ListView.builder(
            itemCount: questions.length,
            itemBuilder: (_, i) {
              final q = questions[i];

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(q['question'] ?? ""),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editQuestionDialog(q),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteQuestion(q['id']),
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