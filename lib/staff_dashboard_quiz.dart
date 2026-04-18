import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
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

  // ================= EXPORT CSV =================
  Future<void> _exportResultsCSV() async {
    try {
      final data = await supabase.from('attempts').select();

      if (data.isEmpty) {
        if (!mounted) return;
        _showStatusSnackbar("No Data", "No quiz results found", false);
        return;
      }

      List<List<dynamic>> rows = [];

      rows.add([
        "Student ID",
        "Quiz ID",
        "Score",
        "Total",
        "Percentage",
        "Attempt Date"
      ]);

      for (var item in data) {
        final score = item['score'] ?? 0;
        final total = item['total'] ?? 1;
        final percent = (score / total) * 100;

        rows.add([
          item['student_id'] ?? '',
          item['quiz_id'] ?? '',
          score,
          total,
          percent.toStringAsFixed(1),
          item['created_at'] ?? '',
        ]);
      }

      String csvData = const ListToCsvConverter().convert(rows);

      final directory = await getApplicationDocumentsDirectory();
      final filePath = "${directory.path}/quiz_results.csv";

      final file = File(filePath);
      await file.writeAsString(csvData);

      if (!mounted) return;

      _showStatusSnackbar(
        "Export Successful",
        "CSV saved successfully",
        true,
      );

      // DEBUG (optional)
      print("CSV PATH: $filePath");

    } catch (e) {
      if (!mounted) return;

      _showStatusSnackbar(
        "Export Failed",
        e.toString(),
        false,
      );
    }
  }

  // ================= SNACKBAR =================
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
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error_outline,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                    Text(message,
                        style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
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
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
    );
  }

  // ================= UI =================
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
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!;

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                      "Overview",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        _statCard("Quizzes", data['quizzes'].toString(),
                            Icons.quiz),
                        const SizedBox(width: 10),
                        _statCard("Attempts", data['attempts'].toString(),
                            Icons.people),
                        const SizedBox(width: 10),
                        _statCard(
                            "Avg Score", "${data['avg']}%", Icons.bar_chart),
                      ],
                    ),

                    const SizedBox(height: 25),

                    const Text(
                      "Quick Actions",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                              builder: (_) => const AllScoreQuizScreen()),
                        );
                      },
                      color: Colors.purple,
                    ),

                    _menuCard(
                      icon: Icons.download,
                      title: "Export Results CSV",
                      onTap: _exportResultsCSV,
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