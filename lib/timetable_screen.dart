import 'package:flutter/material.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  // Dummy data
  List<Map<String, String>> _timetable = [
    {'day': 'Monday', 'time': '10:00 - 12:00', 'subject': 'Software Engineering', 'venue': 'Room 101'},
    {'day': 'Wednesday', 'time': '14:00 - 16:00', 'subject': 'Mobile Apps', 'venue': 'Lab 3'},
    {'day': 'Monday', 'time': '14:00 - 16:00', 'subject': 'Database Systems', 'venue': 'Room 205'},
    {'day': 'Friday', 'time': '09:00 - 11:00', 'subject': 'Web Development', 'venue': 'Lab 1'},
    {'day': 'Tuesday', 'time': '13:00 - 15:00', 'subject': 'Mathematics', 'venue': 'Room 103'},
  ];

  // Order of days for sorting
  final List<String> _dayOrder = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  // Method to group timetable by day
  Map<String, List<Map<String, String>>> _groupByDay() {
    Map<String, List<Map<String, String>>> grouped = {};

    for (var entry in _timetable) {
      String day = entry['day'] ?? 'Other';
      if (!grouped.containsKey(day)) {
        grouped[day] = [];
      }
      grouped[day]!.add(entry);
    }

    return grouped;
  }
  @override
  Widget build(BuildContext context) {
    final groupedTimetable = _groupByDay();
    // Sort days according to _dayOrder
    final sortedDays = groupedTimetable.keys.toList()
      ..sort((a, b) => _dayOrder.indexOf(a).compareTo(_dayOrder.indexOf(b)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable'),
        backgroundColor: const Color(0xFF005A9C),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.announcement),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnnouncementScreen()),
              );
            },
          ),
        ],
      ),
      body: groupedTimetable.isEmpty
          ? const Center(
        child: Text('No timetable entries yet. Tap + to add one.'),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedDays.length,
        itemBuilder: (context, dayIndex) {
          String day = sortedDays[dayIndex];
          List<Map<String, String>> dayEntries = groupedTimetable[day]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day header
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
              // Entries for this day
              ...dayEntries.map((entry) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(entry['subject'] ?? ''),
                  subtitle: Text('${entry['time']} @ ${entry['venue']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddEditTimetableScreen(timetableItem: entry),
                            ),
                          );
                          if (result != null) {
                            setState(() {
                              int index = _timetable.indexWhere((item) =>
                              item['day'] == entry['day'] &&
                                  item['time'] == entry['time'] &&
                                  item['subject'] == entry['subject']
                              );
                              if (index != -1) {
                                _timetable[index] = result;
                              }
                            });
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _timetable.removeWhere((item) =>
                            item['day'] == entry['day'] &&
                                item['time'] == entry['time'] &&
                                item['subject'] == entry['subject']
                            );
                          });
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    // View details - you could show a dialog or navigate to detail screen
                  },
                ),
              )).toList(),
              const SizedBox(height: 16), // Space between day groups
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF005A9C),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditTimetableScreen()),
          );
          if (result != null) {
            setState(() {
              _timetable.add(result);
            });
          }
        },
      ),
    );
  }
}

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

class AnnouncementScreen extends StatelessWidget {
  const AnnouncementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable Announcements'),
        backgroundColor: Color(0xFF005A9C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: ListTile(
              title: Text('New Timetable for Next Semester'),
              subtitle: Text('Posted on March 1, 2026'),
            ),
          ),
          Card(
            child: ListTile(
              title: Text('Exam Schedule Updated'),
              subtitle: Text('Please check your emails.'),
            ),
          ),
        ],
      ),
    );
  }
}