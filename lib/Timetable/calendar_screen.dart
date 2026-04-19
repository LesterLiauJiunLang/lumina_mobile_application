import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  final String studentId;
  const CalendarScreen({super.key, required this.studentId});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  List<Map<String, dynamic>> _allEntries = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Calendar state
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<Map<String, dynamic>>> _events = {};

  final List<String> _dayOrder = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _fetchAllEntries();
  }

  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _fetchAllEntries() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final studentId = widget.studentId;

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

      // 3. Merge
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

      _buildEventsMap();
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

  void _buildEventsMap() {
    final Map<DateTime, List<Map<String, dynamic>>> events = {};
    final startOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final endOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    for (var date = startOfMonth; date.isBefore(endOfMonth.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
      final weekdayName = DateFormat('EEEE').format(date);
      final dayEvents = _allEntries.where((entry) => entry['day'] == weekdayName).toList();
      if (dayEvents.isNotEmpty) {
        events[DateTime(date.year, date.month, date.day)] = dayEvents;
      }
    }
    setState(() {
      _events = events;
    });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar View'),
        backgroundColor: const Color(0xFF005A9C),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.view_list),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back to List',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : Column(
        children: [
          TableCalendar(
            firstDay: DateTime(2024, 1, 1),
            lastDay: DateTime(2026, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            eventLoader: _getEventsForDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
              _buildEventsMap();
            },
            calendarStyle: CalendarStyle(
              markersAlignment: Alignment.bottomCenter,
              markerSize: 4,
              defaultTextStyle: const TextStyle(color: Colors.black87),
              weekendTextStyle: const TextStyle(color: Colors.red),
              todayTextStyle: const TextStyle(fontWeight: FontWeight.bold),
              selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              todayDecoration: BoxDecoration(
                color: const Color(0xFF005A9C).withOpacity(0.3), // 30% opacity – always visible
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: const Color(0xFF005A9C).withOpacity(0.9), // 90% opacity – selected stands out
                shape: BoxShape.circle,
              ),
              cellPadding: const EdgeInsets.all(4),
            ),
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildEventsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    final events = _getEventsForDay(_selectedDay);
    if (events.isEmpty) {
      return const Center(
        child: Text('No events on this day'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final entry = events[index];
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
                ? Text('${_formatTime(entry['startTime'])} - ${_formatTime(entry['endTime'])} @ ${entry['venue']}')
                : Row(
              children: [
                Expanded(
                  child: Text(
                    '${_formatTime(entry['startTime'])} - ${_formatTime(entry['endTime'])} @ ${entry['venue']}',
                  ),
                ),
                const SizedBox(width: 8),
                _buildClassTypeChip(entry['classType']),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClassTypeChip(String? classType) {
    Color chipColor;
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
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        classType ?? 'Unknown',
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}