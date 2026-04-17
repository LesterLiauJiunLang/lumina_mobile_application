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
  List<Map<String, dynamic>> _filteredStudents = [];
  String? _sessionId;
  final Color _mainBlue = const Color(0xFF005A9C);
  final TextEditingController _searchController = TextEditingController();
  
  String _selectedFilter = 'All'; 
  String _sortBy = 'Name (A-Z)'; 
  int _totalSessionsCount = 0;

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

      // Fetch students with TutorialGroup
      final enrollmentData = await supabase.from('Enrollment').select('Student(ID, Name, Programme, Faculty, TutorialGroup)').eq('Course_ID', widget.courseId);
      final List enrolledStudents = (enrollmentData as List).map((e) => e['Student']).toList();

      final recordsData = await supabase.from('AttendanceRecord').select('Student_ID, Status').eq('Session_ID', _sessionId!);
      final Map<String, String> attendanceMap = { for (var r in recordsData) r['Student_ID']: r['Status'] };

      final allSessions = await supabase.from('AttendanceSession').select('ID').eq('Course_ID', widget.courseId);
      final List allSessionIds = (allSessions as List).map((s) => s['ID']).toList();
      _totalSessionsCount = allSessionIds.length;
      
      final allRecords = await supabase.from('AttendanceRecord')
          .select('Student_ID, Status, Session_ID')
          .inFilter('Session_ID', allSessionIds)
          .eq('Status', 'Present');

      Map<String, int> studentPresentCounts = {};
      for (var r in (allRecords as List)) {
        if (r['Session_ID'] != _sessionId) {
          String sId = r['Student_ID'];
          studentPresentCounts[sId] = (studentPresentCounts[sId] ?? 0) + 1;
        }
      }

      setState(() {
        _students = enrolledStudents.map((s) {
          final studentId = s['ID'];
          final currentStatus = attendanceMap[studentId] ?? 'Absent';
          int otherPresentCount = studentPresentCounts[studentId] ?? 0;
          
          return {
            'ID': studentId,
            'Name': s['Name'],
            'Programme': s['Programme'],
            'Faculty': s['Faculty'],
            'TutorialGroup': s['TutorialGroup'],
            'status': currentStatus,
            'otherPresentCount': otherPresentCount,
          };
        }).toList();
        _applyFiltersAndSort();
        _isLoading = false;
      });
    } catch (e) { 
      debugPrint('Init error: $e');
      setState(() => _isLoading = false); 
    }
  }

  double _calculateOverallPercentage(Map<String, dynamic> student) {
    int totalPresent = student['otherPresentCount'] + (student['status'] == 'Present' ? 1 : 0);
    return _totalSessionsCount > 0 ? (totalPresent / _totalSessionsCount) * 100 : 100.0;
  }

  void _applyFiltersAndSort() {
    String query = _searchController.text.toLowerCase();
    List<Map<String, dynamic>> filtered = _students.where((s) {
      final nameMatch = (s['Name']?.toString().toLowerCase() ?? "").contains(query);
      final idMatch = (s['ID']?.toString().toLowerCase() ?? "").contains(query);
      final statusMatch = _selectedFilter == 'All' || s['status'] == _selectedFilter;
      return (nameMatch || idMatch) && statusMatch;
    }).toList();

    switch (_sortBy) {
      case 'Name (A-Z)': filtered.sort((a, b) => (a['Name'] ?? "").compareTo(b['Name'] ?? "")); break;
      case 'Name (Z-A)': filtered.sort((a, b) => (b['Name'] ?? "").compareTo(a['Name'] ?? "")); break;
      case 'Attendance (High)': filtered.sort((a, b) => _calculateOverallPercentage(b).compareTo(_calculateOverallPercentage(a))); break;
      case 'Attendance (Low)': filtered.sort((a, b) => _calculateOverallPercentage(a).compareTo(_calculateOverallPercentage(b))); break;
    }
    setState(() { _filteredStudents = filtered; });
  }

  void _showStudentDetails(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CircleAvatar(backgroundColor: _mainBlue, child: Text(student['Name']?[0] ?? 'S', style: const TextStyle(color: Colors.white))),
            const SizedBox(width: 12),
            const Text('Student Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Name', student['Name']),
            _buildDetailRow('ID', student['ID']),
            _buildDetailRow('Group', student['TutorialGroup']?.toString()),
            _buildDetailRow('Programme', student['Programme']),
            const Divider(height: 24),
            _buildDetailRow('Overall Attendance', '${_calculateOverallPercentage(student).toInt()}%'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Close', style: TextStyle(color: _mainBlue, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.bold)),
          Text(value ?? 'N/A', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showStatusSnackbar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1500), behavior: SnackBarBehavior.floating, backgroundColor: Colors.transparent, elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(color: isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFC62828), borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))]),
          child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(isSuccess ? Icons.check_circle : Icons.error_outline, color: Colors.white, size: 24), const SizedBox(width: 12), Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))]),
        ),
      ),
    );
  }

  Future<void> _updateAttendance(int indexInFiltered, String newStatus) async {
    final student = _filteredStudents[indexInFiltered];
    final studentId = student['ID'];
    setState(() {
      student['status'] = newStatus;
      final originalIndex = _students.indexWhere((s) => s['ID'] == studentId);
      if (originalIndex != -1) _students[originalIndex]['status'] = newStatus;
    });
    if (mounted) _showStatusSnackbar(newStatus == 'Present' ? 'Marked Present' : 'Marked Absent', newStatus == 'Present');
    try { await supabase.from('AttendanceRecord').upsert({ 'Session_ID': _sessionId, 'Student_ID': studentId, 'Status': newStatus, 'MarkedAt': DateTime.now().toIso8601String() }); } catch (e) { debugPrint('Error: $e'); }
  }

  Future<void> _markAllPresent() async {
    final targetStudents = _filteredStudents.where((s) => s['status'] != 'Present').toList();
    if (targetStudents.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Action'),
        content: Text('Mark all ${targetStudents.length} filtered students as Present?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Confirm', style: TextStyle(color: _mainBlue, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      for (var s in targetStudents) { s['status'] = 'Present'; }
      for (var ts in targetStudents) {
        final idx = _students.indexWhere((s) => s['ID'] == ts['ID']);
        if (idx != -1) _students[idx]['status'] = 'Present';
      }
    });

    _showStatusSnackbar('Bulk Registration Successful', true);
    try {
      final records = targetStudents.map((s) => { 'Session_ID': _sessionId, 'Student_ID': s['ID'], 'Status': 'Present', 'MarkedAt': DateTime.now().toIso8601String() }).toList();
      await supabase.from('AttendanceRecord').upsert(records);
    } catch (e) { debugPrint('Error marking all: $e'); }
  }

  void _showSummary() {
    int p = _students.where((s) => s['status'] == 'Present').length;
    int a = _students.length - p;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Session Summary', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSummaryRow('Enrolled Students', '${_students.length}', Colors.black87),
            _buildSummaryRow('Present Today', '$p', Colors.green),
            _buildSummaryRow('Absent Today', '$a', Colors.red),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: _students.isEmpty ? 0 : p / _students.length, backgroundColor: Colors.grey.shade200, color: Colors.green, minHeight: 10),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label), Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color))]),
    );
  }

  @override
  Widget build(BuildContext context) {
    int presentCount = _students.where((s) => s['status'] == 'Present').length;
    double classAttendanceRate = _students.isEmpty ? 0 : (presentCount / _students.length) * 100;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sessionName), backgroundColor: _mainBlue, foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.analytics_outlined), tooltip: 'Summary', onPressed: _showSummary),
          IconButton(icon: const Icon(Icons.done_all), tooltip: 'Mark Filtered Present', onPressed: _markAllPresent),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16), color: _mainBlue.withOpacity(0.05), 
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Enrolled: ${_students.length}', style: const TextStyle(fontWeight: FontWeight.bold)), Text('Present: $presentCount', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))]),
                const SizedBox(height: 8),
                ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: classAttendanceRate / 100, backgroundColor: Colors.grey.shade200, color: Colors.green, minHeight: 6)),
              ],
            )
          ),
          // Search & Sort Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController, onChanged: (_) => _applyFiltersAndSort(),
                    decoration: InputDecoration(hintText: 'Search student...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(vertical: 0)),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(color: _mainBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: PopupMenuButton<String>(
                    icon: Icon(Icons.sort, color: _mainBlue),
                    onSelected: (value) { setState(() => _sortBy = value); _applyFiltersAndSort(); },
                    itemBuilder: (context) => ['Name (A-Z)', 'Name (Z-A)', 'Attendance (High)', 'Attendance (Low)'].map((s) => PopupMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                  ),
                ),
              ],
            ),
          ),
          // Filter Chips
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: Row(
              children: ['All', 'Present', 'Absent'].map((label) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(label, style: TextStyle(color: _selectedFilter == label ? Colors.white : Colors.black87, fontSize: 12)),
                  selected: _selectedFilter == label, selectedColor: _mainBlue, backgroundColor: Colors.grey.shade100,
                  onSelected: (bool selected) { if (selected) { setState(() => _selectedFilter = label); _applyFiltersAndSort(); } },
                ),
              )).toList(),
            ),
          ),
          const Divider(height: 1),
          // Student List with Refresh
          Expanded(
            child: RefreshIndicator(
              onRefresh: _prepareAttendanceSession,
              child: _filteredStudents.isEmpty 
                ? const Center(child: Text('No students found.'))
                : ListView.separated(
                itemCount: _filteredStudents.length, separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final student = _filteredStudents[index];
                  final bool isPresent = student['status'] == 'Present';
                  final double overallP = _calculateOverallPercentage(student);
                  final bool isAtRisk = overallP < 80;

                  return ListTile(
                    onTap: () => _showStudentDetails(student),
                    leading: CircleAvatar(backgroundColor: _mainBlue, child: Text(student['Name']?[0] ?? 'S', style: const TextStyle(color: Colors.white))),
                    title: Row(children: [Text(student['Name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)), if (isAtRisk) ...[const SizedBox(width: 6), const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18)]]), 
                    subtitle: Text('ID: ${student['ID']} • Att: ${overallP.toInt()}%'),
                    trailing: ElevatedButton(
                      onPressed: () => _updateAttendance(index, isPresent ? 'Absent' : 'Present'), 
                      style: ElevatedButton.styleFrom(backgroundColor: isPresent ? Colors.red.shade50 : Colors.green.shade50, foregroundColor: isPresent ? Colors.red : Colors.green, elevation: 0, side: BorderSide(color: isPresent ? Colors.red.shade100 : Colors.green.shade100)), 
                      child: Text(isPresent ? 'Revoke' : 'Attend', style: const TextStyle(fontSize: 12))
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
