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
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () =>
                      setState(() => _refreshKey = UniqueKey()),
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

                if (rows.isEmpty) {
                  return const Center(
                    child: Text(
                      'No quizzes available.',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async =>
                      setState(() => _refreshKey = UniqueKey()),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: rows.length,
                    itemBuilder: (context, i) {
                      final quiz = rows[i];

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
                              // 🎯 Icon
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

                              // 📄 Info
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