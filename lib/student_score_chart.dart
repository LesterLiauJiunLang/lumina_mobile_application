import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
//s
class StudentScoreChartScreen extends StatelessWidget {
  final String quizId;
  final String quizTitle;
  final String? studentId;

  const StudentScoreChartScreen({
    super.key,
    required this.quizId,
    required this.quizTitle,
    this.studentId,
  });

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
      appBar: AppBar(title: Text("Analysis: $quizTitle")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: studentId == null
            ? supabase
            .from('attempts')
            .select()
            .eq('quiz_id', quizId) // ✅ FIXED
            .order('created_at')
            : supabase
            .from('attempts')
            .select()
            .eq('quiz_id', quizId) // ✅ FIXED
            .eq('student_id', studentId!)
            .order('created_at'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final attempts = snapshot.data ?? [];

          if (attempts.isEmpty) {
            return const Center(child: Text("No attempts recorded yet."));
          }

          int full = 0;
          int high = 0;
          int mid = 0;
          int low = 0;

          for (final a in attempts) {
            final score = (a['score'] as int?) ?? 0;
            final total = (a['total'] as int?) ?? 1;
            final p = _percent(score, total);

            if (p == 100) full++;
            else if (p >= 80) high++;
            else if (p >= 50) mid++;
            else low++;
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Score Distribution",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: 40,
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

                const SizedBox(height: 20),

                Wrap(
                  spacing: 12,
                  children: [
                    _legend(Colors.green, "100%: $full"),
                    _legend(Colors.blue, "80-99%: $high"),
                    _legend(Colors.orange, "50-79%: $mid"),
                    _legend(Colors.red, "<50%: $low"),
                  ],
                ),

                const Divider(height: 32),

                Text(
                  studentId == null
                      ? "All Student Results"
                      : "My Attempt History",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: ListView.builder(
                    itemCount: attempts.length,
                    itemBuilder: (context, i) {
                      final a = attempts[i];
                      final score = (a['score'] as int?) ?? 0;
                      final total = (a['total'] as int?) ?? 0;
                      final date = _formatDate(a['created_at']);
                      final p = _percent(score, total);

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: p >= 50
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            child: Text("$p%"),
                          ),
                          title: Text(studentId == null
                              ? "Student: ${a['student_id']}"
                              : "Attempt ${i + 1}"),
                          subtitle: Text("Date: $date"),
                          trailing: Text("$score / $total"),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.popUntil(
                        context, (route) => route.isFirst),
                    child: const Text("Return to Dashboard"),
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
        const SizedBox(width: 4),
        Text(text),
      ],
    );
  }
}