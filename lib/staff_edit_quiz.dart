import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'db/supabase_service.dart';
import 'staff_add_question.dart';

class StaffEditQuizScreen extends StatefulWidget {
  final String quizId;
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

  Future<Map<String, dynamic>?> _getQuizDetails() async {
    final res = await supabase
        .from('quizzes')
        .select()
        .eq('id', widget.quizId)
        .maybeSingle();

    return res;
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF5F7FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
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

      _showStatusSnackbar("Updated", "Quiz title updated", true);
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
              TextField(
                controller: qCtrl,
                decoration: _inputDecoration("Quiz Title"),
              ),
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

      _showStatusSnackbar("Updated", "Question updated", true);
    }
  }

  Future<void> _deleteQuestion(dynamic id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Question"),
        content: const Text("Are you sure?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await supabase.from('questions').delete().eq('id', id); // ✅ use id
      _showStatusSnackbar("Deleted", "Question removed", true);
      setState(() {});
    }
  }

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
            color: isSuccess
                ? const Color(0xFF2E7D32)
                : const Color(0xFFC62828),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 10)
            ],
          ),
          child: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error_outline,
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
                // 🔙 Back
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                const SizedBox(width: 10),

                const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.edit, color: Color(0xFF005A9C)),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    _quizTitle,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ),

                // ✏️ Edit title
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: _editQuizTitle,
                ),

                // ➕ Add question
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () async {
                    final quiz = await SupabaseService.getQuizById(widget.quizId);

                    if (quiz == null) {
                      _showStatusSnackbar("Error", "Quiz not found", false);
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StaffAddQuestionScreen(
                          quizId: widget.quizId,
                          quizTitle: _quizTitle,
                          topic: quiz['topic'] ?? "",
                          duration: (quiz['duration'] ?? "").toString(),
                        ),
                      ),
                    ).then((_) => setState(() {}));
                  },
                ),
              ],
            ),
          ),

          // ===== QUESTION LIST =====
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: supabase
                  .from('questions')
                  .select()
                  .eq('quiz_id', widget.quizId)
                  .order('id'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final questions = snapshot.data ?? [];

                if (questions.isEmpty) {
                  return const Center(child: Text("No questions yet."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: questions.length,
                  itemBuilder: (_, i) {
                    final q = questions[i];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          "Q${i + 1}: ${q['question']}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // EDIT
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.blue),
                                onPressed: () =>
                                    _editQuestionDialog(q),
                              ),
                            ),

                            const SizedBox(width: 6),

                            // DELETE
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () => _deleteQuestion(q['id']),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}