import 'package:flutter/material.dart';
import 'package:lumina_mobile_application/Timetable/staff_calendar_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'conflict_detector.dart'; // reuse for schedule conflicts

class StaffTimetableScreen extends StatefulWidget {
  final String staffId; // e.g., "S001"
  const StaffTimetableScreen({super.key, required this.staffId});

  @override
  State<StaffTimetableScreen> createState() => _StaffTimetableScreenState();
}

class _StaffTimetableScreenState extends State<StaffTimetableScreen> {
  List<Map<String, dynamic>> _scheduleEntries = [];
  List<Map<String, dynamic>> _courses = [];
  bool _isLoading = true;
  String? _errorMessage;

  final List<String> _dayOrder = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final supabase = Supabase.instance.client;
      final staffId = widget.staffId;

      // 1. Fetch courses taught by this staff
      final courses = await supabase
          .from('Course')
          .select('ID, Name')
          .eq('Staff_ID', staffId);
      _courses = List<Map<String, dynamic>>.from(courses);
      final courseIds = _courses.map((c) => c['ID'] as String).toList();

      // 2. Fetch schedule entries for those courses
      if (courseIds.isNotEmpty) {
        final schedule = await supabase
            .from('Schedule')
            .select('*, Course(Name)')
            .inFilter('Course_ID', courseIds)
            .order('DayOfWeek')
            .order('StartTime');
        _scheduleEntries = List<Map<String, dynamic>>.from(schedule);
      } else {
        _scheduleEntries = [];
      }

      setState(() {
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
    for (var entry in _scheduleEntries) {
      String day = _capitalizeDay(entry['DayOfWeek']);
      if (!grouped.containsKey(day)) grouped[day] = [];
      grouped[day]!.add(entry);
    }
    return grouped;
  }

  Future<void> _deleteScheduleEntry(String entryId) async {
    final supabase = Supabase.instance.client;
    await supabase.from('Schedule').delete().eq('ID', entryId);
    _fetchData();
  }

  void _openScheduleForm({Map<String, dynamic>? entry}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleFormScreen(
          existingEntry: entry,
          staffId: widget.staffId,
          courses: _courses,
        ),
      ),
    );
    if (result == true) _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDay();
    final sortedDays = grouped.keys.toList()
      ..sort((a, b) => _dayOrder.indexOf(a).compareTo(_dayOrder.indexOf(b)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Teaching Schedule'),
        backgroundColor: const Color(0xFF005A9C),
        foregroundColor: Colors.white,
        actions: [
          // Optional: calendar view button (same as student)
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StaffCalendarScreen(
                    staffId: widget.staffId,
                    scheduleEntries: _scheduleEntries,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : grouped.isEmpty
          ? const Center(child: Text('No schedule entries found for your courses.'))
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
                final courseName = entry['Course']?['Name'] ?? entry['Course_ID'];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.class_, color: Colors.blue),
                    title: Text('$courseName (${entry['ClassType']})'),
                    subtitle: Text(
                      '${_formatTime(entry['StartTime'])} - ${_formatTime(entry['EndTime'])} @ ${entry['Room'] ?? 'No room'}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _openScheduleForm(entry: entry),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteScheduleEntry(entry['ID']),
                        ),
                      ],
                    ),
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
        onPressed: () => _openScheduleForm(),
      ),
    );
  }
}

// --------------------------------------------------------------
// Form to add/edit a schedule entry
// --------------------------------------------------------------
class ScheduleFormScreen extends StatefulWidget {
  final Map<String, dynamic>? existingEntry;
  final String staffId;
  final List<Map<String, dynamic>> courses;
  const ScheduleFormScreen({
    super.key,
    this.existingEntry,
    required this.staffId,
    required this.courses,
  });

  @override
  State<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedCourseId;
  late String _selectedDay;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late TextEditingController _roomController;
  late String _selectedClassType;

  final List<String> _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  final List<String> _classTypes = ['Lecture', 'Tutorial', 'Practical', 'Lab'];

  @override
  void initState() {
    super.initState();
    final entry = widget.existingEntry;
    _selectedCourseId = entry?['Course_ID'] ?? widget.courses.first['ID'];
    _selectedDay = entry != null ? _capitalizeDay(entry['DayOfWeek']) : 'Monday';
    _startTime = _parseTimeOfDay(entry?['StartTime'] ?? '09:00');
    _endTime = _parseTimeOfDay(entry?['EndTime'] ?? '11:00');
    _roomController = TextEditingController(text: entry?['Room'] ?? '');
    _selectedClassType = entry?['ClassType'] ?? 'Lecture';
  }

  String _capitalizeDay(String day) {
    if (day.isEmpty) return '';
    return day[0].toUpperCase() + day.substring(1).toLowerCase();
  }

  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    if (parts.length >= 2) {
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    return const TimeOfDay(hour: 9, minute: 0);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF005A9C)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF005A9C)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _endTime = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final start = _formatTimeOfDay(_startTime);
    final end = _formatTimeOfDay(_endTime);

    // Conflict detection against other schedule entries (excluding this one if editing)
    final detector = ConflictDetector();
    final conflicts = await detector.checkConflictsForSchedule(
      courseId: _selectedCourseId,
      day: _selectedDay.toUpperCase(),
      startTime: start,
      endTime: end,
      excludeEntryId: widget.existingEntry?['ID'],
    );

    if (conflicts.isNotEmpty) {
      final shouldSave = await _showConflictDialog(conflicts);
      if (!shouldSave) return;
    }

    final supabase = Supabase.instance.client;
    final data = {
      'Course_ID': _selectedCourseId,
      'DayOfWeek': _selectedDay.toUpperCase(),
      'StartTime': start,
      'EndTime': end,
      'Room': _roomController.text.isEmpty ? null : _roomController.text,
      'ClassType': _selectedClassType,
      'DurationHours': (end.compareTo(start) > 0)
          ? double.parse((_endTime.hour - _startTime.hour).toString())
          : 1.0, // simplified
    };

    if (widget.existingEntry != null) {
      await supabase.from('Schedule').update(data).eq('ID', widget.existingEntry!['ID']);
    } else {
      await supabase.from('Schedule').insert(data);
    }
    Navigator.pop(context, true);
  }

  Future<bool> _showConflictDialog(List<String> conflicts) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule Conflict'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This time slot conflicts with:'),
            const SizedBox(height: 8),
            ...conflicts.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $c'),
            )),
            const SizedBox(height: 16),
            const Text('Do you still want to save?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005A9C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Anyway'),
          ),
        ],
      ),
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingEntry == null ? 'Add Schedule Entry' : 'Edit Schedule Entry'),
        backgroundColor: const Color(0xFF005A9C),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedCourseId,
                decoration: const InputDecoration(labelText: 'Course', border: OutlineInputBorder()),
                items: widget.courses.map<DropdownMenuItem<String>>((c) {
                  return DropdownMenuItem<String>(
                    value: c['ID'] as String,
                    child: Text('${c['Name']} (${c['ID']})'),
                  );
                }).toList(),
                onChanged: (String? val) => setState(() => _selectedCourseId = val!),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDay,
                decoration: const InputDecoration(labelText: 'Day', border: OutlineInputBorder()),
                items: _days.map<DropdownMenuItem<String>>((d) => DropdownMenuItem<String>(value: d, child: Text(d))).toList(),
                onChanged: (String? val) => setState(() => _selectedDay = val!),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectStartTime,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Start Time', border: OutlineInputBorder()),
                  child: Text(_formatTimeOfDay(_startTime)),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectEndTime,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'End Time', border: OutlineInputBorder()),
                  child: Text(_formatTimeOfDay(_endTime)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _roomController,
                decoration: const InputDecoration(labelText: 'Room', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedClassType,
                decoration: const InputDecoration(labelText: 'Class Type', border: OutlineInputBorder()),
                items: _classTypes.map<DropdownMenuItem<String>>((ct) => DropdownMenuItem<String>(value: ct, child: Text(ct))).toList(),
                onChanged: (String? val) => setState(() => _selectedClassType = val!),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005A9C),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}