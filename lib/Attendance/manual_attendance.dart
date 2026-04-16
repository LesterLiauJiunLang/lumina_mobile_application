import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManualAttendanceSheet extends StatefulWidget {
  final String sessionName;
  final String courseId;
  final String? existingSessionId;

  const ManualAttendanceSheet({
    super.key,
    required this.sessionName,
    required this.courseId,
    this.existingSessionId,
  });

  @override
  State<ManualAttendanceSheet> createState() => _ManualAttendanceSheetState();
}

class _ManualAttendanceSheetState extends State<ManualAttendanceSheet> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _students = [];
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    _prepareAttendanceSession();
  }

  Future<void> _prepareAttendanceSession() async {
    try {
      if (widget.existingSessionId != null) {
        _sessionId = widget.existingSessionId;
      } else {
        final today = DateTime.now().toIso8601String().split('T')[0];
        final existingSessions = await supabase.from('AttendanceSession').select('ID').eq('Course_ID', widget.courseId).eq('Date', today).limit(1);
        if (existingSessions.isNotEmpty) {
          _sessionId = existingSessions[0]['ID'];
        } else {
          final newSession = await supabase.from('AttendanceSession').insert({'Course_ID': widget.courseId, 'Date': today, 'QR_Token': 'MANUAL'}).select().single();
          _sessionId = newSession['ID'];
        }
      }

      final enrollmentData = await supabase.from('Enrollment').select('Student(ID, Name)').eq('Course_ID', widget.courseId);
      final List enrolledStudents = (enrollmentData as List).map((e) => e['Student']).toList();

      final recordsData = await supabase.from('AttendanceRecord').select('Student_ID, Status').eq('Session_ID', _sessionId!);
      final Map<String, String> attendanceMap = { for (var r in recordsData) r['Student_ID']: r['Status'] };

      setState(() {
        _students = enrolledStudents.map((s) {
          final studentId = s['ID'];
          return { 'ID': studentId, 'Name': s['Name'], 'status': attendanceMap[studentId] ?? 'Absent' };
        }).toList();
        _isLoading = false;
      });
    } catch (e) { setState(() => _isLoading = false); }
  }

  Future<void> _updateAttendance(int index, String newStatus) async {
    final studentId = _students[index]['ID'];
    setState(() { _students[index]['status'] = newStatus; });
    try { await supabase.from('AttendanceRecord').upsert({ 'Session_ID': _sessionId, 'Student_ID': studentId, 'Status': newStatus, 'MarkedAt': DateTime.now().toIso8601String() }); } catch (e) { debugPrint('Error: $e'); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.sessionName), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(padding: const EdgeInsets.all(16), color: Colors.indigo.shade50, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Enrolled: ${_students.length}', style: const TextStyle(fontWeight: FontWeight.bold)), Text('Present: ${_students.where((s) => s['status'] == 'Present').length}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))])),
          Expanded(
            child: ListView.separated(
              itemCount: _students.length, separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final student = _students[index];
                final bool isPresent = student['status'] == 'Present';
                return ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.indigo, child: Text(student['Name']?[0] ?? 'S', style: const TextStyle(color: Colors.white))),
                  title: Text(student['Name'] ?? 'Unknown'), subtitle: Text(student['ID'] ?? ''),
                  trailing: ElevatedButton(onPressed: () => _updateAttendance(index, isPresent ? 'Absent' : 'Present'), style: ElevatedButton.styleFrom(backgroundColor: isPresent ? Colors.red.shade100 : Colors.green.shade100, foregroundColor: isPresent ? Colors.red : Colors.green, elevation: 0), child: Text(isPresent ? 'Revoke' : 'Attend')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
