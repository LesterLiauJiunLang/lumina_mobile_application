import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class StudentSessionLogs extends StatefulWidget {
  final String courseName;
  final String courseId;
  final double percentage;
  final String studentId;

  const StudentSessionLogs({
    super.key,
    required this.courseName,
    required this.courseId,
    required this.percentage,
    required this.studentId,
  });

  @override
  State<StudentSessionLogs> createState() => _StudentSessionLogsState();
}

class _StudentSessionLogsState extends State<StudentSessionLogs> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _allSessions = [];
  
  final Color _mainBlue = const Color(0xFF005A9C);

  @override
  void initState() {
    super.initState();
    _fetchComprehensiveLogs();
  }

  Future<void> _fetchComprehensiveLogs() async {
    try {
      // 1. Fetch ALL sessions for this course
      final sessionsData = await supabase
          .from('AttendanceSession')
          .select('ID, Date, Schedule:Schedule_ID(ClassType, StartTime, EndTime)')
          .eq('Course_ID', widget.courseId)
          .order('Date', ascending: false);

      // 2. Fetch all Present records for this student
      final recordsData = await supabase
          .from('AttendanceRecord')
          .select('Session_ID, Status, MarkedAt')
          .eq('Student_ID', widget.studentId)
          .eq('Status', 'Present');

      final Map<String, dynamic> attendanceMap = {
        for (var r in recordsData) r['Session_ID'].toString(): r
      };

      setState(() {
        _allSessions = (sessionsData as List).map((s) {
          final attendance = attendanceMap[s['ID'].toString()];
          final bool isPresent = attendance != null;
          
          return {
            'date': s['Date'],
            'type': s['Schedule']?['ClassType'] ?? 'N/A',
            'time': '${s['Schedule']?['StartTime'] ?? ""} - ${s['Schedule']?['EndTime'] ?? ""}',
            'status': isPresent ? 'Present' : 'Absent',
            'markedAt': isPresent ? attendance['MarkedAt'] : null,
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching detailed logs: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    int attendedCount = _allSessions.where((s) => s['status'] == 'Present').length;
    int absentCount = _allSessions.where((s) => s['status'] == 'Absent').length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseName),
        backgroundColor: _mainBlue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            // Summary Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(
                color: _mainBlue.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CircularProgressIndicator(
                            value: widget.percentage / 100,
                            strokeWidth: 10,
                            backgroundColor: Colors.grey.shade300,
                            color: widget.percentage < 80 ? Colors.red : Colors.green,
                          ),
                        ),
                        Text(
                          '${widget.percentage.toInt()}%',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Attended', '$attendedCount', Colors.green),
                      _buildStatItem('Absent', '$absentCount', Colors.red),
                      _buildStatItem('Target', '80%', _mainBlue),
                    ],
                  ),
                ],
              ),
            ),
            
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Session History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),

            if (_allSessions.isEmpty)
              const Padding(padding: EdgeInsets.all(40), child: Text('No attendance records found for this course.'))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _allSessions.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final session = _allSessions[index];
                  bool isPresent = session['status'] == 'Present';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isPresent ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                      child: Icon(
                        isPresent ? Icons.check : Icons.close,
                        color: isPresent ? Colors.green : Colors.red,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      DateFormat('EEE, MMM d, yyyy').format(DateTime.parse(session['date'])),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${session['type']} (${session['time']})'),
                        if (isPresent && session['markedAt'] != null)
                          Text(
                            'Marked at: ${DateFormat('hh:mm a').format(DateTime.parse(session['markedAt']))}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                      ],
                    ),
                    trailing: Text(
                      session['status'],
                      style: TextStyle(
                        color: isPresent ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
      ],
    );
  }
}
