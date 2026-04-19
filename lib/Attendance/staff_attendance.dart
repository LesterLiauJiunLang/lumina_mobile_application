import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'qr_code_display.dart';
import 'manual_attendance.dart';
import 'course_session_history.dart';
import '../model/staff.dart';

class StaffAttendanceDashboard extends StatefulWidget {
  const StaffAttendanceDashboard({super.key});

  @override
  State<StaffAttendanceDashboard> createState() => _StaffAttendanceDashboardState();
}

class _StaffAttendanceDashboardState extends State<StaffAttendanceDashboard> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _todaySessions = [];
  List<Map<String, dynamic>> _allMyCourses = [];
  String? _staffId;
  
  final Color _mainBlue = const Color(0xFF005A9C);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Staff) {
      _staffId = args.id;
    } else {
      _staffId = 'S001'; 
    }
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchTodaySessions(),
      _fetchAllCourses(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _fetchTodaySessions() async {
    try {
      final now = DateTime.now();
      final dayName = DateFormat('EEEE').format(now).toUpperCase();

      final data = await supabase
          .from('Schedule')
          .select('*, Course!inner(*)')
          .eq('DayOfWeek', dayName)
          .eq('Course.Staff_ID', _staffId!);

      _todaySessions = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error today sessions: $e');
    }
  }

  Future<void> _fetchAllCourses() async {
    try {
      final data = await supabase
          .from('Course')
          .select('*')
          .eq('Staff_ID', _staffId!);
      _allMyCourses = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error all courses: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Management'),
        backgroundColor: _mainBlue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Today's Sessions", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _mainBlue)),
            const SizedBox(height: 12),
            _todaySessions.isEmpty
                ? const Card(child: ListTile(title: Text('No classes scheduled for today.'), leading: Icon(Icons.info_outline)))
                : Column(
              children: _todaySessions.map((sessionData) {
                final courseRaw = sessionData['Course'];
                final Map<String, dynamic> course = (courseRaw is List) ? courseRaw.first : courseRaw;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(course['Name'] ?? 'Unknown Course', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  Text('${sessionData['ClassType']} • ${sessionData['DurationHours']} Hours',
                                      style: TextStyle(color: _mainBlue, fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            Text('${sessionData['StartTime']} - ${sessionData['EndTime']}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        const Divider(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildClassAction(Icons.qr_code, 'Display QR', () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => QRCodeDisplay(
                                courseName: course['Name'], courseId: course['ID'], staffId: _staffId, section: "1", sendToEmail: false,
                              )));
                            }),
                            _buildClassAction(Icons.edit_calendar, 'Manual', () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => ManualAttendanceSheet(
                                sessionName: '${course['Name']} (${sessionData['ClassType']})', courseId: course['ID'],
                              )));
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 30),
            Text("All My Courses", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _mainBlue)),
            const SizedBox(height: 12),
            ..._allMyCourses.map((course) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: _mainBlue.withOpacity(0.1), child: Icon(Icons.book, color: _mainBlue)),
                title: Text(course['Name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Course ID: ${course['ID']}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => CourseSessionsHistory(
                    courseId: course['ID'],
                    courseName: course['Name'],
                  )));
                },
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildClassAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _mainBlue.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: _mainBlue, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _mainBlue)),
        ],
      ),
    );
  }
}
