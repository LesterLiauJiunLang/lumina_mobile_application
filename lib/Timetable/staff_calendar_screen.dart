import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class StaffCalendarScreen extends StatefulWidget {
  final String staffId;
  final List<Map<String, dynamic>> scheduleEntries; // passed from parent
  const StaffCalendarScreen({
    super.key,
    required this.staffId,
    required this.scheduleEntries,
  });

  @override
  State<StaffCalendarScreen> createState() => _StaffCalendarScreenState();
}

class _StaffCalendarScreenState extends State<StaffCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<Map<String, dynamic>>> _events = {};

  @override
  void initState() {
    super.initState();
    _buildEventsMap();
  }

  void _buildEventsMap() {
    final Map<DateTime, List<Map<String, dynamic>>> events = {};
    final startOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final endOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    for (var date = startOfMonth;
    date.isBefore(endOfMonth.add(const Duration(days: 1)));
    date = date.add(const Duration(days: 1))) {
      final weekdayName = DateFormat('EEEE').format(date); // e.g., "Monday"
      final dayEvents = widget.scheduleEntries
          .where((entry) => _capitalizeDay(entry['DayOfWeek']) == weekdayName)
          .toList();
      if (dayEvents.isNotEmpty) {
        events[DateTime(date.year, date.month, date.day)] = dayEvents;
      }
    }
    setState(() {
      _events = events;
    });
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

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teaching Calendar'),
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
      body: Column(
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
              setState(() => _focusedDay = focusedDay);
              _buildEventsMap(); // rebuild markers for new month
            },
            calendarStyle: CalendarStyle(
              markersAlignment: Alignment.bottomCenter,
              markerSize: 4,
              defaultTextStyle: const TextStyle(color: Colors.black87),
              weekendTextStyle: const TextStyle(color: Colors.red),
              todayTextStyle: const TextStyle(fontWeight: FontWeight.bold),
              selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              todayDecoration: BoxDecoration(
                color: const Color(0xFF005A9C).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Color(0xFF005A9C),
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
      return const Center(child: Text('No classes on this day'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final entry = events[index];
        final courseName = entry['Course']?['Name'] ?? entry['Course_ID'];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.class_, color: Colors.blue),
            title: Text('$courseName (${entry['ClassType']})'),
            subtitle: Text(
              '${_formatTime(entry['StartTime'])} - ${_formatTime(entry['EndTime'])} @ ${entry['Room'] ?? 'No room'}',
            ),
          ),
        );
      },
    );
  }
}