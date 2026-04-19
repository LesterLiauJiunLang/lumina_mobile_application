import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'conflict_detector.dart';

class PersonalEventFormScreen extends StatefulWidget {
  final Map<String, dynamic>? existingEvent;
  final String studentId;
  const PersonalEventFormScreen({
    super.key,
    this.existingEvent,
    required this.studentId,
  });

  @override
  State<PersonalEventFormScreen> createState() => _PersonalEventFormScreenState();
}

class _PersonalEventFormScreenState extends State<PersonalEventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late String _selectedDay;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late TextEditingController _venueController;

  final List<String> _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    final event = widget.existingEvent;
    _titleController = TextEditingController(text: event?['title'] ?? '');
    _selectedDay = event?['day'] ?? 'Monday';
    _startTime = _parseTimeOfDay(event?['startTime'] ?? '09:00');
    _endTime = _parseTimeOfDay(event?['endTime'] ?? '17:00');
    _venueController = TextEditingController(text: event?['venue'] ?? '');
  }

  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    if (parts.length >= 2) {
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }
    return const TimeOfDay(hour: 9, minute: 0);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF005A9C)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF005A9C)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _endTime) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final startTime = _formatTimeOfDay(_startTime);
    final endTime = _formatTimeOfDay(_endTime);

    // Check for conflicts
    final detector = ConflictDetector();
    final conflicts = await detector.checkConflicts(
      studentId: widget.studentId,
      day: _selectedDay,
      startTime: startTime,
      endTime: endTime,
      excludeEventId: widget.existingEvent?['id'],
    );

    if (conflicts.isNotEmpty) {
      // Show warning dialog, let user decide
      final shouldSave = await _showConflictDialog(conflicts);
      if (!shouldSave) return;
    }

    // Proceed with save
    final supabase = Supabase.instance.client;
    final data = {
      'student_id': widget.studentId,
      'title': _titleController.text,
      'day': _selectedDay,
      'start_time': startTime,
      'end_time': endTime,
      'venue': _venueController.text.isEmpty ? null : _venueController.text,
    };

    if (widget.existingEvent != null) {
      await supabase.from('personal_events').update(data).eq('id', widget.existingEvent!['id']);
    } else {
      await supabase.from('personal_events').insert(data);
    }
    Navigator.pop(context, true);
  }

  Future<bool> _showConflictDialog(List<String> conflicts) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Time Conflict'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This event conflicts with:'),
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
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingEvent == null ? 'Add Personal Event' : 'Edit Personal Event'),
        backgroundColor: const Color(0xFF005A9C),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Title field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title (e.g., Study Session)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Day dropdown
              DropdownButtonFormField<String>(
                value: _selectedDay,
                decoration: const InputDecoration(
                  labelText: 'Day',
                  border: OutlineInputBorder(),
                ),
                items: _days.map((day) {
                  return DropdownMenuItem(value: day, child: Text(day));
                }).toList(),
                onChanged: (newDay) {
                  setState(() {
                    _selectedDay = newDay!;
                  });
                },
                validator: (value) => value == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Start time picker
              InkWell(
                onTap: _selectStartTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Start Time',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(_formatTimeOfDay(_startTime)),
                ),
              ),
              const SizedBox(height: 16),

              // End time picker
              InkWell(
                onTap: _selectEndTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'End Time',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(_formatTimeOfDay(_endTime)),
                ),
              ),
              const SizedBox(height: 16),

              // Venue field (optional)
              TextFormField(
                controller: _venueController,
                decoration: const InputDecoration(
                  labelText: 'Venue (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Save button
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005A9C),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Save',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),)
              ),
            ],
          ),
        ),
      ),
    );
  }
}