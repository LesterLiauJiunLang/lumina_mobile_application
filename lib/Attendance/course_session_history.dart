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
  List<Map<String, dynamic>> _historySessions = [];
  List<Map<String, dynamic>> _upcomingSessions = [];
  List<Map<String, dynamic>> _filteredHistory = [];
  
  final Color _mainBlue = const Color(0xFF005A9C);
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchSessionsAndStats();
  }

  Future<void> _fetchSessionsAndStats() async {
    try {
      final enrollmentRes = await supabase
          .from('Enrollment')
          .select('ID')
          .eq('Course_ID', widget.courseId);
      final int totalEnrolled = enrollmentRes.length;

      final data = await supabase
          .from('AttendanceSession')
          .select('*, Schedule:Schedule_ID(ClassType)')
          .eq('Course_ID', widget.courseId);

      final List<Map<String, dynamic>> sessionsList = List<Map<String, dynamic>>.from(data);

      if (sessionsList.isEmpty) {
        setState(() {
          _historySessions = [];
          _upcomingSessions = [];
          _filteredHistory = [];
          _isLoading = false;
        });
        return;
      }

      final sessionIds = sessionsList.map((s) => s['ID']).toList();
      final recordsData = await supabase
          .from('AttendanceRecord')
          .select('Session_ID, Status')
          .inFilter('Session_ID', sessionIds)
          .eq('Status', 'Present');

      final List records = recordsData as List;

      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);

      List<Map<String, dynamic>> history = [];
      List<Map<String, dynamic>> upcoming = [];

      for (var s in sessionsList) {
        final sId = s['ID'];
        final dateStr = s['Date'];
        final date = DateTime.parse(dateStr);
        final bool isFuture = date.isAfter(now) && dateStr != todayStr;
        
        final int presentCount = records.where((r) => r['Session_ID'] == sId).length;
        
        final sessionData = {
          ...s,
          'presentCount': presentCount,
          'absentCount': totalEnrolled - presentCount,
        };

        if (isFuture) {
          upcoming.add(sessionData);
        } else {
          history.add(sessionData);
        }
      }

      history.sort((a, b) => b['Date'].compareTo(a['Date']));
      upcoming.sort((a, b) => a['Date'].compareTo(b['Date']));

      setState(() {
        _historySessions = history;
        _upcomingSessions = upcoming;
        _filteredHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching sessions: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterHistory(String query) {
    setState(() {
      _filteredHistory = _historySessions.where((session) {
        final dateMatch = session['Date'].toString().contains(query);
        final typeMatch = (session['Schedule']?['ClassType'] ?? 'Manual')
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase());
        return dateMatch || typeMatch;
      }).toList();
      
      if (_selectedDate != null) {
        final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
        _filteredHistory = _filteredHistory.where((s) => s['Date'] == dateStr).toList();
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
        _filterHistory(_searchController.text);
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // --- Search & Filter Bar ---
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _filterHistory,
                          decoration: InputDecoration(
                            hintText: 'Search past dates or types...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty 
                              ? IconButton(
                                  icon: const Icon(Icons.clear), 
                                  onPressed: () {
                                    _searchController.clear();
                                    _selectedDate = null;
                                    _filterHistory('');
                                  })
                              : null,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          ),
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
                  child: RefreshIndicator(
                    onRefresh: _fetchSessionsAndStats,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          if (_filteredHistory.isEmpty && _upcomingSessions.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(40.0),
                              child: Center(child: Text('No matching sessions found.')),
                            ),
                          
                          // --- RECENT & PAST SESSIONS ---
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredHistory.length,
                            itemBuilder: (context, index) => _buildSessionCard(_filteredHistory[index], false),
                          ),

                          // --- UPCOMING SESSIONS (Expandable) ---
                          if (_upcomingSessions.isNotEmpty && _searchController.text.isEmpty)
                            Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                title: Text(
                                  'Upcoming Sessions (${_upcomingSessions.length})',
                                  style: TextStyle(color: _mainBlue, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                children: [
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    itemCount: _upcomingSessions.length,
                                    itemBuilder: (context, index) => _buildSessionCard(_upcomingSessions[index], true),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session, bool isFuture) {
    final classType = session['Schedule']?['ClassType'] ?? 'Manual';
    final date = DateTime.parse(session['Date']);
    
    return Card(
      elevation: isFuture ? 0 : 2,
      color: isFuture ? Colors.grey[50] : Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isFuture ? BorderSide(color: Colors.grey[200]!) : BorderSide.none,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isFuture ? Colors.grey[200] : _mainBlue.withOpacity(0.1),
          child: Icon(
            isFuture ? Icons.lock_clock : Icons.event, 
            color: isFuture ? Colors.grey : _mainBlue
          ),
        ),
        title: Text(
          DateFormat('EEEE, MMM d, yyyy').format(date),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isFuture ? Colors.grey : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Type: $classType | Token: ${session['QR_Token']}',
              style: TextStyle(color: isFuture ? Colors.grey : Colors.black54),
            ),
            if (!isFuture)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    _statBadge('Present: ${session['presentCount']}', Colors.green),
                    const SizedBox(width: 8),
                    _statBadge('Absent: ${session['absentCount']}', Colors.red),
                  ],
                ),
              ),
          ],
        ),
        trailing: isFuture 
          ? const Icon(Icons.block, size: 18, color: Colors.grey)
          : const Icon(Icons.edit_note, color: Colors.blue),
        onTap: isFuture ? null : () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ManualAttendanceSheet(
            sessionName: '${widget.courseName} ($classType)',
            courseId: widget.courseId,
            existingSessionId: session['ID'],
          )));
        },
      ),
    );
  }

  Widget _statBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color, 
          fontSize: 10, 
          fontWeight: FontWeight.bold
        ),
      ),
    );
  }
}
