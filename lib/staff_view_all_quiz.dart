import 'quiz_qr_generator.dart';
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

class _StaffViewAllQuizScreenState
    extends State<StaffViewAllQuizScreen> {

  final supabase = Supabase.instance.client;

  Key _refreshKey = UniqueKey();
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";

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
                ? const Color(0xFF2E7D32)
                : const Color(0xFFC62828),
            borderRadius: BorderRadius.circular(12),
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
        await SupabaseService.deleteQuiz(quizId);

        if (!mounted) return;

        setState(() {
          _refreshKey = UniqueKey();
        });

        _showStatusSnackbar("Deleted", "Quiz removed successfully", true);
      } catch (e) {
        _showStatusSnackbar("Error", "Failed to delete quiz", false);
      }
    }
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
            padding: const EdgeInsets.fromLTRB(20, 65, 20, 25),
            decoration: const BoxDecoration(
              color: Color(0xFF005A9C),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              children: [
                Row(
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

                    const SizedBox(width: 12),

                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.list_alt,
                          size: 30, color: Color(0xFF005A9C)),
                    ),

                    const SizedBox(width: 15),

                    const Expanded(
                      child: Text(
                        "All Quizzes",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // 🔄 Refresh
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _refreshKey = UniqueKey();
                          _searchController.clear();
                          searchQuery = "";
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // 🔍 SEARCH BAR
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: "Search quiz title...",
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding:
                      EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ===== LIST =====
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              key: _refreshKey,
              future: supabase
                  .from('quizzes')
                  .select()
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final quizzes = snapshot.data ?? [];

                // 🔍 FILTER
                final filtered = quizzes.where((quiz) {
                  final title =
                  (quiz['title'] ?? "").toString().toLowerCase();
                  return title.contains(searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text("No matching quizzes found."),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _refreshKey = UniqueKey();
                      _searchController.clear();
                      searchQuery = "";
                    });
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final quiz = filtered[i];

                      final String quizId = quiz['id'];
                      final String title =
                          quiz['title'] ?? "Untitled";

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
                          title: Text(title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text("ID: $quizId"),

                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.qr_code,
                                    color: Colors.green),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          QuizQRGeneratorScreen(
                                            quizId: quizId,
                                            quizTitle: title,
                                          ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.blue),
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          StaffEditQuizScreen(
                                            quizId: quizId,
                                            quizTitle: title,
                                          ),
                                    ),
                                  );
                                  setState(() {});
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () =>
                                    _deleteQuiz(quizId),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}