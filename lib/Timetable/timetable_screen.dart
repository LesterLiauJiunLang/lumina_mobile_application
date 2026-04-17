import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'announcement_screen.dart';
import 'personal_event_form_screen.dart';

// This is the widget that will be called from the route
class TimetableScreen extends StatelessWidget {
  final String studentId;
  const TimetableScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return _TimetableScreenContent(studentId: studentId);
  }
}

// Internal stateful widget
class _TimetableScreenContent extends StatefulWidget {
  final String studentId;
  const _TimetableScreenContent({required this.studentId});

  @override
  State<_TimetableScreenContent> createState() => _TimetableScreenContentState();
}

class _TimetableScreenContentState extends State<_TimetableScreenContent> {
  List<Map<String, dynamic>> _allEntries = [];
  bool _isLoading = true;
  String? _errorMessage;

  final List<String> _dayOrder = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _fetchAllTimetableEntries();
  }

  Future<void> _fetchAllTimetableEntries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final studentId = widget.studentId;  // Use the passed ID directly

      // 1. Fetch enrolled courses
      final enrollments = await supabase
          .from('Enrollment')
          .select('Course_ID')
          .eq('Student_ID', studentId);
      final courseIds = enrollments.map((e) => e['Course_ID'] as String).toList();

      List<Map<String, dynamic>> courseEntries = [];
      if (courseIds.isNotEmpty) {
        final schedule = await supabase
            .from('Schedule')
            .select('*, Course(Name)')
            .inFilter('Course_ID', courseIds)
            .order('DayOfWeek')
            .order('StartTime');

        for (var entry in schedule) {
          courseEntries.add({
            'id': entry['ID'],
            'type': 'course',
            'day': _capitalizeDay(entry['DayOfWeek']),
            'startTime': entry['StartTime'],
            'endTime': entry['EndTime'],
            'title': entry['Course']?['name'] ?? entry['Course_ID'],
            'venue': entry['Room'] ?? 'No room',
            'isPersonal': false,
          });
        }
      }

      // 2. Fetch personal events
      final personal = await supabase
          .from('personal_events')
          .select()
          .eq('student_id', studentId)
          .order('day')
          .order('start_time');

      List<Map<String, dynamic>> personalEntries = [];
      for (var event in personal) {
        personalEntries.add({
          'id': event['id'],
          'type': 'personal',
          'day': event['day'],
          'startTime': event['start_time'],
          'endTime': event['end_time'],
          'title': event['title'],
          'venue': event['venue'] ?? '',
          'isPersonal': true,
        });
      }

      // 3. Merge and sort
      final all = [...courseEntries, ...personalEntries];
      all.sort((a, b) {
        int dayCompare = _dayOrder.indexOf(a['day']).compareTo(_dayOrder.indexOf(b['day']));
        if (dayCompare != 0) return dayCompare;
        return a['startTime'].compareTo(b['startTime']);
      });

      setState(() {
        _allEntries = all;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _capitalizeDay(String day) {
    if (day.isEmpty) return '';
    return day[0].toUpperCase() + day.substring(1).toLowerCase();
  }

  String _formatTime(String time) {
    if (time.isEmpty) return '';
    final parts = time.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return time;
  }

  Map<String, List<Map<String, dynamic>>> _groupByDay() {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var entry in _allEntries) {
      String day = entry['day'];
      if (!grouped.containsKey(day)) grouped[day] = [];
      grouped[day]!.add(entry);
    }
    return grouped;
  }

  Future<void> _deletePersonalEvent(String eventId) async {
    final supabase = Supabase.instance.client;
    await supabase.from('personal_events').delete().eq('id', eventId);
    _fetchAllTimetableEntries();
  }

  void _openPersonalEventForm({Map<String, dynamic>? event}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PersonalEventFormScreen(
          existingEvent: event,
          studentId: widget.studentId,
        ),
      ),
    );
    if (result == true) _fetchAllTimetableEntries();
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDay();
    final sortedDays = grouped.keys.toList()
      ..sort((a, b) => _dayOrder.indexOf(a).compareTo(_dayOrder.indexOf(b)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Timetable'),
        backgroundColor: const Color(0xFF005A9C),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.announcement),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AnnouncementScreen()),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : grouped.isEmpty
          ? const Center(child: Text('No timetable entries found.'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedDays.length,
        itemBuilder: (context, dayIndex) {
          final day = sortedDays[dayIndex];
          final dayEntries = grouped[day]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  day,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF005A9C),
                  ),
                ),
              ),
              ...dayEntries.map((entry) {
                final isPersonal = entry['isPersonal'] == true;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isPersonal ? Colors.blue[50] : Colors.white,
                  child: ListTile(
                    leading: Icon(
                      isPersonal ? Icons.person_add : Icons.school,
                      color: isPersonal ? Colors.green : Colors.blue,
                    ),
                    title: Text(entry['title']),
                    subtitle: Text(
                      '${_formatTime(entry['startTime'])} - ${_formatTime(entry['endTime'])} @ ${entry['venue']}',
                    ),
                    trailing: isPersonal
                        ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _openPersonalEventForm(event: entry),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deletePersonalEvent(entry['id']),
                        ),
                      ],
                    )
                        : null,
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF005A9C),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () => _openPersonalEventForm(),
      ),
    );
  }
}