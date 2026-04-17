import 'package:flutter/material.dart';



class AddEditTimetableScreen extends StatefulWidget {
  final Map<String, String>? timetableItem;

  const AddEditTimetableScreen({super.key, this.timetableItem});

  @override
  State<AddEditTimetableScreen> createState() => _AddEditTimetableScreenState();
}

class _AddEditTimetableScreenState extends State<AddEditTimetableScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _dayController;
  late TextEditingController _timeController;
  late TextEditingController _subjectController;
  late TextEditingController _venueController;

  @override
  void initState() {
    super.initState();
    _dayController = TextEditingController(text: widget.timetableItem?['day'] ?? '');
    _timeController = TextEditingController(text: widget.timetableItem?['time'] ?? '');
    _subjectController = TextEditingController(text: widget.timetableItem?['subject'] ?? '');
    _venueController = TextEditingController(text: widget.timetableItem?['venue'] ?? '');
  }

  @override
  void dispose() {
    _dayController.dispose();
    _timeController.dispose();
    _subjectController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.timetableItem == null ? 'Add Timetable' : 'Edit Timetable'),
        backgroundColor: Color(0xFF005A9C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _dayController,
                decoration: const InputDecoration(labelText: 'Day'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(labelText: 'Time (e.g., 10:00 - 12:00)'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(labelText: 'Subject'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _venueController,
                decoration: const InputDecoration(labelText: 'Venue'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final newItem = {
                        'day': _dayController.text,
                        'time': _timeController.text,
                        'subject': _subjectController.text,
                        'venue': _venueController.text,
                      };
                      Navigator.pop(context, newItem);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005A9C), // Button background color
                    foregroundColor: Colors.white, // Button text color
                    padding: const EdgeInsets.symmetric(vertical: 16), // Optional: adjust padding
                    minimumSize: const Size(80, 20), // Optional: make button full width
                  ),
                  child: const Text('Save')
              ),
            ],
          ),
        ),
      ),
    );
  }
}