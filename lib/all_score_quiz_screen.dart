import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_score_chart.dart';
//ss
class AllScoreQuizScreen extends StatelessWidget {
  final String? studentId;

  const AllScoreQuizScreen({super.key, this.studentId});

  @override
  Widget build(BuildContext context) {
    final isStaff = studentId == null;
    final supabase = Supabase.instance.client;

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
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                const SizedBox(width: 12),

                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.bar_chart,
                      color: Color(0xFF005A9C), size: 28),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    isStaff ? "Check Results" : "My Results",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ===== CONTENT =====
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: supabase
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
                      child: Text("Error: ${snapshot.error}"));
                }

                final quizzes = snapshot.data ?? [];

                if (quizzes.isEmpty) {
                  return const Center(
                      child: Text("No quizzes available."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: quizzes.length,
                  itemBuilder: (_, i) {
                    final quiz = quizzes[i];

                    final String quizId = quiz['id'];
                    final String title =
                        quiz['title'] ?? "Untitled Quiz";

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StudentScoreChartScreen(
                              quizId: quizId,
                              quizTitle: title,
                              studentId: studentId,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // 📊 Icon Box
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF005A9C)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.analytics_outlined,
                                color: Color(0xFF005A9C),
                              ),
                            ),

                            const SizedBox(width: 15),

                            // 📝 Quiz Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Quiz ID: $quizId",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ➡️ Arrow
                            const Icon(Icons.arrow_forward_ios_rounded,
                                size: 16, color: Colors.grey),
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