import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
//s
class StudentScoreChartScreen extends StatefulWidget {
  final String quizId;
  final String quizTitle;
  final String? studentId;

  const StudentScoreChartScreen({
    super.key,
    required this.quizId,
    required this.quizTitle,
    this.studentId,
  });

  @override
  State<StudentScoreChartScreen> createState() =>
      _StudentScoreChartScreenState();
}

class _StudentScoreChartScreenState
    extends State<StudentScoreChartScreen> {

  bool isAscending = true; // ✅ toggle state

  int _percent(int score, int total) {
    if (total <= 0) return 0;
    return ((score / total) * 100).round();
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return "-";
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
          "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F9),

      appBar: AppBar(
        backgroundColor: const Color(0xFF005A9C),
        title: Text(
          widget.quizTitle,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: widget.studentId == null
            ? supabase
            .from('attempts')
            .select()
            .eq('quiz_id', widget.quizId)
            : supabase
            .from('attempts')
            .select()
            .eq('quiz_id', widget.quizId)
            .eq('student_id', widget.studentId!),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          List<Map<String, dynamic>> attempts = snapshot.data ?? [];

          if (attempts.isEmpty) {
            return const Center(
              child: Text("No attempts recorded yet."),
            );
          }

          // ✅ SORT (by created_at)
          attempts.sort((a, b) {
            final aDate = DateTime.parse(a['created_at']);
            final bDate = DateTime.parse(b['created_at']);
            return isAscending
                ? aDate.compareTo(bDate)
                : bDate.compareTo(aDate);
          });

          // ================= COUNT DISTRIBUTION =================
          int full = 0, high = 0, mid = 0, low = 0;

          for (final a in attempts) {
            final score = (a['score'] as int?) ?? 0;
            final total = (a['total'] as int?) ?? 1;
            final p = _percent(score, total);

            if (p == 100) {
              full++;
            } else if (p >= 80) {
              high++;
            } else if (p >= 50) {
              mid++;
            } else {
              low++;
            }
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.studentId == null
                      ? "Class Performance Overview"
                      : "My Performance Analysis",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 16),

                // ================= PIE CHART =================
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Score Distribution",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

                      SizedBox(
                        height: 220,
                        child: PieChart(
                          PieChartData(
                            centerSpaceRadius: 45,
                            sectionsSpace: 2,
                            sections: [
                              if (full > 0)
                                PieChartSectionData(
                                    value: full.toDouble(),
                                    color: Colors.green,
                                    title: "100%"),
                              if (high > 0)
                                PieChartSectionData(
                                    value: high.toDouble(),
                                    color: Colors.blue,
                                    title: "80%+"),
                              if (mid > 0)
                                PieChartSectionData(
                                    value: mid.toDouble(),
                                    color: Colors.orange,
                                    title: "50%+"),
                              if (low > 0)
                                PieChartSectionData(
                                    value: low.toDouble(),
                                    color: Colors.red,
                                    title: "<50%"),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 12,
                        children: [
                          _legend(Colors.green, "100%: $full"),
                          _legend(Colors.blue, "80-99%: $high"),
                          _legend(Colors.orange, "50-79%: $mid"),
                          _legend(Colors.red, "<50%: $low"),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ================= HEADER WITH SORT =================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Attempt History",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),

                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          isAscending = !isAscending;
                        });
                      },
                      icon: Icon(
                        isAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 18,
                      ),
                      label: Text(isAscending ? "ASC" : "DESC"),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ================= LIST =================
                Expanded(
                  child: ListView.builder(
                    itemCount: attempts.length,
                    itemBuilder: (context, i) {
                      final a = attempts[i];

                      final score = (a['score'] as int?) ?? 0;
                      final total = (a['total'] as int?) ?? 1;
                      final date = _formatDate(a['created_at']);
                      final p = _percent(score, total);

                      //FIXED NUMBERING
                      final attemptNumber = isAscending
                          ? i + 1
                          : attempts.length - i;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: p >= 50
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            child: Text("$p%"),
                          ),
                          title: Text(
                            widget.studentId == null
                                ? "Student: ${a['student_id']}"
                                : "Attempt $attemptNumber",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("Date: $date"),
                          trailing: Text("$score / $total"),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _legend(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}