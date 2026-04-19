import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student_announcement_screen.dart';
import 'personal_event_form_screen.dart';
import 'package:intl/intl.dart';
import 'calendar_screen.dart';

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
            'title': entry['Course']?['Name'] ?? entry['Course_ID'],
            'venue': entry['Room'] ?? 'No room',
            'classType': entry['ClassType'] ?? '',
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


  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  Map<String, dynamic>? _getNextEvent() {
    if (_allEntries.isEmpty) return null;

    final now = DateTime.now();
    final currentWeekday = DateFormat('EEEE').format(now);
    final currentTime = TimeOfDay.fromDateTime(now);
    final todayIndex = _dayOrder.indexOf(currentWeekday);
    if (todayIndex == -1) return null;

    List<Map<String, dynamic>> futureEvents = [];

    for (var entry in _allEntries) {
      final entryDay = entry['day'];
      final entryDayIndex = _dayOrder.indexOf(entryDay);
      if (entryDayIndex < todayIndex) continue;

      final startTimeStr = entry['startTime'] as String;
      final startParts = startTimeStr.split(':');
      if (startParts.length < 2) continue;
      final startTime = TimeOfDay(
        hour: int.parse(startParts[0]),
        minute: int.parse(startParts[1]),
      );

      if (entryDayIndex == todayIndex) {
        if (startTime.hour > currentTime.hour ||
            (startTime.hour == currentTime.hour && startTime.minute > currentTime.minute)) {
          futureEvents.add(entry);
        }
      } else {
        futureEvents.add(entry);
      }
    }

    if (futureEvents.isEmpty) return null;

    futureEvents.sort((a, b) {
      final dayCompare = _dayOrder.indexOf(a['day']).compareTo(_dayOrder.indexOf(b['day']));
      if (dayCompare != 0) return dayCompare;
      return a['startTime'].compareTo(b['startTime']);
    });

    return futureEvents.first;
  }

  Widget _buildClassTypeChip(String? classType) {
    Color chipColor;
    Color textColor = Colors.white;

    switch (classType?.toLowerCase()) {
      case 'lecture':
        chipColor = Colors.blue;
        break;
      case 'tutorial':
        chipColor = Colors.green;
        break;
      case 'practical':
        chipColor = Colors.orange;
        break;
      default:
        chipColor = Colors.grey;
        textColor = Colors.black87;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        classType ?? 'Unknown',
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }


  Widget _buildNextEventCard() {
    final nextEvent = _getNextEvent();
    if (nextEvent == null) return const SizedBox.shrink();

    final isPersonal = nextEvent['isPersonal'] == true;
    final start = _formatTime(nextEvent['startTime']);
    final end = _formatTime(nextEvent['endTime']);
    final now = DateTime.now();
    final eventStart = _parseTimeOfDay(nextEvent['startTime']);
    final eventDateTime = DateTime(
      now.year, now.month, now.day,
      eventStart.hour, eventStart.minute,
    );
    final difference = eventDateTime.difference(now);
    final minutesLeft = difference.inMinutes;
    final timeLeftText = minutesLeft > 0 ? 'in $minutesLeft min' : 'now';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF005A9C), Color(0xFF0077BE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⬆️ Next Up',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isPersonal ? Icons.person_add : Icons.school,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nextEvent['title'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${nextEvent['day']} • $start - $end | ${nextEvent['venue']}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  timeLeftText,
                  style: const TextStyle(
                    color: Color(0xFF005A9C),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CalendarScreen(studentId: widget.studentId),
                ),
              );
            },
            tooltip: 'Calendar View',
          ),
          IconButton(
            icon: const Icon(Icons.announcement),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => StudentAnnouncementScreen(studentId: widget.studentId)),
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
          : Column(
        children: [
          _buildNextEventCard(),
          Expanded(
            child: ListView.builder(
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
                          subtitle: isPersonal
                              ? Text('${_formatTime(entry['startTime'])} - ${_formatTime(entry['endTime'])} | ${entry['venue']}')
                              : Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${_formatTime(entry['startTime'])} - ${_formatTime(entry['endTime'])} | ${entry['venue']}',
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildClassTypeChip(entry['classType']),
                            ],
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
          ),
        ],
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