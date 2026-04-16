import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'manual_attendance.dart';

class CourseSessionsHistory extends StatefulWidget {
  final String courseId;
  final String courseName;

  const CourseSessionsHistory({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<CourseSessionsHistory> createState() => _CourseSessionsHistoryState();
}

class _CourseSessionsHistoryState extends State<CourseSessionsHistory> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _sessions = [];

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  Future<void> _fetchSessions() async {
    try {
      final data = await supabase
          .from('AttendanceSession')
          .select('*, Schedule(ClassType)')
          .eq('Course_ID', widget.courseId)
          .order('Date', ascending: false);

      setState(() {
        _sessions = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching sessions: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.courseName} - Sessions'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
          ? const Center(child: Text('No past sessions found for this course.'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sessions.length,
        itemBuilder: (context, index) {
          final session = _sessions[index];
          final classType = session['Schedule']?['ClassType'] ?? 'Manual';

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.indigo.shade50,
                child: const Icon(Icons.event, color: Colors.indigo),
              ),
              title: Text('Date: ${session['Date']}'),
              subtitle: Text('Type: $classType | Token: ${session['QR_Token']}'),
              trailing: const Icon(Icons.edit, size: 20, color: Colors.blue),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ManualAttendanceSheet(
                  sessionName: '${widget.courseName} ($classType)',
                  courseId: widget.courseId,
                  existingSessionId: session['ID'],
                )));
              },
            ),
          );
        },
      ),
    );
  }
}
