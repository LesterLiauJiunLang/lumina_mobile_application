import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class StaffDistributionChart extends StatefulWidget {
  final List<dynamic> staffList;
  const StaffDistributionChart({super.key, required this.staffList});

  @override
  State<StaffDistributionChart> createState() => _StaffDistributionChartState();
}

class _StaffDistributionChartState extends State<StaffDistributionChart> {
  bool isPieChart = true;
  bool isAscending = false;

  final List<String> jobTitles = [
    'Full-time Lecturer',
    'Part-time Tutor',
    'Tutor',
    'Senior Lecturer',
    'Professor',
    'Superadmin'
  ];

  final List<Color> sectionColors = [
    const Color(0xFF005A9C),
    Colors.orangeAccent,
    Colors.greenAccent[700]!,
    Colors.purpleAccent,
    Colors.redAccent,
    Colors.teal,
  ];

  @override
  Widget build(BuildContext context) {
    // 1. Logic: Group data by JobTitle
    Map<String, int> counts = {};
    for (var title in jobTitles) {
      counts[title] = widget.staffList.where((s) => s['JobTitle'] == title).length;
    }

    // 2. Logic: Sort based on toggle
    List<String> activeTitles = jobTitles.where((t) => counts[t]! > 0).toList();
    activeTitles.sort((a, b) {
      int countA = counts[a]!;
      int countB = counts[b]!;
      return isAscending ? countA.compareTo(countB) : countB.compareTo(countA);
    });

    int totalStaff = widget.staffList.length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // --- REPORT SUMMARY HEADER ---
          _buildHeader(totalStaff),

          const SizedBox(height: 25),

          // --- CHART CONTAINER ---
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 4))],
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                _buildTypeToggle(),

                const SizedBox(height: 35),

                // DYNAMIC CHART
                SizedBox(
                  height: 300,
                  child: totalStaff == 0
                      ? const Center(child: Text("No Data Available"))
                      : isPieChart
                      ? _buildPieChart(activeTitles, counts, totalStaff)
                      : _buildBarChart(activeTitles, counts),
                ),

                const SizedBox(height: 30),

                // --- SORTING CONTROL ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Staff Breakdown", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey)),
                    TextButton.icon(
                      onPressed: () => setState(() => isAscending = !isAscending),
                      icon: Icon(isAscending ? Icons.sort_rounded : Icons.low_priority_rounded, size: 18, color: const Color(0xFF005A9C)),
                      label: Text(isAscending ? "Ascending" : "Descending", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 10),

                // --- LEGEND LIST ---
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activeTitles.length,
                  itemBuilder: (context, index) {
                    String title = activeTitles[index];
                    return _buildLegendItem(
                        sectionColors[jobTitles.indexOf(title) % sectionColors.length],
                        title,
                        "${counts[title]} Staff"
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // --- UI COMPONENT HELPERS ---

  Widget _buildHeader(int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF005A9C),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          const Text("STAFF DISTRIBUTION REPORT", style: TextStyle(color: Colors.white, letterSpacing: 1.2, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          Text("$total", style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900)),
          const Text("Total Staff Registered", style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          _buildToggleItem(true, "Pie Chart", Icons.pie_chart),
          _buildToggleItem(false, "Histogram", Icons.bar_chart),
        ],
      ),
    );
  }

  Widget _buildToggleItem(bool value, String label, IconData icon) {
    bool active = isPieChart == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isPieChart = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: active ? const Color(0xFF005A9C) : Colors.grey),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(
                fontWeight: active ? FontWeight.bold : FontWeight.w600,
                color: active ? const Color(0xFF005A9C) : Colors.grey,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart(List<String> titles, Map<String, int> counts, int total) {
    return PieChart(
      PieChartData(
        sectionsSpace: 3,
        centerSpaceRadius: 50,
        sections: titles.asMap().entries.map((entry) {
          int index = jobTitles.indexOf(entry.value);
          double value = counts[entry.value]!.toDouble();
          double percentage = (value / total) * 100;

          return PieChartSectionData(
            color: sectionColors[index % sectionColors.length],
            value: value,
            title: '${percentage.toStringAsFixed(0)}%',
            radius: 65,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBarChart(List<String> titles, Map<String, int> counts) {
    double rawMaxY = counts.values.isNotEmpty
        ? counts.values.reduce((a, b) => a > b ? a : b).toDouble()
        : 0;
    double fixedMaxY = ((rawMaxY / 5).ceil() * 5).toDouble();
    if (fixedMaxY < 5) fixedMaxY = 5;

    return BarChart(
      BarChartData(
        maxY: fixedMaxY,
        borderData: FlBorderData(
          show: true,
          border: const Border(
            bottom: BorderSide(color: Colors.blueGrey, width: 2),
            left: BorderSide(color: Colors.blueGrey, width: 2),
          ),
        ),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              reservedSize: 35,
              getTitlesWidget: (val, meta) => Text(val.toInt().toString(), style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < titles.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(titles[value.toInt()].substring(0, 3).toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: titles.asMap().entries.map((entry) {
          int index = entry.key;
          double value = counts[entry.value]!.toDouble();
          Color color = sectionColors[jobTitles.indexOf(entry.value) % sectionColors.length];
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: value,
                gradient: LinearGradient(colors: [color, color.withOpacity(0.7)], begin: Alignment.bottomCenter, end: Alignment.topCenter),
                width: 22,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
                backDrawRodData: BackgroundBarChartRodData(show: true, toY: fixedMaxY, color: Colors.grey[100]),
              )
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 15),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87))),
          Text(subtitle, style: const TextStyle(color: Color(0xFF005A9C), fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}