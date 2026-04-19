import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class StudentAnnouncementScreen extends StatefulWidget {
  final String studentId;
  const StudentAnnouncementScreen({super.key, required this.studentId});

  @override
  State<StudentAnnouncementScreen> createState() => _StudentAnnouncementScreenState();
}

class _StudentAnnouncementScreenState extends State<StudentAnnouncementScreen> {
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final supabase = Supabase.instance.client;
      final studentId = widget.studentId;

      // 1. Get enrolled course IDs for this student
      final enrollments = await supabase
          .from('Enrollment')
          .select('Course_ID')
          .eq('Student_ID', studentId);
      final courseIds = enrollments.map((e) => e['Course_ID'] as String).toList();

      if (courseIds.isEmpty) {
        setState(() {
          _announcements = [];
          _isLoading = false;
        });
        return;
      }

      // 2. Fetch ONLY course announcements (timetable changes) for enrolled courses
      final data = await supabase
          .from('Announcement')
          .select('*')
          .eq('Type', 'Course')
          .inFilter('Course_ID', courseIds)
          .order('Created_At', ascending: false);

      setState(() {
        _announcements = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateTimeString) {
    if (dateTimeString == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateTimeString);
      return DateFormat('MMM d, yyyy • h:mm a').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        backgroundColor: const Color(0xFF005A9C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : _announcements.isEmpty
          ? const Center(child: Text('No announcements for you.'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _announcements.length,
        itemBuilder: (context, index) {
          final ann = _announcements[index];
          final type = ann['Type'];
          String typeLabel = '';
          Color typeColor = Colors.blue;
          switch (type) {
            case 'General':
              typeLabel = 'General';
              typeColor = Colors.grey;
              break;
            case 'Student':
              typeLabel = 'Students';
              typeColor = Colors.green;
              break;
            case 'Course':
              typeLabel = 'Course: ${ann['Course_ID']}';
              typeColor = const Color(0xFF005A9C);
              break;
          }
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          typeLabel,
                          style: TextStyle(
                            color: typeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(ann['Created_At']),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ann['Title'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(ann['Content']),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}