import 'package:flutter/material.dart';
import 'db/supabase_service.dart';
import 'student_attempt_quiz.dart';

class StudentQuizListScreen extends StatefulWidget {
  final String studentId;

  const StudentQuizListScreen({
    super.key,
    required this.studentId,
  });

  @override
  State<StudentQuizListScreen> createState() => _StudentQuizListScreenState();
}

class _StudentQuizListScreenState extends State<StudentQuizListScreen> {
  Key _refreshKey = UniqueKey();

  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";

  void _showEnterQuizDialog() {
    final TextEditingController idController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Enter Quiz ID"),
        content: TextField(
          controller: idController,
          decoration: const InputDecoration(
            hintText: "Enter quiz ID",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final enteredId = idController.text.trim();

              if (enteredId.isEmpty) return;

              try {
                // 🔥 Check if quiz exists
                final quiz = await SupabaseService.client
                    .from('quizzes')
                    .select()
                    .eq('id', enteredId)
                    .maybeSingle();

                if (quiz == null) {
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
                          color: const Color(0xFFC62828), // ❌ red
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
                          children: const [
                            Icon(Icons.error_outline, color: Colors.white, size: 28),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Quiz Not Found",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "Please check the Quiz ID and try again.",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );

                  return;
                }

                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentAttemptQuizScreen(
                      quizId: enteredId,
                      quizTitle: quiz['title'] ?? "Quiz",
                      studentId: widget.studentId,
                    ),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Invalid Quiz ID")),
                );
              }
            },
            child: const Text("Enter"),
          ),
        ],
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
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            decoration: const BoxDecoration(
              color: Color(0xFF005A9C),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(35),
                bottomRight: Radius.circular(35),
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

                    const SizedBox(width: 10),

                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.quiz, color: Color(0xFF005A9C)),
                    ),

                    const SizedBox(width: 12),

                    const Expanded(
                      child: Text(
                        "Available Quizzes",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.login, color: Colors.white),
                      tooltip: "Enter Quiz ID",
                      onPressed: () => _showEnterQuizDialog(),
                    ),
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

          // ===== QUIZ LIST =====
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              key: _refreshKey,
              future: SupabaseService.client
                  .from('quizzes')
                  .select()
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}'));
                }

                final rows = snapshot.data ?? [];

                // 🔥 FILTER LOGIC
                final filtered = rows.where((quiz) {
                  final title =
                  (quiz['title'] ?? "").toString().toLowerCase();
                  return title.contains(searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'No matching quizzes found.',
                      style: TextStyle(fontSize: 16),
                    ),
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
                    itemBuilder: (context, i) {
                      final quiz = filtered[i];

                      final String quizId = quiz['id'] ?? "";
                      final String title =
                          quiz['title'] ?? "Untitled Quiz";
                      final String topic =
                          quiz['topic'] ?? "General";
                      final int duration =
                          quiz['duration'] ?? 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color:
                              Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    StudentAttemptQuizScreen(
                                      quizId: quizId,
                                      quizTitle: title,
                                      studentId:
                                      widget.studentId,
                                    ),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF005A9C)
                                      .withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Color(0xFF005A9C),
                                  size: 28,
                                ),
                              ),

                              const SizedBox(width: 15),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontWeight:
                                        FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 5),

                                    Row(
                                      children: [
                                        const Icon(Icons.category,
                                            size: 14,
                                            color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(topic,
                                            style:
                                            const TextStyle(
                                                color: Colors
                                                    .grey)),
                                      ],
                                    ),

                                    const SizedBox(height: 4),

                                    Row(
                                      children: [
                                        const Icon(Icons.timer,
                                            size: 14,
                                            color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                            "$duration mins",
                                            style:
                                            const TextStyle(
                                                color: Colors
                                                    .grey)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const Icon(Icons.arrow_forward_ios,
                                  size: 16, color: Colors.grey),
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