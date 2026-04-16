import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'qr_code_display.dart';
import 'manual_attendance.dart';
import 'course_session_history.dart';

class StaffAttendanceDashboard extends StatefulWidget {
  const StaffAttendanceDashboard({super.key});

  @override
  State<StaffAttendanceDashboard> createState() => _StaffAttendanceDashboardState();
}

class _StaffAttendanceDashboardState extends State<StaffAttendanceDashboard> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _todayClasses = [];

  @override
  void initState() {
    super.initState();
    _fetchTodayClasses();
  }

  Future<void> _fetchTodayClasses() async {
    try {
      final now = DateTime.now();
      final dayName = DateFormat('EEEE').format(now);

      final data = await supabase
          .from('Course')
          .select('*, Schedule!inner(*)')
          .eq('Schedule.DayOfWeek', dayName);

      setState(() {
        _todayClasses = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching classes: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Dashboard'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchTodayClasses),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Today's Classes", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 12),
            _todayClasses.isEmpty
                ? const Card(child: ListTile(title: Text('No classes scheduled for today.'), leading: Icon(Icons.info_outline)))
                : Column(
              children: _todayClasses.map((classData) {
                final schedule = classData['Schedule'];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(classData['Name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text('${schedule['ClassType']} (${schedule['DurationHours']}h)',
                                    style: TextStyle(color: Colors.indigo.shade400, fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            Text('${schedule['StartTime']} - ${schedule['EndTime']}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildActionButton(context, Icons.qr_code, 'QR Code', () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => QRCodeDisplay(
                                courseName: classData['Name'],
                                courseId: classData['ID'],
                                staffId: classData['Staff_ID'],
                                section: "Section 1",
                                sendToEmail: false,
                              )));
                            }),
                            _buildActionButton(context, Icons.history, 'Sessions', () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => CourseSessionsHistory(
                                courseId: classData['ID'],
                                courseName: classData['Name'],
                              )));
                            }, color: Colors.blue.shade700),
                            _buildActionButton(context, Icons.edit_note, 'Today', () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => ManualAttendanceSheet(
                                sessionName: '${classData['Name']} (${schedule['ClassType']})',
                                courseId: classData['ID'],
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
            const SizedBox(height: 24),
            const Text("All My Courses", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 12),
            FutureBuilder(
              future: supabase.from('Course').select('*'),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final courses = snapshot.data as List;
                return Column(
                  children: courses.map((course) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.book, color: Colors.indigo),
                      title: Text(course['Name']),
                      subtitle: Text('ID: ${course['ID']}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => CourseSessionsHistory(
                          courseId: course['ID'],
                          courseName: course['Name'],
                        )));
                      },
                    ),
                  )).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Colors.indigo.shade50,
        foregroundColor: color != null ? Colors.white : Colors.indigo,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}
