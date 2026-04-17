import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  late TextEditingController _dayController;
  late TextEditingController _startController;
  late TextEditingController _endController;
  late TextEditingController _venueController;

  @override
  void initState() {
    super.initState();
    final event = widget.existingEvent;
    _titleController = TextEditingController(text: event?['title'] ?? '');
    _dayController = TextEditingController(text: event?['day'] ?? 'Monday');
    _startController = TextEditingController(text: _formatTimeForInput(event?['startTime']));
    _endController = TextEditingController(text: _formatTimeForInput(event?['endTime']));
    _venueController = TextEditingController(text: event?['venue'] ?? '');
  }

  String _formatTimeForInput(String? time) {
    if (time == null) return '10:00';
    final parts = time.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return time;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dayController.dispose();
    _startController.dispose();
    _endController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final supabase = Supabase.instance.client;

    final data = {
      'student_id': widget.studentId,  // Use the passed ID
      'title': _titleController.text,
      'day': _dayController.text,
      'start_time': _startController.text,
      'end_time': _endController.text,
      'venue': _venueController.text.isEmpty ? null : _venueController.text,
    };

    if (widget.existingEvent != null) {
      await supabase.from('personal_events').update(data).eq('id', widget.existingEvent!['id']);
    } else {
      await supabase.from('personal_events').insert(data);
    }
    Navigator.pop(context, true);
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
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title (e.g., Study Session)'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _dayController,
                decoration: const InputDecoration(labelText: 'Day'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _startController,
                decoration: const InputDecoration(labelText: 'Start time (HH:MM)'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _endController,
                decoration: const InputDecoration(labelText: 'End time (HH:MM)'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _venueController,
                decoration: const InputDecoration(labelText: 'Venue (optional)'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005A9C),
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