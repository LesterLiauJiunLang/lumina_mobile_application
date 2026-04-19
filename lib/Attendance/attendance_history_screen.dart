import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../model/student.dart';
import 'student_session_logs.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  final bool isStaff;

  const AttendanceHistoryScreen({
    super.key, 
    required this.isStaff,
  });

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _courseAttendance = [];
  List<Map<String, dynamic>> _todayRegisteredClasses = [];
  String? _studentId;
  int _initialTabIndex = 0; 
  
  final Color _mainBlue = const Color(0xFF005A9C);
  final TextEditingController _tokenController = TextEditingController();
  bool _isScannerLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    
    if (args is Student) {
      _studentId = args.id;
      _initialTabIndex = 0; 
    } else if (args is Map<String, dynamic>) {
      final student = args['student'] as Student;
      _studentId = student.id;
      _initialTabIndex = args['tabIndex'] ?? 0; 
    } else if (args is String) {
      _studentId = args;
    } else {
      _studentId = '26WMR00009';
    }
    
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    if (_studentId == null) return;
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchAttendanceOverview(),
      _fetchTodayRegistered(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _fetchAttendanceOverview() async {
    try {
      final enrollmentData = await supabase
          .from('Enrollment')
          .select('Course:Course_ID(ID, Name)')
          .eq('Student_ID', _studentId!);

      List<Map<String, dynamic>> overview = [];
      final Set<String> processedCourseIds = {};

      for (var item in (enrollmentData as List)) {
        final course = item['Course'];
        if (course == null) continue;
        final courseId = course['ID'];
        if (processedCourseIds.contains(courseId)) continue;
        processedCourseIds.add(courseId);

        final sessions = await supabase
            .from('AttendanceSession')
            .select('ID, Schedule:Schedule_ID(DurationHours)')
            .eq('Course_ID', courseId);

        final records = await supabase
            .from('AttendanceRecord')
            .select('Session_ID')
            .eq('Student_ID', _studentId!)
            .eq('Status', 'Present');

        final Set<String> presentSessionIds = {for (var r in records) r['Session_ID'].toString()};

        double totalHours = 0;
        double attendedHours = 0;
        for (var session in (sessions as List)) {
          final double hours = (session['Schedule']?['DurationHours'] ?? 1).toDouble();
          totalHours += hours;
          if (presentSessionIds.contains(session['ID'].toString())) attendedHours += hours;
        }

        overview.add({
          'courseId': courseId,
          'courseName': course['Name'],
          'percentage': totalHours > 0 ? (attendedHours / totalHours) * 100 : 100.0,
          'totalHours': totalHours,
          'attendedHours': attendedHours,
        });
      }
      _courseAttendance = overview;
    } catch (e) { debugPrint('Error overview: $e'); }
  }

  Future<void> _fetchTodayRegistered() async {
    try {
      final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final data = await supabase
          .from('AttendanceRecord')
          .select('*, Session:Session_ID!inner(ID, Date, Course:Course_ID(Name), Schedule:Schedule_ID(StartTime, EndTime, ClassType))')
          .eq('Student_ID', _studentId!)
          .eq('Status', 'Present')
          .eq('Session.Date', todayDate);

      _todayRegisteredClasses = (data as List).map((r) {
        final session = r['Session'];
        return {
          'course': session['Course']?['Name'] ?? 'Unknown',
          'type': session['Schedule']?['ClassType'] ?? 'N/A',
          'time': '${session['Schedule']?['StartTime'] ?? ""} - ${session['Schedule']?['EndTime'] ?? ""}',
        };
      }).toList();
    } catch (e) { debugPrint('Error today logic: $e'); }
  }

  void _showStatusSnackbar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isSuccess ? Icons.check_circle : Icons.error_outline, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitToken(String token) async {
    if (token.isEmpty) return;
    setState(() => _isScannerLoading = true);
    try {
      final sessionData = await supabase.from('AttendanceSession').select('ID, Date, Course_ID, Course(Name), Schedule:Schedule_ID(StartTime, EndTime)').eq('QR_Token', token).maybeSingle();
      if (sessionData == null) throw 'Invalid Token';

      // Logical Fix: Check if already registered
      final existingRecord = await supabase
          .from('AttendanceRecord')
          .select('ID')
          .eq('Session_ID', sessionData['ID'])
          .eq('Student_ID', _studentId!)
          .maybeSingle();

      if (existingRecord != null) {
        throw 'Registered Already';
      }

      final enrollment = await supabase.from('Enrollment').select('ID').eq('Course_ID', sessionData['Course_ID']).eq('Student_ID', _studentId!);
      if ((enrollment as List).isEmpty) throw 'Not Enrolled';

      final now = DateTime.now();
      if (sessionData['Date'] != DateFormat('yyyy-MM-dd').format(now)) throw 'Wrong Day';

      final schedule = sessionData['Schedule'];
      if (schedule != null) {
        final startTime = _parseTime(schedule['StartTime']);
        final endTime = _parseTime(schedule['EndTime']);
        if (now.isBefore(startTime) || now.isAfter(endTime)) throw 'Class Over';
      }

      await supabase.from('AttendanceRecord').upsert({'Session_ID': sessionData['ID'], 'Student_ID': _studentId, 'Status': 'Present', 'MarkedAt': DateTime.now().toIso8601String()});
      
      if (mounted) {
        _showStatusSnackbar('Attendance Successful', true);
        _tokenController.clear();
        _fetchAllData();
      }
    } catch (e) {
      if (mounted) _showStatusSnackbar(e.toString(), false);
    } finally {
      if (mounted) setState(() => _isScannerLoading = false);
    }
  }

  DateTime _parseTime(String timeStr) {
    final now = DateTime.now();
    final parts = timeStr.split(':');
    return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: _initialTabIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Attendance'), backgroundColor: _mainBlue, foregroundColor: Colors.white,
          bottom: const TabBar(labelColor: Colors.white, unselectedLabelColor: Colors.white70, indicatorColor: Colors.white, indicatorWeight: 3, tabs: [Tab(text: 'Today'), Tab(text: 'Register'), Tab(text: 'Overall')]),
        ),
        body: _isLoading ? const Center(child: CircularProgressIndicator()) : TabBarView(physics: const NeverScrollableScrollPhysics(), children: [_buildTodayTab(), _buildRegisterTab(), _buildOverallTab()]),
      ),
    );
  }

  Widget _buildTodayTab() {
    if (_todayRegisteredClasses.isEmpty) return _buildEmptyState('No classes registered today.', icon: Icons.today);
    return ListView.builder(
      padding: const EdgeInsets.all(16), itemCount: _todayRegisteredClasses.length,
      itemBuilder: (context, index) {
        final session = _todayRegisteredClasses[index];
        return Card(
          elevation: 2, margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.check, color: Colors.white)),
            title: Text(session['course'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${session['type']} • ${session['time']}'),
            trailing: Text('Registered', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        );
      },
    );
  }

  Widget _buildRegisterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Text('Scan Class QR Code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 260, height: 260, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20), border: Border.all(color: _mainBlue, width: 3)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(alignment: Alignment.center, children: [
                  MobileScanner(onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) { if (barcode.rawValue != null && !_isScannerLoading) { _submitToken(barcode.rawValue!); break; } }
                  }),
                  const _ScanningLine(),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Text('OR ENTER TOKEN', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _tokenController, keyboardType: TextInputType.number, textAlign: TextAlign.center, maxLength: 10,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 4),
            decoration: InputDecoration(
              hintText: 'e.g. 123456', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), counterText: "",
              suffixIcon: IconButton(icon: Icon(Icons.send, color: _mainBlue), onPressed: () => _submitToken(_tokenController.text)),
            ),
          ),
          if (_isScannerLoading) const Padding(padding: EdgeInsets.only(top: 20), child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildOverallTab() {
    if (_courseAttendance.isEmpty) return _buildEmptyState('No courses found.');
    return ListView.builder(
      padding: const EdgeInsets.all(16), itemCount: _courseAttendance.length,
      itemBuilder: (context, index) {
        final data = _courseAttendance[index];
        final double p = data['percentage'];
        return Card(
          margin: const EdgeInsets.only(bottom: 16), elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StudentSessionLogs(courseName: data['courseName'], courseId: data['courseId'], percentage: p, studentId: _studentId ?? '26WMR00009'))),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 60, height: 60,
                        child: CircularProgressIndicator(
                          value: p / 100,
                          backgroundColor: Colors.grey.shade200,
                          color: p < 80 ? Colors.red : Colors.green,
                          strokeWidth: 6,
                        ),
                      ),
                      Text('${p.toInt()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: p < 80 ? Colors.red : Colors.green)),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['courseName'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('${data['attendedHours']} / ${data['totalHours']} hours attended', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(
                          p < 80 ? 'Status: Barred (Low)' : 'Status: Eligible',
                          style: TextStyle(color: p < 80 ? Colors.red : Colors.green, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message, {IconData icon = Icons.info_outline}) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16), Text(message, style: TextStyle(color: Colors.grey.shade500))]));
  }

  Widget _buildPercentageChip(double p) {
    Color c = p >= 80 ? Colors.green : Colors.red;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: c)), child: Text('${p.toStringAsFixed(1)}%', style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12)));
  }
}

class _ScanningLine extends StatefulWidget {
  const _ScanningLine();
  @override
  State<_ScanningLine> createState() => _ScanningLineState();
}

class _ScanningLineState extends State<_ScanningLine> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true); }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(top: 40 + (_controller.value * 180), child: Container(width: 200, height: 2, decoration: BoxDecoration(color: Colors.greenAccent, boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)])));
      },
    );
  }
}
