import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
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
  List<Map<String, dynamic>> _filteredSessions = [];
  
  final Color _mainBlue = const Color(0xFF005A9C);
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;

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
        _filteredSessions = _sessions;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching sessions: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterSessions(String query) {
    setState(() {
      _filteredSessions = _sessions.where((session) {
        final dateMatch = session['Date'].toString().contains(query);
        final typeMatch = (session['Schedule']?['ClassType'] ?? 'Manual')
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase());
        return dateMatch || typeMatch;
      }).toList();
      
      if (_selectedDate != null) {
        final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
        _filteredSessions = _filteredSessions.where((s) => s['Date'] == dateStr).toList();
      }
    });
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: _mainBlue),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _searchController.text = DateFormat('yyyy-MM-dd').format(picked);
        _filterSessions(_searchController.text);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.courseName} History'),
        backgroundColor: _mainBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search date or type...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear), 
                            onPressed: () {
                              _searchController.clear();
                              _selectedDate = null;
                              _filterSessions('');
                            })
                        : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: _filterSessions,
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.calendar_month, color: _mainBlue),
                  onPressed: _pickDate,
                  tooltip: 'Filter by Date',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSessions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('No sessions match your search.', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredSessions.length,
              itemBuilder: (context, index) {
                final session = _filteredSessions[index];
                final classType = session['Schedule']?['ClassType'] ?? 'Manual';
                final date = DateTime.parse(session['Date']);

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _mainBlue.withOpacity(0.1),
                      child: Icon(Icons.event, color: _mainBlue),
                    ),
                    title: Text(
                      DateFormat('EEEE, MMM d, yyyy').format(date),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Type: $classType | Token: ${session['QR_Token']}'),
                    trailing: const Icon(Icons.edit_note, color: Colors.blue),
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
          ),
        ],
      ),
    );
  }
}
