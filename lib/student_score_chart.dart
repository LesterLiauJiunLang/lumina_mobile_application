import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

class _StudentScoreChartScreenState extends State<StudentScoreChartScreen> {

  bool isAscending = true;
  bool isPieChart = true;

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
            ? supabase.from('attempts').select().eq('quiz_id', widget.quizId)
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

          // SORT
          attempts.sort((a, b) {
            final aDate = DateTime.parse(a['created_at']);
            final bDate = DateTime.parse(b['created_at']);
            return isAscending
                ? aDate.compareTo(bDate)
                : bDate.compareTo(aDate);
          });

          // DISTRIBUTION
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

          int totalAttempts = attempts.length;

          double avgPercent = 0;
          int highest = 0;
          int lowest = 100;

          for (final a in attempts) {
            final score = (a['score'] as int?) ?? 0;
            final total = (a['total'] as int?) ?? 1;

            final percent = _percent(score, total);

            avgPercent += percent;

            if (percent > highest) highest = percent;
            if (percent < lowest) lowest = percent;
          }

          avgPercent = totalAttempts > 0 ? avgPercent / totalAttempts : 0;

          return SingleChildScrollView(
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

                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [

                      _statItem("Attempts", totalAttempts.toString(), Icons.list),

                      _statItem(
                        "Average",
                        "${avgPercent.toStringAsFixed(1)}%",
                        Icons.show_chart,
                      ),

                      _statItem("Highest", "$highest%", Icons.arrow_upward),

                      _statItem("Lowest", "$lowest%", Icons.arrow_downward),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ================= NEW MODERN CHART =================
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [

                      // TOGGLE
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _chartToggle(true, "Pie", Icons.pie_chart),
                            _chartToggle(false, "Bar", Icons.bar_chart),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      SizedBox(
                        height: 250,
                        child: isPieChart
                            ? _buildScorePie(full, high, mid, low)
                            : _buildScoreBar(full, high, mid, low),
                      ),

                      const SizedBox(height: 25),

                      Column(
                        children: [
                          _legendTile(Colors.green, "100%", full),
                          _legendTile(Colors.blue, "80 - 99%", high),
                          _legendTile(Colors.orange, "50 - 79%", mid),
                          _legendTile(Colors.red, "< 50%", low),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ================= LIST =================
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

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                    itemCount: attempts.length,
                    itemBuilder: (context, i) {
                      final a = attempts[i];

                      final score = (a['score'] as int?) ?? 0;
                      final total = (a['total'] as int?) ?? 1;
                      final date = _formatDate(a['created_at']);
                      final p = _percent(score, total);

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
              ],
            ),
          );
        },
      ),
    );
  }

  // ================= TOGGLE =================
  Widget _chartToggle(bool value, String text, IconData icon) {
    bool active = isPieChart == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isPieChart = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: active ? const Color(0xFF005A9C) : Colors.grey),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: active ? const Color(0xFF005A9C) : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= PIE =================
  Widget _buildScorePie(int full, int high, int mid, int low) {
    final total = full + high + mid + low;

    return PieChart(
      PieChartData(
        sectionsSpace: 3,
        centerSpaceRadius: 50,
        sections: [
          if (full > 0) _pieSection(full, total, Colors.green),
          if (high > 0) _pieSection(high, total, Colors.blue),
          if (mid > 0) _pieSection(mid, total, Colors.orange),
          if (low > 0) _pieSection(low, total, Colors.red),
        ],
      ),
    );
  }

  PieChartSectionData _pieSection(int value, int total, Color color) {
    final percent = (value / total) * 100;

    return PieChartSectionData(
      color: color,
      value: value.toDouble(),
      title: "${percent.toStringAsFixed(0)}%",
      radius: 65,
      titleStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );
  }

  // ================= BAR =================
  Widget _buildScoreBar(int full, int high, int mid, int low) {
    final data = [full, high, mid, low];

    double maxY =
    data.reduce((a, b) => a > b ? a : b).toDouble();
    double fixedMaxY = ((maxY / 5).ceil() * 5).toDouble();
    if (fixedMaxY < 5) fixedMaxY = 5;

    final labels = ["100%", "80+", "50+", "<50"];
    final colors = [Colors.green, Colors.blue, Colors.orange, Colors.red];

    return BarChart(
      BarChartData(
        maxY: fixedMaxY,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            left: BorderSide(color: Colors.blueGrey, width: 2),
            bottom: BorderSide(color: Colors.blueGrey, width: 2),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              reservedSize: 30,
              getTitlesWidget: (value, _) =>
                  Text(value.toInt().toString()),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                if (value.toInt() < labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(labels[value.toInt()]),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          topTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: data.asMap().entries.map((entry) {
          int i = entry.key;
          double val = entry.value.toDouble();

          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: val,
                width: 20,
                color: colors[i],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              )
            ],
          );
        }).toList(),
      ),
    );
  }

  // ================= LEGEND =================
  Widget _legendTile(Color color, String label, int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          Text(
            "$count",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF005A9C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF005A9C)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}