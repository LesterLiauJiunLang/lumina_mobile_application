import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'staff_create_quiz.dart';
import 'all_score_quiz_screen.dart';
import 'staff_view_all_quiz.dart';

class StaffDashboardQuiz extends StatefulWidget {
  const StaffDashboardQuiz({super.key});

  @override
  State<StaffDashboardQuiz> createState() => _StaffDashboardQuizState();
}

class _StaffDashboardQuizState extends State<StaffDashboardQuiz> {
  final supabase = Supabase.instance.client;

  // ================= FETCH STATS =================
  Future<Map<String, dynamic>> _fetchStats() async {
    final quizzes = await supabase.from('quizzes').select();
    final attempts = await supabase.from('attempts').select();

    double avg = 0;

    if (attempts.isNotEmpty) {
      avg = attempts
          .map((e) => (e['score'] / e['total']) * 100)
          .reduce((a, b) => a + b) /
          attempts.length;
    }

    return {
      "quizzes": quizzes.length,
      "attempts": attempts.length,
      "avg": avg.toStringAsFixed(1),
    };
  }

  // ================= MENU CARD =================
  Widget _menuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = const Color(0xFF005A9C),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(18),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ================= STAT CARD =================
  Widget _statCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF005A9C)),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            Text(title,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader(BuildContext context) {
    return Container(
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
            child: Icon(Icons.quiz,
                color: Color(0xFF005A9C), size: 28),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Text(
              "Quiz Management",
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 🔄 REFRESH BUTTON (NEW)
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================= BODY =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F9),

      body: Column(
        children: [
          _buildHeader(context),

          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _fetchStats(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final data = snapshot.data!;

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // ===== STATS =====
                    const Text(
                      "Overview",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        _statCard("Quizzes",
                            data['quizzes'].toString(), Icons.quiz),
                        const SizedBox(width: 10),
                        _statCard("Attempts",
                            data['attempts'].toString(), Icons.people),
                        const SizedBox(width: 10),
                        _statCard("Avg Score",
                            "${data['avg']}%", Icons.bar_chart),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // ===== MENU =====
                    const Text(
                      "Quick Actions",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 12),

                    _menuCard(
                      icon: Icons.add_task,
                      title: "Create Quiz",
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StaffCreateQuizScreen(),
                          ),
                        );

                        if (result == true) {
                          setState(() {}); 
                        }
                      },
                      color: Colors.blue,
                    ),

                    _menuCard(
                      icon: Icons.list_alt,
                      title: "View All Quizzes",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                              const StaffViewAllQuizScreen()),
                        );
                      },
                      color: Colors.orange,
                    ),

                    _menuCard(
                      icon: Icons.bar_chart,
                      title: "Check Results",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                              const AllScoreQuizScreen()),
                        );
                      },
                      color: Colors.purple,
                    ),

                    // 🔥 FUTURE EXTENSIONS
                    _menuCard(
                      icon: Icons.analytics,
                      title: "Analytics Dashboard (Coming Soon)",
                      onTap: () {},
                      color: Colors.teal,
                    ),

                    _menuCard(
                      icon: Icons.download,
                      title: "Export Results CSV (Coming Soon)",
                      onTap: () {},
                      color: Colors.green,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}